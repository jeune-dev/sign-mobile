abstract class FactureEvent {}

class LoadFactures extends FactureEvent {
  final int page;
  final int limit;
  LoadFactures({this.page = 1, this.limit = 10});
}

class GoToPage extends FactureEvent {
  final int page;
  GoToPage(this.page);
}

class LoadMoreFactures extends FactureEvent {}

class CreerFactureEvent extends FactureEvent {
  final Map<String, dynamic> data;
  CreerFactureEvent(this.data);
}

class OuvrirDocumentEvent extends FactureEvent {
  final String documentId;
  OuvrirDocumentEvent(this.documentId);
}

class ResetFactureState extends FactureEvent {}

class MettreAJourFactureEvent extends FactureEvent {
  final String documentId;
  final double? avance;
  final String? statut;
  MettreAJourFactureEvent({
    required this.documentId,
    this.avance,
    this.statut,
  });
}
