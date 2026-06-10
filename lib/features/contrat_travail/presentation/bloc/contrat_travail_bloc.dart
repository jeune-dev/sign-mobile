import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_contrats_travail.dart';
import '../../domain/usecases/get_contrat_travail_detail.dart';
import '../../domain/usecases/creer_contrat_travail.dart';
import '../../domain/usecases/signer_contrat_travail.dart';
import '../../domain/usecases/telecharger_contrat_travail.dart';
import '../../domain/usecases/get_stats_travail.dart';
import '../../domain/entities/contrat_travail.dart';
import 'contrat_travail_event.dart';
import 'contrat_travail_state.dart';

class ContratTravailBloc extends Bloc<ContratTravailEvent, ContratTravailState> {
  final GetContratsTravail getContratsTravail;
  final GetContratTravailDetail getContratTravailDetail;
  final CreerContratTravail creerContratTravail;
  final SignerContratTravail signerContratTravail;
  final TelechargerContratTravail telechargerContratTravail;
  final GetStatsTravail getStatsTravail;

  List<ContratTravail> _contrats = [];
  int _currentPage = 1;

  ContratTravailBloc({
    required this.getContratsTravail,
    required this.getContratTravailDetail,
    required this.creerContratTravail,
    required this.signerContratTravail,
    required this.telechargerContratTravail,
    required this.getStatsTravail,
  }) : super(ContratTravailInitial()) {
    on<LoadContratsTravail>(_onLoadContrats);
    on<LoadMoreContratsTravail>(_onLoadMoreContrats);
    on<LoadContratTravailDetail>(_onLoadDetail);
    on<CreerContratTravailEvent>(_onCreerContrat);
    on<SignerContratTravailEvent>(_onSignerContrat);
    on<TelechargerContratTravailEvent>(_onTelechargerContrat);
    on<ResetContratTravailState>((_, emit) => emit(ContratTravailInitial()));
    on<LoadStatsTravail>(_onLoadStats);
  }

  Future<void> _onLoadContrats(LoadContratsTravail event, Emitter<ContratTravailState> emit) async {
    if (_contrats.isNotEmpty) {
      emit(ContratsTravailLoaded(contrats: _contrats, isRefreshing: true));
    } else {
      emit(ContratTravailLoading());
    }
    _currentPage = 1;
    _contrats = [];
    final result = await getContratsTravail(page: 1, limit: event.limit);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (contrats) {
        _contrats = contrats;
        emit(ContratsTravailLoaded(contrats: _contrats, hasMore: contrats.length >= event.limit));
      },
    );
  }

  Future<void> _onLoadMoreContrats(LoadMoreContratsTravail event, Emitter<ContratTravailState> emit) async {
    _currentPage++;
    final result = await getContratsTravail(page: _currentPage, limit: 10);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (contrats) {
        _contrats = [..._contrats, ...contrats];
        emit(ContratsTravailLoaded(contrats: _contrats, hasMore: contrats.isNotEmpty));
      },
    );
  }

  Future<void> _onLoadDetail(LoadContratTravailDetail event, Emitter<ContratTravailState> emit) async {
    emit(ContratTravailLoading());
    final result = await getContratTravailDetail(event.contratId);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (contrat) => emit(ContratTravailDetailLoaded(contrat)),
    );
  }

  Future<void> _onCreerContrat(CreerContratTravailEvent event, Emitter<ContratTravailState> emit) async {
    emit(ContratTravailLoading());
    final result = await creerContratTravail(event.data);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (_) => emit(ContratTravailSuccess(message: 'Contrat de travail créé avec succès')),
    );
  }

  Future<void> _onSignerContrat(SignerContratTravailEvent event, Emitter<ContratTravailState> emit) async {
    emit(ContratTravailLoading());
    final result = await signerContratTravail(event.contratId, event.signature);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (_) => emit(ContratTravailSuccess(message: 'Contrat signé avec succès')),
    );
  }

  Future<void> _onLoadStats(LoadStatsTravail event, Emitter<ContratTravailState> emit) async {
    emit(ContratTravailStatsLoading());
    final result = await getStatsTravail();
    result.fold(
      (_) => emit(ContratTravailStatsLoaded(total: 0, signes: 0, enAttente: 0)),
      (stats) => emit(ContratTravailStatsLoaded(
        total:     stats['total']     ?? 0,
        signes:    stats['signes']    ?? 0,
        enAttente: stats['enAttente'] ?? 0,
      )),
    );
  }

  Future<void> _onTelechargerContrat(TelechargerContratTravailEvent event, Emitter<ContratTravailState> emit) async {
    emit(ContratTravailLoading());
    final result = await telechargerContratTravail(event.contratId);
    result.fold(
      (failure) => emit(ContratTravailError(failure.errorMessage)),
      (bytes) => emit(ContratTravailBytes(bytes: bytes, contratId: event.contratId, titre: event.titre)),
    );
  }
}
