import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/client_model.dart';

abstract class ClientRemoteDataSource {
  Future<List<ClientModel>> getClients();
  Future<List<ClientModel>> rechercherClients(String query);
  Future<void> ajouterClient(Map<String, dynamic> data);
}

class ClientRemoteDataSourceImpl implements ClientRemoteDataSource {
  final Dio dio;
  ClientRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ClientModel>> getClients() async {
    final response = await dio.get(Env.clientListe);
    final utilisateurs = response.data['utilisateurs'] as List? ?? [];
    return utilisateurs
        .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
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
    final utilisateurs = response.data['utilisateurs'] as List? ?? [];
    return utilisateurs
        .map((e) => ClientModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<void> ajouterClient(Map<String, dynamic> data) async {
    await dio.post(Env.clientAjout, data: data);
  }
}
