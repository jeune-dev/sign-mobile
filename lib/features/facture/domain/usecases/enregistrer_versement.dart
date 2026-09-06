import 'package:dartz/dartz.dart';
import 'package:sign_application/core/errors/failure.dart';
import '../repositories/facture_repository.dart';

/// Encaisser un règlement sur une facture.
///
/// `montant` est le montant que l'on vient de recevoir, jamais le cumul : le
/// backend émet une facture de plus, qui rappelle les versements précédents et
/// le solde restant, et l'envoie aux deux parties.
class EnregistrerVersement {
  final FactureRepository repository;
  EnregistrerVersement(this.repository);

  Future<Either<Failure, Map<String, dynamic>>> call({
    required String documentId,
    required double montant,
    String? moyenPaiement,
  }) {
    return repository.enregistrerVersement(
      documentId: documentId,
      montant: montant,
      moyenPaiement: moyenPaiement,
    );
  }
}
