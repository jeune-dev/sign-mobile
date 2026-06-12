import 'package:flutter_bloc/flutter_bloc.dart';
import 'fiche_paie_event.dart';
import 'fiche_paie_state.dart';
import '../../domain/usecases/cree_fiche_paie.dart';
import '../../domain/entities/fiche_paie.dart';

class FichePaieBloc extends Bloc<FichePaieEvent, FichePaieState> {
  final CreerFichePaie creerFichePaie;
  final GetFichesPaie getFichesPaie;
  final TelechargerFichePaie telechargerFichePaie;

  List<FichePaie> _fiches = [];
  int _currentPage = 1;

  FichePaieBloc({
    required this.creerFichePaie,
    required this.getFichesPaie,
    required this.telechargerFichePaie,
  }) : super(FichePaieInitial()) {
    on<CreerFichePaieEvent>(_onCreerFichePaie);
    on<LoadFichesPaieEvent>(_onLoadFiches);
    on<LoadMoreFichesPaieEvent>(_onLoadMoreFiches);
    on<TelechargerFichePaieEvent>(_onTelechargerFiche);
  }

  Future<void> _onCreerFichePaie(
    CreerFichePaieEvent event,
    Emitter<FichePaieState> emit,
  ) async {
    emit(FichePaieLoading());
    final result = await creerFichePaie(event.fiche);
    result.fold(
      (failure) => emit(FichePaieError(failure.errorMessage)),
      (fiche)   => emit(FichePaieSuccess(fiche)),
    );
  }

  Future<void> _onLoadFiches(
    LoadFichesPaieEvent event,
    Emitter<FichePaieState> emit,
  ) async {
    // Emit refreshing state with cached list if available, else full loading
    if (_fiches.isNotEmpty) {
      emit(FichesPaieLoaded(fiches: _fiches, isRefreshing: true));
    } else {
      emit(FichePaieLoading());
    }
    _currentPage = 1;
    final result = await getFichesPaie(page: 1, limit: event.limit);
    result.fold(
      (failure) => emit(FichePaieError(failure.errorMessage)),
      (fiches) {
        _fiches = fiches;
        emit(FichesPaieLoaded(fiches: _fiches, hasMore: fiches.length >= event.limit));
      },
    );
  }

  Future<void> _onLoadMoreFiches(
    LoadMoreFichesPaieEvent event,
    Emitter<FichePaieState> emit,
  ) async {
    _currentPage++;
    final result = await getFichesPaie(page: _currentPage, limit: 10);
    result.fold(
      (failure) => emit(FichePaieError(failure.errorMessage)),
      (fiches) {
        _fiches = [..._fiches, ...fiches];
        emit(FichesPaieLoaded(fiches: _fiches, hasMore: fiches.isNotEmpty));
      },
    );
  }

  Future<void> _onTelechargerFiche(
    TelechargerFichePaieEvent event,
    Emitter<FichePaieState> emit,
  ) async {
    emit(FichePaieLoading());
    final result = await telechargerFichePaie(event.ficheId);
    result.fold(
      (failure) => emit(FichePaieError(failure.errorMessage)),
      (bytes)   => emit(FichePaieBytes(bytes: bytes, titre: event.titre)),
    );
  }
}
