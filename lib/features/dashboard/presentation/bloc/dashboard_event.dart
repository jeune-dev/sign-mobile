abstract class DashboardEvent {}

class LoadDashboard extends DashboardEvent {}

class OuvrirDocumentDashboardEvent extends DashboardEvent {
  final String documentId;
  OuvrirDocumentDashboardEvent(this.documentId);
}

class ResetDashboardState extends DashboardEvent {}
