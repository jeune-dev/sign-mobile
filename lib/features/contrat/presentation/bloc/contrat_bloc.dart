import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_contrats_immobilier.dart';
import '../../domain/usecases/creer_contrat_bail.dart';
import '../../domain/usecases/telecharger_contrat.dart';
import '../../domain/entities/contrat_bail.dart';
import 'contrat_event.dart';
import 'contrat_state.dart';

class ContratBloc extends Bloc<ContratEvent, ContratState> {
  final GetContratsImmobilier getContratsImmobilier;
  final CreerContratBail creerContratBail;
  final TelechargerContrat telechargerContrat;

  List<ContratBail> _contrats = [];
  int _currentPage = 1;

  ContratBloc({
    required this.getContratsImmobilier,
    required this.creerContratBail,
    required this.telechargerContrat,
  }) : super(ContratInitial()) {
    on<LoadContratsImmobilier>(_onLoadContrats);
    on<LoadMoreContratsImmobilier>(_onLoadMoreContrats);
    on<CreerContratBailEvent>(_onCreerContrat);
    on<TelechargerContratEvent>(_onTelechargerContrat);
    on<ResetContratState>((_, emit) => emit(ContratInitial()));
  }

  Future<void> _onLoadContrats(
    LoadContratsImmobilier event,
    Emitter<ContratState> emit,
  ) async {
    if (_contrats.isNotEmpty) {
      emit(ContratsLoaded(contrats: _contrats, isRefreshing: true));
    } else {
      emit(ContratLoading());
    }
    _currentPage = 1;
    _contrats = [];
    final result = await getContratsImmobilier(page: 1, limit: event.limit);
    result.fold(
      (failure) => emit(ContratError(failure.errorMessage)),
      (contrats) {
        _contrats = contrats;
        emit(ContratsLoaded(contrats: _contrats, hasMore: contrats.length >= event.limit));
      },
    );
  }

  Future<void> _onLoadMoreContrats(
    LoadMoreContratsImmobilier event,
    Emitter<ContratState> emit,
  ) async {
    _currentPage++;
    final result = await getContratsImmobilier(page: _currentPage, limit: 10);
    result.fold(
      (failure) => emit(ContratError(failure.errorMessage)),
      (contrats) {
        _contrats = [..._contrats, ...contrats];
        emit(ContratsLoaded(contrats: _contrats, hasMore: contrats.isNotEmpty));
      },
    );
  }

  Future<void> _onCreerContrat(
    CreerContratBailEvent event,
    Emitter<ContratState> emit,
  ) async {
    emit(ContratLoading());
    final result = await creerContratBail(event.data);
    result.fold(
      (failure) => emit(ContratError(failure.errorMessage)),
      (_) => emit(ContratSuccess(message: 'Contrat créé avec succès')),
    );
  }

  Future<void> _onTelechargerContrat(
    TelechargerContratEvent event,
    Emitter<ContratState> emit,
  ) async {
    emit(ContratLoading());
    final result = await telechargerContrat(event.contratId);
    result.fold(
      (failure) => emit(ContratError(failure.errorMessage)),
      (bytes) => emit(ContratBytes(bytes: bytes, contratId: event.contratId, titre: event.titre)),
    );
  }
}
