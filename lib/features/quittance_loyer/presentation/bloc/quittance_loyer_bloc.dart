import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_quittances.dart';
import '../../domain/usecases/get_quittance_detail.dart';
import '../../domain/usecases/creer_quittance.dart';
import '../../domain/usecases/telecharger_quittance.dart';
import '../../domain/entities/quittance_loyer.dart';
import 'quittance_loyer_event.dart';
import 'quittance_loyer_state.dart';

class QuittanceLoyerBloc extends Bloc<QuittanceLoyerEvent, QuittanceLoyerState> {
  final GetQuittances getQuittances;
  final GetQuittanceDetail getQuittanceDetail;
  final CreerQuittance creerQuittance;
  final TelechargerQuittance telechargerQuittance;

  List<QuittanceLoyer> _quittances = [];
  int _currentPage = 1;

  QuittanceLoyerBloc({
    required this.getQuittances,
    required this.getQuittanceDetail,
    required this.creerQuittance,
    required this.telechargerQuittance,
  }) : super(QuittanceLoyerInitial()) {
    on<LoadQuittances>(_onLoadQuittances);
    on<LoadMoreQuittances>(_onLoadMoreQuittances);
    on<LoadQuittanceDetail>(_onLoadDetail);
    on<CreerQuittanceEvent>(_onCreerQuittance);
    on<TelechargerQuittanceEvent>(_onTelechargerQuittance);
    on<ResetQuittanceState>((_, emit) => emit(QuittanceLoyerInitial()));
  }

  Future<void> _onLoadQuittances(LoadQuittances event, Emitter<QuittanceLoyerState> emit) async {
    emit(QuittanceLoyerLoading());
    _currentPage = 1;
    _quittances = [];
    final result = await getQuittances(page: 1, limit: event.limit);
    result.fold(
      (failure) => emit(QuittanceLoyerError(failure.errorMessage)),
      (quittances) {
        _quittances = quittances;
        emit(QuittancesLoaded(quittances: _quittances, hasMore: quittances.length >= event.limit));
      },
    );
  }

  Future<void> _onLoadMoreQuittances(LoadMoreQuittances event, Emitter<QuittanceLoyerState> emit) async {
    _currentPage++;
    final result = await getQuittances(page: _currentPage, limit: 10);
    result.fold(
      (failure) => emit(QuittanceLoyerError(failure.errorMessage)),
      (quittances) {
        _quittances = [..._quittances, ...quittances];
        emit(QuittancesLoaded(quittances: _quittances, hasMore: quittances.isNotEmpty));
      },
    );
  }

  Future<void> _onLoadDetail(LoadQuittanceDetail event, Emitter<QuittanceLoyerState> emit) async {
    emit(QuittanceLoyerLoading());
    final result = await getQuittanceDetail(event.quittanceId);
    result.fold(
      (failure) => emit(QuittanceLoyerError(failure.errorMessage)),
      (quittance) => emit(QuittanceDetailLoaded(quittance)),
    );
  }

  Future<void> _onCreerQuittance(CreerQuittanceEvent event, Emitter<QuittanceLoyerState> emit) async {
    emit(QuittanceLoyerLoading());
    final result = await creerQuittance(event.data);
    result.fold(
      (failure) => emit(QuittanceLoyerError(failure.errorMessage)),
      (_) => emit(QuittanceLoyerSuccess(message: 'Quittance créée avec succès')),
    );
  }

  Future<void> _onTelechargerQuittance(TelechargerQuittanceEvent event, Emitter<QuittanceLoyerState> emit) async {
    emit(QuittanceLoyerLoading());
    final result = await telechargerQuittance(event.quittanceId);
    result.fold(
      (failure) => emit(QuittanceLoyerError(failure.errorMessage)),
      (bytes) => emit(QuittanceBytes(bytes: bytes, quittanceId: event.quittanceId, mode: event.mode)),
    );
  }
}
