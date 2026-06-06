abstract class ContratEvent {}

class LoadContratsImmobilier extends ContratEvent {
  final int page;
  final int limit;
  LoadContratsImmobilier({this.page = 1, this.limit = 10});
}

class LoadMoreContratsImmobilier extends ContratEvent {}

class CreerContratBailEvent extends ContratEvent {
  final Map<String, dynamic> data;
  CreerContratBailEvent(this.data);
}

class TelechargerContratEvent extends ContratEvent {
  final String contratId;
  TelechargerContratEvent(this.contratId);
}

class ResetContratState extends ContratEvent {}
