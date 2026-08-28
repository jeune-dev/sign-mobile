import 'package:sign_application/features/facture/domain/entities/facture.dart';
import 'package:sign_application/core/models/document_cree.dart';

abstract class FactureState {}

class FactureInitial extends FactureState {}

class FactureLoading extends FactureState {}

class FacturesLoaded extends FactureState {
  final List<Facture> factures;
  final bool hasMore;
  final int totalPages;
  final int total;
  final int currentPage;

  FacturesLoaded({
    required this.factures,
    this.hasMore = true,
    this.totalPages = 1,
    this.total = 0,
    this.currentPage = 1,
  });
}

class FactureSuccess extends FactureState {
  final String message;

  /// Facture tout juste creee, quand l'operation en a produit une.
  /// Null pour une mise a jour ou un renvoi.
  final DocumentCree? documentCree;

  FactureSuccess({this.message = 'Opération réussie', this.documentCree});
}

class DocumentBytes extends FactureState {
  final List<int> bytes;
  final String titre;
  DocumentBytes(this.bytes, {this.titre = ''});
}

class FactureError extends FactureState {
  final String message;
  FactureError(this.message);
}

class FactureMiseAJourSuccess extends FactureState {
  final Map<String, dynamic> data;
  FactureMiseAJourSuccess(this.data);
}

class FactureRenvoyeeSuccess extends FactureState {}

class FactureRenvoyeeLoading extends FactureState {}
