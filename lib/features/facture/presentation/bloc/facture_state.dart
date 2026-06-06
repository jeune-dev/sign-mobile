import 'package:sign_application/features/facture/domain/entities/facture.dart';

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
  FactureSuccess({this.message = 'Opération réussie'});
}

class DocumentBytes extends FactureState {
  final List<int> bytes;
  DocumentBytes(this.bytes);
}

class FactureError extends FactureState {
  final String message;
  FactureError(this.message);
}
