import 'package:dio/dio.dart';
import 'package:sign_application/core/config/env.dart';
import '../models/contrat_travail_model.dart';

abstract class ContratTravailRemoteDataSource {
  Future<List<ContratTravailModel>> getContratsTravail({int page, int limit});
  Future<ContratTravailModel> getContratTravailDetail(String contratId);
  Future<void> creerContratTravail(Map<String, dynamic> data);
  Future<void> signerContratTravail(String contratId, String signature);
  Future<List<int>> telechargerContratTravail(String contratId);
}

class ContratTravailRemoteDataSourceImpl implements ContratTravailRemoteDataSource {
  final Dio dio;
  ContratTravailRemoteDataSourceImpl({required this.dio});

  @override
  Future<List<ContratTravailModel>> getContratsTravail({int page = 1, int limit = 10}) async {
    final response = await dio.get(
      Env.contratTravailListe,
      queryParameters: {'page': page, 'limit': limit},
    );

    final raw = response.data['data'];

    // Gère : { data: [...] } ou { data: { rows: [...] } } ou { data: { contrats: [...] } }
    final List dataList = raw is List
        ? raw
        : (raw is Map && raw['rows'] is List)
            ? raw['rows'] as List
            : (raw is Map && raw['contrats'] is List)
                ? raw['contrats'] as List
                : [];

    final result = <ContratTravailModel>[];
    for (final e in dataList) {
      try {
        result.add(ContratTravailModel.fromJson(Map<String, dynamic>.from(e as Map)));
      } catch (_) {
        // Item ignoré silencieusement si parsing échoue
      }
    }
    return result;
  }

  @override
  Future<ContratTravailModel> getContratTravailDetail(String contratId) async {
    final response = await dio.get('${Env.contratTravailDetail}/$contratId');
    return ContratTravailModel.fromJson(
      Map<String, dynamic>.from(response.data['data']),
    );
  }

  @override
  Future<void> creerContratTravail(Map<String, dynamic> data) async {
    // Backend attend : { salarieId, signature_employeur, data: { ...reste } }
    final salarieId          = data.remove('salarieId');
    final signatureEmployeur = data.remove('signature_employeur') ?? '';
    data['missions'] ??= [];
    final body = {
      'salarieId':           salarieId,
      'signature_employeur': signatureEmployeur,
      'data':                data,
    };
    await dio.post(Env.contratTravailCreer, data: body);
  }

  @override
  Future<void> signerContratTravail(String contratId, String signature) async {
    await dio.post(
      '${Env.contratTravailSigner}/$contratId/sign',
      data: {'signature': signature},
    );
  }

  @override
  Future<List<int>> telechargerContratTravail(String contratId) async {
    // VULN-M01 : validateStatus restreint aux 2xx uniquement
    final response = await dio.get(
      '${Env.contratTravailTelecharger}/$contratId/download',
      options: Options(
        responseType: ResponseType.bytes,
        validateStatus: (status) => status != null && status >= 200 && status < 300,
      ),
    );
    return List<int>.from(response.data);
  }
}
