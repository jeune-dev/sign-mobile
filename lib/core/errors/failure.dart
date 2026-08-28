abstract class Failure {
  final String errorMessage;
  const Failure({required this.errorMessage});

  @override
  String toString() => '$runtimeType(errorMessage: $errorMessage)';

  @override
  int get hashCode => Object.hash(runtimeType, errorMessage);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other.runtimeType == runtimeType &&
          other is Failure &&
          other.errorMessage == errorMessage;
}

class ServerFailure extends Failure {
  const ServerFailure({required super.errorMessage});
}

class CacheFailure extends Failure {
  const CacheFailure({required super.errorMessage});
}

/// Le compte visé date d'avant la refonte du parcours : il possède un mot de
/// passe, et le backend l'exige pour ouvrir la session. L'écran de connexion
/// s'en sert pour afficher le champ « mot de passe » au lieu d'un message
/// d'échec — les comptes créés depuis la refonte n'en ont pas.
class MotDePasseRequisFailure extends Failure {
  const MotDePasseRequisFailure({required super.errorMessage});
}

/// L'adresse e-mail du compte n'a pas encore été confirmée. L'écran de
/// connexion renvoie alors vers la saisie du code plutôt que d'afficher un
/// échec, que l'utilisateur ne saurait pas quoi corriger.
class VerificationEmailRequiseFailure extends Failure {
  final String email;
  const VerificationEmailRequiseFailure({
    required super.errorMessage,
    required this.email,
  });
}
