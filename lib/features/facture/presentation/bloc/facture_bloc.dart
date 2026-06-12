import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_factures.dart';
import '../../domain/usecases/creer_facture.dart';
import '../../domain/usecases/ouvrir_document.dart';
import '../../domain/usecases/mettre_a_jour_facture.dart';
import '../../domain/usecases/renvoyer_facture.dart';
import '../../domain/entities/facture.dart';
import 'facture_event.dart';
import 'facture_state.dart';

class FactureBloc extends Bloc<FactureEvent, FactureState> {
  final GetFactures getFactures;
  final CreerFacture creerFacture;
  final OuvrirDocument ouvrirDocument;
  final MettreAJourFacture mettreAJourFacture;
  final RenvoyerFacture renvoyerFacture;

  List<Facture> _factures = [];
  int _currentPage = 1;

  FactureBloc({
    required this.getFactures,
    required this.creerFacture,
    required this.ouvrirDocument,
    required this.mettreAJourFacture,
    required this.renvoyerFacture,
  }) : super(FactureInitial()) {
    on<LoadFactures>(_onLoadFactures);
    on<LoadMoreFactures>(_onLoadMoreFactures);
    on<GoToPage>((event, emit) async {
      add(LoadFactures(page: event.page, limit: 10));
    });
    on<CreerFactureEvent>(_onCreerFacture);
    on<OuvrirDocumentEvent>(_onOuvrirDocument);
    on<ResetFactureState>((_, emit) => emit(FactureInitial()));
    on<MettreAJourFactureEvent>(_onMettreAJourFacture);
    on<RenvoyerFactureEvent>(_onRenvoyerFacture);
  }

  Future<void> _onLoadFactures(
    LoadFactures event,
    Emitter<FactureState> emit,
  ) async {
    emit(FactureLoading());
    _currentPage = event.page;
    if (_currentPage == 1) _factures = [];
    final result = await getFactures(page: _currentPage, limit: event.limit);
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (pageResult) {
        _factures = pageResult.factures;
        emit(FacturesLoaded(
          factures: _factures,
          hasMore: _currentPage < pageResult.totalPages,
          totalPages: pageResult.totalPages,
          total: pageResult.total,
          currentPage: pageResult.currentPage,
        ));
      },
    );
  }

  Future<void> _onLoadMoreFactures(
    LoadMoreFactures event,
    Emitter<FactureState> emit,
  ) async {
    _currentPage++;
    final result = await getFactures(page: _currentPage, limit: 10);
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (pageResult) {
        _factures = [..._factures, ...pageResult.factures];
        emit(FacturesLoaded(
          factures: _factures,
          hasMore: _currentPage < pageResult.totalPages,
          totalPages: pageResult.totalPages,
          total: pageResult.total,
          currentPage: pageResult.currentPage,
        ));
      },
    );
  }

  Future<void> _onCreerFacture(
    CreerFactureEvent event,
    Emitter<FactureState> emit,
  ) async {
    emit(FactureLoading());
    final result = await creerFacture(event.data);
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (_) => emit(FactureSuccess(message: 'Facture créée avec succès')),
    );
  }

  Future<void> _onOuvrirDocument(
    OuvrirDocumentEvent event,
    Emitter<FactureState> emit,
  ) async {
    emit(FactureLoading());
    final result = await ouvrirDocument(event.documentId);
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (bytes) => emit(DocumentBytes(bytes, titre: event.titre)),
    );
  }

  Future<void> _onMettreAJourFacture(
    MettreAJourFactureEvent event,
    Emitter<FactureState> emit,
  ) async {
    emit(FactureLoading());
    final result = await mettreAJourFacture(
      documentId: event.documentId,
      avance: event.avance,
      statut: event.statut,
    );
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (data) => emit(FactureMiseAJourSuccess(data)),
    );
  }

  Future<void> _onRenvoyerFacture(
    RenvoyerFactureEvent event,
    Emitter<FactureState> emit,
  ) async {
    emit(FactureRenvoyeeLoading());
    final result = await renvoyerFacture(event.documentId);
    result.fold(
      (failure) => emit(FactureError(failure.errorMessage)),
      (_) => emit(FactureRenvoyeeSuccess()),
    );
  }
}
