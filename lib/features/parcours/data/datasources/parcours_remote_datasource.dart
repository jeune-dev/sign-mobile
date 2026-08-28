import 'dart:io';

import 'package:dio/dio.dart';

import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/core/validation/identifiant_validator.dart';

import '../models/exigences_document.dart';

/// parcours_remote_datasource.dart — Appels du nouveau parcours.
///
/// Regroupe tout ce qui se joue entre l'inscription rapide et la génération
/// d'un document : exigences par type de document, enregistrement des
/// informations réclamées, contrôle avant génération, recherche de l'autre
/// partie et dépôt des justificatifs.
///
/// Toutes les méthodes remontent une [ParcoursException] portant le message
/// exact du backend — ces messages sont rédigés pour être affichés tels quels
/// à l'utilisateur (« Le numéro doit comporter 9 chiffres — 8 saisis »).
class ParcoursException implements Exception {
  final String message;

  /// Détails champ par champ, quand le backend en fournit.
  final List<String> details;

  ParcoursException(this.message, {this.details = const []});

  @override
  String toString() => message;
}

class ParcoursRemoteDataSource {
  final Dio dio;

  ParcoursRemoteDataSource({required this.dio});

  /// Extrait le message le plus parlant d'une erreur Dio.
  Never _relancer(DioException e, String messageParDefaut) {
    final donnees = e.response?.data;
    if (donnees is Map) {
      final details = donnees['details'];
      if (details is List && details.isNotEmpty) {
        throw ParcoursException(
          details.first.toString(),
          details: details.map((d) => d.toString()).toList(),
        );
      }
      if (donnees['message'] != null) {
        throw ParcoursException(donnees['message'].toString());
      }
    }
    throw ParcoursException(messageParDefaut);
  }

  Map<String, dynamic> _donnees(Response reponse) {
    final corps = reponse.data;
    if (corps is Map && corps['data'] is Map) {
      return Map<String, dynamic>.from(corps['data'] as Map);
    }
    return corps is Map ? Map<String, dynamic>.from(corps) : <String, dynamic>{};
  }

  // ── § 4 : ce qu'il manque pour un document ──────────────────────────────

  Future<ExigencesDocument> exigences(String typeDocument) async {
    try {
      final reponse = await dio.get(Env.profilExigences(typeDocument));
      return ExigencesDocument.depuisJson(_donnees(reponse));
    } on DioException catch (e) {
      _relancer(e, 'Impossible de déterminer les informations nécessaires.');
    }
  }

  // ── § 9 / § 15 : contrôle avant génération ──────────────────────────────

  ///
  /// [valeursFournies] porte ce que l'utilisateur vient de saisir pour ce
  /// document sans avoir autorisé son enregistrement : le backend en tient
  /// compte pour le contrôle, mais n'écrit rien sur le compte.
  Future<VerificationGeneration> verifierAvantGeneration(
    String typeDocument, {
    Map<String, dynamic>? valeursFournies,
  }) async {
    try {
      final reponse = await dio.get(
        Env.profilVerification(typeDocument),
        queryParameters: valeursFournies == null || valeursFournies.isEmpty
            ? null
            : valeursFournies.map((c, v) => MapEntry(c, v?.toString() ?? '')),
      );
      return VerificationGeneration.depuisJson(_donnees(reponse));
    } on DioException catch (e) {
      _relancer(e, 'Impossible de vérifier vos informations.');
    }
  }

  // ── § 14 : référentiels de saisie ───────────────────────────────────────

  /// Récupère les règles appliquées par le backend et les injecte dans le
  /// validateur local, pour que l'app suive toute évolution du référentiel
  /// (nouvelle plage téléphonique par exemple) sans nouvelle version.
  ///
  /// Échec silencieux : le validateur garde alors ses valeurs par défaut.
  Future<void> synchroniserReferentiels() async {
    try {
      final reponse = await dio.get(Env.profilReferentiels);
      IdentifiantValidator.appliquerReferentiel(_donnees(reponse));
    } catch (_) {
      // Sans réseau, les règles locales suffisent — le backend revalidera.
    }
  }

  // ── Enregistrement des informations ─────────────────────────────────────

