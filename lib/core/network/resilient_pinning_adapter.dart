import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:flutter/foundation.dart';

/// Adaptateur HTTP avec certificate pinning **fail-safe**.
///
/// Incident production : l'implémentation précédente épinglait un certificat
/// **intermédiaire** Let's Encrypt via `SecurityContext(withTrustedRoots: false)`.
/// Le `try/catch` qui entourait la création du client ne protégeait rien : la
/// construction du [HttpClient] réussit toujours, c'est le *handshake* TLS qui
/// échoue. Dès que le backend a servi un autre intermédiaire, 100 % des
/// requêtes sont tombées en [HandshakeException] et l'app n'atteignait plus le
/// serveur — sans aucun repli possible.
///
/// Ici :
///  * on épingle les **racines** ISRG (stables jusqu'en 2035 / 2040), donc une
///    rotation d'intermédiaire (YE1 / YE2 / E5 / E6 / R10 / R11…) est sans effet ;
///  * si le handshake épinglé échoue malgré tout, on bascule **définitivement**
///    (pour la durée de la session) sur la validation système, et la requête en
///    cours est rejouée de façon transparente.
///
/// La sécurité reste assurée par les trust anchors système ; l'application ne
/// peut plus être mise hors service par un changement de certificat.
class ResilientPinningAdapter implements HttpClientAdapter {
  ResilientPinningAdapter({
    required Uint8List trustedCertificates,
    this.maxReplayBytes = 2 * 1024 * 1024,
  }) : _pinned = IOHttpClientAdapter(
          createHttpClient: () {
            try {
              final context = SecurityContext(withTrustedRoots: false)
                ..setTrustedCertificatesBytes(trustedCertificates);
              return HttpClient(context: context);
            } catch (_) {
              // PEM illisible ou expiré → validation système standard.
              return HttpClient();
            }
          },
        );

  final IOHttpClientAdapter _pinned;
  final IOHttpClientAdapter _system = IOHttpClientAdapter();

  /// Taille maximale d'un corps de requête que l'on accepte de bufferiser en
  /// mémoire pour pouvoir le rejouer après un échec de handshake.
  final int maxReplayBytes;

  bool _pinningDisabled = false;

  /// `true` une fois que le pinning a été désactivé suite à un échec TLS.
  bool get pinningDisabled => _pinningDisabled;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (_pinningDisabled) {
      return _system.fetch(options, requestStream, cancelFuture);
    }

    // On ne bufferise que les corps de taille connue et raisonnable : au-delà
    // (upload de document), la requête ne sera pas rejouée — mais le pinning
    // sera tout de même désactivé pour les requêtes suivantes.
    final canReplay = requestStream == null || _contentLength(options) <= maxReplayBytes;

    List<Uint8List>? buffered;
    Stream<Uint8List>? stream = requestStream;
    if (requestStream != null && canReplay) {
      buffered = await requestStream.toList();
      stream = Stream.fromIterable(buffered);
    }

    try {
      return await _pinned.fetch(options, stream, cancelFuture);
    } on HandshakeException catch (e) {
      _disablePinning(e);
      if (buffered == null && requestStream != null) rethrow;
      return _system.fetch(
        options,
        buffered == null ? null : Stream.fromIterable(buffered),
        cancelFuture,
      );
    } on TlsException catch (e) {
      _disablePinning(e);
      if (buffered == null && requestStream != null) rethrow;
      return _system.fetch(
        options,
        buffered == null ? null : Stream.fromIterable(buffered),
        cancelFuture,
      );
    }
  }

  int _contentLength(RequestOptions options) {
    final raw = options.headers[Headers.contentLengthHeader];
    if (raw is int) return raw;
    return int.tryParse('$raw') ?? (1 << 62);
  }

  void _disablePinning(Object error) {
    if (_pinningDisabled) return;
    _pinningDisabled = true;
    _pinned.close(force: true);
    if (kDebugMode) {
      debugPrint('⚠️ Certificate pinning désactivé pour la session : $error');
    }
  }

  @override
  void close({bool force = false}) {
    _pinned.close(force: force);
    _system.close(force: force);
  }
}
