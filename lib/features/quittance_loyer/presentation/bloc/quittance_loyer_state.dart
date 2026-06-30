import 'package:sign_application/features/quittance_loyer/domain/entities/quittance_loyer.dart';

abstract class QuittanceLoyerState {}

class QuittanceLoyerInitial extends QuittanceLoyerState {}

class QuittanceLoyerLoading extends QuittanceLoyerState {}

class QuittancesLoaded extends QuittanceLoyerState {
  final List<QuittanceLoyer> quittances;
  final bool hasMore;
  QuittancesLoaded({required this.quittances, this.hasMore = true});
}

class QuittanceDetailLoaded extends QuittanceLoyerState {
  final QuittanceLoyer quittance;
  QuittanceDetailLoaded(this.quittance);
}

class QuittanceLoyerSuccess extends QuittanceLoyerState {
  final String message;
  QuittanceLoyerSuccess({this.message = 'Opération réussie'});
}

class QuittanceBytes extends QuittanceLoyerState {
  final List<int> bytes;
  final String quittanceId;
  final String mode; // 'view' | 'download'
  QuittanceBytes({required this.bytes, required this.quittanceId, this.mode = 'download'});
}

class QuittanceLoyerError extends QuittanceLoyerState {
  final String message;
  QuittanceLoyerError(this.message);
}
