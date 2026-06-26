abstract class EtatLogementEvent {}

class LoadEtatsLogement extends EtatLogementEvent {}

class LoadEtatLogementDetail extends EtatLogementEvent {
  final String etatId;
  LoadEtatLogementDetail(this.etatId);
}

class CreerEtatLogementEvent extends EtatLogementEvent {
  final String contratId;
  final Map<String, dynamic> data;
  CreerEtatLogementEvent({required this.contratId, required this.data});
}

class SignerEtatLogementEvent extends EtatLogementEvent {
  final String etatId;
  final String signature;
  SignerEtatLogementEvent({required this.etatId, required this.signature});
}

class TelechargerEtatLogementEvent extends EtatLogementEvent {
  final String etatId;
  final String titre;
  TelechargerEtatLogementEvent(this.etatId, {this.titre = ''});
}

class ResetEtatLogementState extends EtatLogementEvent {}
