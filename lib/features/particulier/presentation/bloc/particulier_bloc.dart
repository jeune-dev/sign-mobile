import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_stats.dart';
import '../../domain/usecases/get_factures_client.dart';
import '../../domain/usecases/get_contrats_client.dart';
import '../../data/models/particulier_facture_model.dart';
import 'particulier_event.dart';
import 'particulier_state.dart';

class ParticulierBloc extends Bloc<ParticulierEvent, ParticulierState> {
  final GetDashboardStats       getDashboardStats;
  final GetFacturesClient       getFacturesClient;
  final GetContratsClient       getContratsClient;
  final GetContratsByTypeClient getContratsByTypeClient;
  final GetContratDetailClient  getContratDetailClient;
  final SignerContratClient     signerContratClient;

  ParticulierBloc({
    required this.getDashboardStats,
    required this.getFacturesClient,
    required this.getContratsClient,
    required this.getContratsByTypeClient,
    required this.getContratDetailClient,
    required this.signerContratClient,
  }) : super(ParticulierInitial()) {
    on<LoadDashboardStats>(_onLoadDashboard);
    on<LoadFactures>(_onLoadFactures);
    on<LoadContrats>(_onLoadContrats);
    on<LoadContratDetail>(_onLoadContratDetail);
    on<SignerContrat>(_onSignerContrat);
  }

  Future<void> _onLoadDashboard(
    LoadDashboardStats event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    try {
      final data    = await getDashboardStats();
      final factures = ((data['recentesFactures'] as List?) ?? [])
          .map((e) => ParticulierFactureModel.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      emit(DashboardLoaded(
        stats:            data['stats'] as Map<String, dynamic>? ?? {},
        recentesFactures: factures,
      ));
    } catch (e) {
      emit(ParticulierError(e.toString()));
    }
  }

  Future<void> _onLoadFactures(
    LoadFactures event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    try {
      final factures = await getFacturesClient(statut: event.statut);
      emit(FacturesLoaded(factures: factures, statut: event.statut));
    } catch (e) {
      emit(ParticulierError(e.toString()));
    }
  }

  Future<void> _onLoadContrats(
    LoadContrats event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    try {
      final contrats = event.type == null
          ? await getContratsClient(statut: event.statut)
          : await getContratsByTypeClient(type: event.type!, statut: event.statut);
      emit(ContratsLoaded(contrats: contrats, type: event.type, statut: event.statut));
    } catch (e) {
      emit(ParticulierError(e.toString()));
    }
  }

  Future<void> _onLoadContratDetail(
    LoadContratDetail event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    try {
      final contrat = await getContratDetailClient(type: event.type, contratId: event.contratId);
      emit(ContratDetailLoaded(contrat: contrat));
    } catch (e) {
      emit(ParticulierError(e.toString()));
    }
  }

  Future<void> _onSignerContrat(
    SignerContrat event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ContratSignatureEnCours());
    try {
      await signerContratClient(
        type:       event.type,
        contratId:  event.contratId,
        signature:  event.signature,
      );
      emit(const ContratSigne());
    } catch (e) {
      emit(ParticulierError(e.toString()));
    }
  }
}
