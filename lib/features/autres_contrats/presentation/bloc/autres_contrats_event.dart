abstract class AutresContratsEvent {}

class LoadContrats extends AutresContratsEvent {
  final String type;
  LoadContrats(this.type);
}

class LoadDetail extends AutresContratsEvent {
  final String type;
  final String id;
  LoadDetail(this.type, this.id);
}

class CreerContrat extends AutresContratsEvent {
  final String type;
  final Map<String, dynamic> body;
  CreerContrat(this.type, this.body);
}

class SignerContrat extends AutresContratsEvent {
  final String type;
  final String id;
  final String signature;
  SignerContrat(this.type, this.id, this.signature);
}

class TelechargerContrat extends AutresContratsEvent {
  final String type;
  final String id;
  TelechargerContrat(this.type, this.id);
}

class ResetState extends AutresContratsEvent {}
