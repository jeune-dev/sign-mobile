abstract class ContratTravailEvent {}

class LoadContratsTravail extends ContratTravailEvent {
  final int page;
  final int limit;
  LoadContratsTravail({this.page = 1, this.limit = 10});
}

class LoadMoreContratsTravail extends ContratTravailEvent {}

class LoadContratTravailDetail extends ContratTravailEvent {
  final String contratId;
  LoadContratTravailDetail(this.contratId);
}

class CreerContratTravailEvent extends ContratTravailEvent {
  final Map<String, dynamic> data;
  CreerContratTravailEvent(this.data);
}

class SignerContratTravailEvent extends ContratTravailEvent {
  final String contratId;
  final String signature;
  SignerContratTravailEvent({required this.contratId, required this.signature});
}

class TelechargerContratTravailEvent extends ContratTravailEvent {
  final String contratId;
  final String titre;
  TelechargerContratTravailEvent(this.contratId, {this.titre = ''});
}

class ResetContratTravailState extends ContratTravailEvent {}

class LoadStatsTravail extends ContratTravailEvent {}
