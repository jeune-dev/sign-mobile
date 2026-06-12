import 'package:equatable/equatable.dart';

abstract class ParticulierEvent extends Equatable {
  const ParticulierEvent();
  @override
  List<Object?> get props => [];
}

class LoadDashboardStats extends ParticulierEvent {
  const LoadDashboardStats();
}

class LoadFactures extends ParticulierEvent {
  final String? statut; // null = toutes, 'signe', 'en_attente'
  const LoadFactures({this.statut});
  @override
  List<Object?> get props => [statut];
}

class LoadContrats extends ParticulierEvent {
  final String? type;   // null = tous les types
  final String? statut;
  const LoadContrats({this.type, this.statut});
  @override
  List<Object?> get props => [type, statut];
}

class LoadContratDetail extends ParticulierEvent {
  final String type;
  final String contratId;
  const LoadContratDetail({required this.type, required this.contratId});
  @override
  List<Object?> get props => [type, contratId];
}

class SignerContrat extends ParticulierEvent {
  final String type;
  final String contratId;
  final String signature;
  const SignerContrat({required this.type, required this.contratId, required this.signature});
  @override
  List<Object?> get props => [type, contratId];
}

class DownloadContratPdf extends ParticulierEvent {
  final String type;
  final String contratId;
  const DownloadContratPdf({required this.type, required this.contratId});
  @override
  List<Object?> get props => [type, contratId];
}
