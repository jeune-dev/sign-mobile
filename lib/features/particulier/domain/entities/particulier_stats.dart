import 'package:equatable/equatable.dart';

class ParticulierStats extends Equatable {
  final int facturesTotal;
  final int facturesSignees;
  final int facturesEnAttente;
  final int contratsTotal;
  final int contratsSignes;
  final int contratsEnAttente;
  final Map<String, ContratTypeStats> parType;

  const ParticulierStats({
    required this.facturesTotal,
    required this.facturesSignees,
    required this.facturesEnAttente,
    required this.contratsTotal,
    required this.contratsSignes,
    required this.contratsEnAttente,
    required this.parType,
  });

  @override
  List<Object?> get props => [
        facturesTotal,
        facturesSignees,
        facturesEnAttente,
        contratsTotal,
        contratsSignes,
        contratsEnAttente,
        parType,
      ];
}

class ContratTypeStats extends Equatable {
  final int total;
  final int signes;
  final int enAttente;

  const ContratTypeStats({
    required this.total,
    required this.signes,
    required this.enAttente,
  });

  @override
  List<Object?> get props => [total, signes, enAttente];
}
