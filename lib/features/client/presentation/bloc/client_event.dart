abstract class ClientEvent {}

class LoadClients extends ClientEvent {}

class RechercherClientsEvent extends ClientEvent {
  final String query;
  RechercherClientsEvent(this.query);
}

class AjouterClientEvent extends ClientEvent {
  final String nom;
  final String prenom;
  final String email;
  final String motDePasse;
  final String? telephone;
  final String? adresse;
  final String? carteIdentiteNationalNum;

  AjouterClientEvent({
    required this.nom,
    required this.prenom,
    required this.email,
    required this.motDePasse,
    this.telephone,
    this.adresse,
    this.carteIdentiteNationalNum,
  });
}

class ResetClientState extends ClientEvent {}
