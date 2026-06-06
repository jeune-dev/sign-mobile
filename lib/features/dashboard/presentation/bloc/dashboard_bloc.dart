import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/usecases/get_dashboard_stats.dart';
import '../../domain/usecases/get_documents_recents.dart';
import '../../domain/usecases/ouvrir_document_dashboard.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetDashboardStats getDashboardStats;
  final GetDocumentsRecents getDocumentsRecents;
  final OuvrirDocumentDashboard ouvrirDocument;

  DashboardBloc({
    required this.getDashboardStats,
    required this.getDocumentsRecents,
    required this.ouvrirDocument,
  }) : super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<OuvrirDocumentDashboardEvent>(_onOuvrirDocument);
    on<ResetDashboardState>((_, emit) => emit(DashboardInitial()));
  }

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final statsResult = await getDashboardStats();
    final docsResult = await getDocumentsRecents(limit: 5);

    statsResult.fold(
      (failure) => emit(DashboardError(failure.errorMessage)),
      (stats) {
        docsResult.fold(
          (failure) => emit(DashboardLoaded(stats: stats, documentsRecents: [])),
          (docs) => emit(DashboardLoaded(stats: stats, documentsRecents: docs)),
        );
      },
    );
  }

  Future<void> _onOuvrirDocument(
    OuvrirDocumentDashboardEvent event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());
    final result = await ouvrirDocument(event.documentId);
    result.fold(
      (failure) => emit(DashboardError(failure.errorMessage)),
      (bytes) => emit(DashboardDocumentBytes(bytes: bytes, documentId: event.documentId)),
    );
  }
}
