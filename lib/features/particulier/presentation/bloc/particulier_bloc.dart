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
    final result = await getDashboardStats();
    result.fold(
      (failure) => emit(ParticulierError(failure.errorMessage)),
      (data) {
        final factures = ((data['recentesFactures'] as List?) ?? [])
            .map((e) => ParticulierFactureModel.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList();
        emit(DashboardLoaded(
          stats:            data['stats'] as Map<String, dynamic>? ?? {},
          recentesFactures: factures,
        ));
      },
    );
  }

  Future<void> _onLoadFactures(
    LoadFactures event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    final result = await getFacturesClient(statut: event.statut);
    result.fold(
      (failure) => emit(ParticulierError(failure.errorMessage)),
      (factures) => emit(FacturesLoaded(factures: factures, statut: event.statut)),
    );
  }

  Future<void> _onLoadContrats(
    LoadContrats event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    final result = event.type == null
        ? await getContratsClient(statut: event.statut)
        : await getContratsByTypeClient(type: event.type!, statut: event.statut);
    result.fold(
      (failure) => emit(ParticulierError(failure.errorMessage)),
      (contrats) => emit(ContratsLoaded(contrats: contrats, type: event.type, statut: event.statut)),
    );
  }

  Future<void> _onLoadContratDetail(
    LoadContratDetail event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ParticulierLoading());
    final result = await getContratDetailClient(type: event.type, contratId: event.contratId);
    result.fold(
      (failure) => emit(ParticulierError(failure.errorMessage)),
      (contrat) => emit(ContratDetailLoaded(contrat: contrat)),
    );
  }

  Future<void> _onSignerContrat(
    SignerContrat event,
    Emitter<ParticulierState> emit,
  ) async {
    emit(ContratSignatureEnCours());
    final result = await signerContratClient(
      type:      event.type,
      contratId: event.contratId,
      signature: event.signature,
    );
    result.fold(
      (failure) => emit(ParticulierError(failure.errorMessage)),
      (_)       => emit(const ContratSigne()),
    );
  }
}
