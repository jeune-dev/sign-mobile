import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/etat_logement_model.dart';
import 'package:sign_application/core/models/document_cree.dart';

abstract class EtatLogementRemoteDataSource {
  Future<List<EtatLogementModel>> getEtatsLogement();
  Future<EtatLogementModel> getEtatLogementDetail(String etatId);
  Future<DocumentCree> creerEtatLogement(String contratId, Map<String, dynamic> data);
  Future<void> signerEtatLogement(String etatId, String signature);
  Future<List<int>> telechargerEtatLogement(String etatId);
}

class EtatLogementRemoteDataSourceImpl implements EtatLogementRemoteDataSource {
  final Dio dio;
  EtatLogementRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<EtatLogementModel>> getEtatsLogement() async {
    final response = await dio.get(Env.etatLogementBase);
    final data = response.data['data'] as List? ?? [];
    return data
        .map((e) => EtatLogementModel.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  @override
  Future<EtatLogementModel> getEtatLogementDetail(String etatId) async {
    final response = await dio.get('${Env.etatLogementBase}/$etatId');
    return EtatLogementModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  @override
  Future<DocumentCree> creerEtatLogement(
    String contratId,
    Map<String, dynamic> data,
  ) async {
    // La reponse porte le document cree : on en retient
    // l'identifiant et le numero pour l'ecran de confirmation (§ 9).
    final reponse = await dio.post('${Env.etatLogementBase}/$contratId', data: data);
    return DocumentCree.depuisReponse(reponse.data);
  }

  @override
  Future<void> signerEtatLogement(String etatId, String signature) async {
    await dio.post(
      '${Env.etatLogementBase}/$etatId/signer',
      data: {'signature': signature},
    );
  }

  @override
  Future<List<int>> telechargerEtatLogement(String etatId) async {
    // VULN-M01 : validateStatus restreint aux 2xx uniquement
    final response = await dio.get(
      '${Env.etatLogementBase}/$etatId/pdf',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );
    return List<int>.from(response.data);
  }
}
