import 'package:flutter/material.dart';

import '../theme/app_color.dart';

/// barre_filtre_direction.dart — « Tous / Envoyés / Reçus », avec compteurs.
///
/// Les documents reçus et émis vivent dans la même liste. Sans cette barre,
/// rien ne les distingue : un contrat reçu se noie parmi ceux qu'on a soi-même
/// créés, et rien n'indique qu'il en est arrivé un.
///
/// Les compteurs portent toujours sur l'ensemble, jamais sur la sélection
/// courante — c'est ce qui permet de voir qu'il y a quelque chose à consulter
/// dans un onglet où l'on ne se trouve pas.
///
/// Les libellés sont paramétrables pour suivre le genre du document : « Toutes
/// / Envoyées / Reçues » pour des factures, au masculin pour des contrats.
class BarreFiltreDirection extends StatelessWidget {
  /// Valeur courante : `tous`, `envoyes` ou `recus`.
  final String valeur;

  final ValueChanged<String> onChange;

  /// Nombre total de documents, toutes directions confondues.
  final int total;

  /// Nombre de documents émis, puis reçus.
  final int envoyes;
  final int recus;

  final String libelleTous;
  final String libelleEnvoyes;
  final String libelleRecus;

  const BarreFiltreDirection({
    super.key,
    required this.valeur,
    required this.onChange,
    required this.total,
    required this.envoyes,
    required this.recus,
    this.libelleTous = 'Tous',
    this.libelleEnvoyes = 'Envoyés',
    this.libelleRecus = 'Reçus',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(children: [
        _puce(libelleTous, 'tous', total),
        const SizedBox(width: 8),
        _puce(libelleEnvoyes, 'envoyes', envoyes),
        const SizedBox(width: 8),
        _puce(libelleRecus, 'recus', recus),
      ]),
    );
  }

  Widget _puce(String libelle, String cle, int nombre) {
    final choisie = valeur == cle;
    return Expanded(
      child: GestureDetector(
        onTap: () => onChange(cle),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: choisie ? AppColor.kTexte : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: choisie ? AppColor.kTexte : AppColor.kBordure),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  libelle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: choisie ? Colors.white : AppColor.kTexteFort,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: choisie
                      ? Colors.white.withValues(alpha: 0.22)
                      : AppColor.kNeutreClair,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$nombre',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: choisie ? Colors.white : AppColor.kTexteMoyen,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
