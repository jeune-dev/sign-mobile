import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/autre_contrat_model.dart';
import 'package:sign_application/core/models/document_cree.dart';

abstract class AutreContratRemoteDataSource {
  Future<List<AutreContratModel>> getContrats(String type);
  Future<AutreContratModel> getContratDetail(String type, String id);
  Future<DocumentCree> creerContrat(String type, Map<String, dynamic> body);
  Future<void> signerContrat(String type, String id, String signature);
  Future<List<int>> telechargerContrat(String type, String id);
}

class AutreContratRemoteDataSourceImpl implements AutreContratRemoteDataSource {
  final Dio dio;
  AutreContratRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<AutreContratModel>> getContrats(String type) async {
    // Pas de slash final — certains reverse proxies (Render.com) renvoient 404 avec trailing slash
    final response = await dio.get(Env.autresContratsBase(type));
    // Gère les deux structures : { data: [...] } ou { data: { contrats: [...] } }
    final raw = response.data['data'];
    final List dataList = raw is List
        ? raw
        : (raw is Map && raw['contrats'] is List)
            ? raw['contrats'] as List
            : [];
    return dataList
        .map((e) => AutreContratModel.fromJson(Map<String, dynamic>.from(e as Map), type))
        .toList();
  }

  @override
  Future<AutreContratModel> getContratDetail(String type, String id) async {
    final response = await dio.get('${Env.autresContratsBase(type)}/$id');
    return AutreContratModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
      type,
    );
  }

  @override
  Future<DocumentCree> creerContrat(String type, Map<String, dynamic> body) async {
    final reponse =
        await dio.post('${Env.autresContratsBase(type)}/creation', data: body);
    // Le backend renvoie le contrat cree : on en garde l'identifiant et le
    // numero, de quoi afficher le document juste apres sa generation (§ 9).
    return DocumentCree.depuisReponse(reponse.data);
  }

  @override
  Future<void> signerContrat(String type, String id, String signature) async {
    await dio.post(
      '${Env.autresContratsBase(type)}/$id/sign',
      data: {'signature': signature},
    );
  }

  @override
  Future<List<int>> telechargerContrat(String type, String id) async {
    // VULN-M01 : validateStatus restreint aux 2xx uniquement
    final response = await dio.get(
      '${Env.autresContratsBase(type)}/$id/download',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    return List<int>.from(response.data);
  }
}
