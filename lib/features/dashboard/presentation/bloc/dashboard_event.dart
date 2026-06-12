abstract class DashboardEvent {}

class LoadDashboard extends DashboardEvent {}

class OuvrirDocumentDashboardEvent extends DashboardEvent {
  final String documentId;
  final String titre;
  OuvrirDocumentDashboardEvent(this.documentId, {this.titre = ''});
}

class ResetDashboardState extends DashboardEvent {}
