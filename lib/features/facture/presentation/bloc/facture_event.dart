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

/// Facture pour un client NON inscrit — infos client saisies manuellement
/// (voir `data['client']`) au lieu d'un `clientId`.
class CreerFactureClientManuelEvent extends FactureEvent {
  final Map<String, dynamic> data;
  CreerFactureClientManuelEvent(this.data);
}

class OuvrirDocumentEvent extends FactureEvent {
  final String documentId;
  final String titre;
  OuvrirDocumentEvent(this.documentId, {this.titre = ''});
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

class RenvoyerFactureEvent extends FactureEvent {
  final String documentId;
  RenvoyerFactureEvent(this.documentId);
}
