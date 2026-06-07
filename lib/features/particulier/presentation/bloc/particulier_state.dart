import 'package:equatable/equatable.dart';
import '../../domain/entities/particulier_facture.dart';
import '../../domain/entities/particulier_contrat.dart';

abstract class ParticulierState extends Equatable {
  const ParticulierState();
  @override
  List<Object?> get props => [];
}

class ParticulierInitial extends ParticulierState {}

class ParticulierLoading extends ParticulierState {}

// ── Dashboard ───────────────────────────────────────────────────
class DashboardLoaded extends ParticulierState {
  final Map<String, dynamic> stats;
  final List<ParticulierFacture> recentesFactures;
  const DashboardLoaded({required this.stats, required this.recentesFactures});
  @override
  List<Object?> get props => [stats, recentesFactures];
}

// ── Factures ────────────────────────────────────────────────────
class FacturesLoaded extends ParticulierState {
  final List<ParticulierFacture> factures;
  final String? statut;
  const FacturesLoaded({required this.factures, this.statut});
  @override
  List<Object?> get props => [factures, statut];
}

// ── Contrats ────────────────────────────────────────────────────
class ContratsLoaded extends ParticulierState {
  final List<ParticulierContrat> contrats;
  final String? type;
  final String? statut;
  const ContratsLoaded({required this.contrats, this.type, this.statut});
  @override
  List<Object?> get props => [contrats, type, statut];
}

class ContratDetailLoaded extends ParticulierState {
  final ParticulierContrat contrat;
  const ContratDetailLoaded({required this.contrat});
  @override
  List<Object?> get props => [contrat];
}

// ── Signature ───────────────────────────────────────────────────
class ContratSigne extends ParticulierState {
  const ContratSigne();
}

class ContratSignatureEnCours extends ParticulierState {
  const ContratSignatureEnCours();
}

// ── Erreur ──────────────────────────────────────────────────────
class ParticulierError extends ParticulierState {
  final String message;
  const ParticulierError(this.message);
  @override
  List<Object?> get props => [message];
}
