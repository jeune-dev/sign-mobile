import 'package:equatable/equatable.dart';

class DashboardStats extends Equatable {
  final int nombreFactures;
  final int nombreContratsImmobilier;
  final int nombreContratsTravail;
  final double creancesClients; // ← KPI : somme restant à payer (avance partielle)

  const DashboardStats({
    required this.nombreFactures,
    required this.nombreContratsImmobilier,
    required this.nombreContratsTravail,
    this.creancesClients = 0.0,
  });

  @override
  List<Object?> get props => [
    nombreFactures,
    nombreContratsImmobilier,
    nombreContratsTravail,
    creancesClients,
  ];
}
