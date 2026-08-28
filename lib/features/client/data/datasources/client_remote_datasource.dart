import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/client_model.dart';

// Fonction top-level (requis par compute()) : parse le JSON brut en isolate
// séparé pour ne pas bloquer le thread UI sur un portefeuille client volumineux.
List<ClientModel> _parseClients(List<dynamic> raw) => raw
    .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e)))
    .toList();

abstract class ClientRemoteDataSource {
  Future<List<ClientModel>> getClients();
  Future<List<ClientModel>> rechercherClients(String query);
  Future<void> ajouterClient(Map<String, dynamic> data);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final Dio dio;
  ClientRemoteDataSourceImpl({required this.dio});

  // Le backend pagine réellement cet endpoint (page/limit + pagination.totalPages,
  // cf. gestionclient.controller.js:listerClients). On boucle sur les pages côté
  // client pour ne jamais faire transiter un payload unique non borné, tout en
  // gardant la même signature (liste complète) pour ne pas casser les appelants
  // existants — un garde-fou dur (10 pages max = 2000 clients) évite tout risque
  // d'appels réseau illimités si un compte a un portefeuille anormalement gros.
  static const int _pageSize = 200;
  static const int _maxPages = 10;

  @override
  Future<List<ClientModel>> getClients() async {
    final List<dynamic> brut = [];
    int page = 1;
    while (page <= _maxPages) {
      final response = await dio.get(
        Env.clientListe,
        queryParameters: {'page': page, 'limit': _pageSize},
      );
      final data = response.data['data'] as Map<String, dynamic>? ?? {};
      final utilisateurs = data['utilisateurs'] as List? ?? [];
      brut.addAll(utilisateurs);

      final pagination = data['pagination'] as Map<String, dynamic>?;
      final totalPages = pagination?['totalPages'] as int? ?? 1;
      if (page >= totalPages || utilisateurs.isEmpty) break;
      page++;
    }
    // Parsing sur un isolate séparé (compute()) — évite de bloquer le thread
    // UI le temps de convertir un portefeuille client volumineux en objets.
    return compute(_parseClients, brut);
  }

  @override
  Future<List<ClientModel>> rechercherClients(String query) async {
    final response = await dio.get(
      Env.clientRecherche,
      queryParameters: {
        'nom': query,
        'prenom': query,
        'email': query,
        'carte_identite_national_num': query,
        'telephone': query,
      },
    );
    final data = response.data['data'] as Map<String, dynamic>? ?? {};
    final utilisateurs = data['utilisateurs'] as List? ?? [];
    return utilisateurs
        .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> ajouterClient(Map<String, dynamic> data) async {
    // Création via l'endpoint auth register (role Particulier)
    await dio.post(Env.register, data: data);
  }
}
