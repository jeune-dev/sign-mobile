import 'package:sign_application/features/dashboard/domain/entities/dashboard_stats.dart';

abstract class DashboardState {}

class DashboardInitial extends DashboardState {}

class DashboardLoading extends DashboardState {}

class DashboardLoaded extends DashboardState {
  final DashboardStats stats;
  final List<dynamic> documentsRecents;
  DashboardLoaded({required this.stats, required this.documentsRecents});
}

class DashboardDocumentBytes extends DashboardState {
  final List<int> bytes;
  final String documentId;
  DashboardDocumentBytes({required this.bytes, required this.documentId});
}

class DashboardError extends DashboardState {
  final String message;
  DashboardError(this.message);
}