  /// Enregistre les informations réclamées au fil du parcours.
  /// Renvoie les avertissements éventuels (identifiants « format valide »).
  Future<List<String>> enregistrerInformations(Map<String, dynamic> donnees) async {
    try {
      final reponse = await dio.put(Env.profilInformations, data: donnees);
      final corps = _donnees(reponse);
      final avertissements = corps['avertissements'];
      if (avertissements is List) {
        return avertissements
            .map((a) => a is Map ? (a['message']?.toString() ?? '') : a.toString())
            .where((m) => m.isNotEmpty)
            .toList();
      }
      return const [];
    } on DioException catch (e) {
      _relancer(e, "Impossible d'enregistrer vos informations.");
    }
  }

  /// § 11 : bascule le compte en « profil complet ».
  Future<void> completerProfil(Map<String, dynamic> donnees) async {
    try {
      await dio.post(Env.profilComplet, data: donnees);
    } on DioException catch (e) {
      _relancer(e, 'Impossible de finaliser votre compte.');
    }
  }

  /// § 16 : bloc d'informations préremplies.
  Future<Map<String, dynamic>> prereemplissage() async {
    try {
      final reponse = await dio.get(Env.profilPrereemplissage);
      return _donnees(reponse);
    } on DioException catch (e) {
      _relancer(e, 'Impossible de récupérer vos informations.');
    }
  }

  // ── § 8 : autre partie ──────────────────────────────────────────────────

  Future<ResultatRechercheAutrePartie> rechercherAutrePartie(String recherche) async {
    try {
      final reponse = await dio.get(
        Env.autrePartieRecherche,
        queryParameters: {'recherche': recherche},
      );
      return ResultatRechercheAutrePartie.depuisJson(_donnees(reponse));
    } on DioException catch (e) {
      _relancer(e, 'Recherche impossible pour le moment.');
    }
  }

  /// Invite une personne à créer son compte. Renvoie le texte à partager.
  Future<String> inviterAutrePartie({
    String? email,
    String? telephone,
    String? nomInvite,
  }) async {
    try {
      final reponse = await dio.post(Env.autrePartieInviter, data: {
        if (email != null && email.isNotEmpty) 'email': email,
        if (telephone != null && telephone.isNotEmpty) 'telephone': telephone,
        if (nomInvite != null && nomInvite.isNotEmpty) 'nomInvite': nomInvite,
      });
      final corps = _donnees(reponse);
      return corps['texteAPartager']?.toString() ?? '';
    } on DioException catch (e) {
      _relancer(e, "Impossible d'envoyer l'invitation.");
    }
  }

  // ── § 12 / § 13 : justificatifs ─────────────────────────────────────────

  Future<({List<Justificatif> justificatifs, MentionsJustificatifs mentions})>
      listerJustificatifs() async {
    try {
      final reponse = await dio.get(Env.profilJustificatifs);
      final corps = _donnees(reponse);
      final liste = (corps['justificatifs'] as List?)
              ?.map((j) => Justificatif.depuisJson(Map<String, dynamic>.from(j as Map)))
              .toList() ??
          <Justificatif>[];
      final mentions = corps['mentions'] is Map
          ? MentionsJustificatifs.depuisJson(
              Map<String, dynamic>.from(corps['mentions'] as Map))
          : const MentionsJustificatifs(
              finalite: '', stockage: '', acces: '', conservation: '', suppression: '');
      return (justificatifs: liste, mentions: mentions);
    } on DioException catch (e) {
      _relancer(e, 'Impossible de charger vos justificatifs.');
    }
  }

  Future<Justificatif> deposerJustificatif({
    required String type,
    required File fichier,
    void Function(int envoye, int total)? surProgression,
  }) async {
    try {
      final formData = FormData.fromMap({
        'type': type,
        'justificatif': await MultipartFile.fromFile(
          fichier.path,
          filename: fichier.path.split(Platform.pathSeparator).last,
        ),
      });
      final reponse = await dio.post(
        Env.profilJustificatifs,
        data: formData,
        onSendProgress: surProgression,
        options: Options(contentType: 'multipart/form-data'),
      );
      return Justificatif.depuisJson(_donnees(reponse));
    } on DioException catch (e) {
      _relancer(e, 'Impossible de transmettre ce justificatif.');
    }
  }

  Future<void> supprimerJustificatif(String id) async {
    try {
      await dio.delete('${Env.profilJustificatifs}/$id');
    } on DioException catch (e) {
      _relancer(e, 'Impossible de supprimer ce justificatif.');
    }
  }
}
