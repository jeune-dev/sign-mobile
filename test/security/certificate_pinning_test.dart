import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sign_application/core/config/env.dart';

/// Garde-fou contre l'incident de production du pinning TLS.
///
/// Contexte : l'application a épinglé pendant un temps un certificat
/// **intermédiaire** Let's Encrypt (YE2), récupéré par erreur sur un autre
/// backend. Le serveur servant un autre intermédiaire (YE1), 100 % des
/// requêtes échouaient en `HandshakeException` — l'app n'atteignait plus le
/// backend, sans aucun message exploitable côté client.
///
/// Ces tests garantissent que :
///  1. le bundle épinglé ne contient QUE des racines connues et auto-signées ;
///  2. un handshake TLS réel vers le backend de production réussit avec ce
///     bundle seul (test réseau, ignoré hors ligne).
void main() {
  final bundle = File('assets/certs/backend_ca.pem');

  /// Racines autorisées — SHA-256 du DER.
  /// Le backend de production unique (api.app-signs.com) est servi par
  /// Let's Encrypt, donc rattaché aux racines ISRG.
  /// Toute modification de cette liste doit être délibérée : n'y ajoutez
  /// JAMAIS un certificat intermédiaire, il est renouvelé plusieurs fois par an.
  const racinesAutorisees = <String, String>{
    '96bcec06264976f37460779acf28c5a7cfe8a3c0aae11a8ffcee05c0bddf08c6':
        'ISRG Root X1',
    '69729b8e15a86efc177a57afb7171dfc64add28c2fca8cf1507e34453ccb1470':
        'ISRG Root X2',
  };


  List<List<int>> derDuBundle() {
    final texte = bundle.readAsStringSync();
    final blocs = RegExp(
      r'-----BEGIN CERTIFICATE-----(.*?)-----END CERTIFICATE-----',
      dotAll: true,
    ).allMatches(texte);
    return blocs
        .map((m) => base64.decode(m.group(1)!.replaceAll(RegExp(r'\s'), '')))
        .toList();
  }

  group('Certificate pinning — bundle épinglé', () {
    test('le bundle existe et est déclaré comme asset', () {
      expect(bundle.existsSync(), isTrue,
          reason: 'assets/certs/backend_ca.pem est introuvable');
      expect(File('pubspec.yaml').readAsStringSync(), contains('assets/certs/'),
          reason: 'assets/certs/ doit rester déclaré dans pubspec.yaml');
    });

    test('ne contient que des racines explicitement autorisées', () {
      final empreintes = derDuBundle()
          .map((der) => sha256.convert(der).toString())
          .toList();

      expect(empreintes, isNotEmpty);
      for (final e in empreintes) {
        expect(racinesAutorisees.containsKey(e), isTrue,
            reason: 'Certificat non autorisé dans le bundle (SHA-256 $e). '
                'N\'épinglez jamais un intermédiaire : il est renouvelé '
                'plusieurs fois par an et coupe les clients installés.');
      }
    });

    test('est accepté par SecurityContext', () {
      expect(
        () => SecurityContext(withTrustedRoots: false)
          ..setTrustedCertificatesBytes(bundle.readAsBytesSync()),
        returnsNormally,
      );
    });
  });

  group('Certificate pinning — handshake réel', () {
    test('le backend de production est joignable avec le bundle seul', () async {
      final hote = Uri.parse(Env.baseUrl).host;
      final contexte = SecurityContext(withTrustedRoots: false)
        ..setTrustedCertificatesBytes(bundle.readAsBytesSync());
      final client = HttpClient(context: contexte);

      try {
        final requete = await client.getUrl(Uri.parse('https://$hote/'));
        await (await requete.close()).drain();
      } on HandshakeException catch (e) {
        fail('Handshake TLS refusé vers $hote avec le bundle épinglé : $e\n'
            'Le certificat du backend a changé de chaîne — mettez à jour '
            'assets/certs/backend_ca.pem AVANT de publier.');
      } on SocketException {
        // Pas de réseau (poste hors ligne) : rien à vérifier ici.
      } finally {
        client.close(force: true);
      }
    }, timeout: const Timeout(Duration(seconds: 30)));
  });
}
