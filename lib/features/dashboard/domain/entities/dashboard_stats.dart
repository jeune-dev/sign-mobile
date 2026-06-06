import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int nombreFactures;
  final int nombreContratsImmobilier;
  final int nombreContratsTravail;

  const DashboardStats({
    required this.nombreFactures,
    required this.nombreContratsImmobilier,
    required this.nombreContratsTravail,
  });

  @override
  List<Object?> get props => [nombreFactures, nombreContratsImmobilier, nombreContratsTravail];
}
