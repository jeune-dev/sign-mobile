import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/autres_contrats/presentation/bloc/autres_contrats_bloc.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_caution_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_confidentialite_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_location_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_partenariat_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_prestation_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_procuration_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_reconnaissance_dette_page.dart';
import 'package:sign_application/features/contrat/presentation/pages/creation_contrat_bail_page.dart';
import 'package:sign_application/features/contrat_travail/presentation/pages/creation_contrat_travail_page.dart';

// ─── Modèle de type de contrat ───────────────────────────────────────────────

class ContratTypeItem {
  final String id;
  final String titre;
  final String description;
  final IconData icon;
  final Color color;
  const ContratTypeItem({
    required this.id,
    required this.titre,
    required this.description,
    required this.icon,
    required this.color,
  });
}

final List<ContratTypeItem> allContractTypes = [
  const ContratTypeItem(id: 'bail',     titre: 'Contrat de bail',           description: 'Location immobilière',           icon: Icons.home_work_outlined,        color: Color(0xFF2563EB)),
  const ContratTypeItem(id: 'travail',  titre: 'Contrat de travail',         description: 'CDI, CDD, Stage, Freelance',     icon: Icons.work_outline_rounded,      color: Color(0xFF4F46E5)),
  ContratTypeItem(id: ContratType.prestation.apiValue,         titre: 'Contrat de prestation',      description: 'Mission de service',             icon: Icons.handshake_outlined,        color: const Color(0xFF2563EB)),
  ContratTypeItem(id: ContratType.partenariat.apiValue,        titre: 'Contrat de partenariat',     description: 'Accord de collaboration',        icon: Icons.people_outline_rounded,    color: const Color(0xFF4F46E5)),
  ContratTypeItem(id: ContratType.location.apiValue,           titre: 'Contrat de location',        description: 'Location de véhicule/matériel',  icon: Icons.directions_car_outlined,   color: const Color(0xFF2563EB)),
  ContratTypeItem(id: ContratType.caution.apiValue,            titre: 'Contrat de caution',         description: 'Garantie de paiement',           icon: Icons.shield_outlined,           color: const Color(0xFF4F46E5)),
  ContratTypeItem(id: ContratType.confidentialite.apiValue,    titre: 'Accord de confidentialité',  description: 'Protection des informations',    icon: Icons.lock_outline_rounded,      color: const Color(0xFF2563EB)),
  ContratTypeItem(id: ContratType.procuration.apiValue,        titre: 'Procuration',                description: 'Délégation de pouvoirs',         icon: Icons.assignment_ind_outlined,   color: const Color(0xFF4F46E5)),
  ContratTypeItem(id: ContratType.reconnaissanceDette.apiValue,titre: 'Reconnaissance de dette',    description: 'Engagement de remboursement',    icon: Icons.account_balance_outlined,  color: const Color(0xFF2563EB)),
];

// ─── Fonction de navigation vers la page de création ─────────────────────────

Future<void> navigateToContractCreation(
  BuildContext context,
  ContratTypeItem type, {
  User? user,
}) async {
  Widget? page;
  if (type.id == 'bail') {
    page = CreationContratPage(user: user);
  } else if (type.id == 'travail') {
    page = const CreationContratTravailPage();
  } else if (type.id == ContratType.prestation.apiValue) {
    page = const CreationContratPrestationPage();
  } else if (type.id == ContratType.partenariat.apiValue) {
    page = const CreationContratPartenariatPage();
  } else if (type.id == ContratType.location.apiValue) {
    page = const CreationContratLocationPage();
  } else if (type.id == ContratType.caution.apiValue) {
    page = const CreationContratCautionPage();
  } else if (type.id == ContratType.confidentialite.apiValue) {
    page = const CreationContratConfidentialitePage();
  } else if (type.id == ContratType.procuration.apiValue) {
    page = const CreationProcurationPage();
  } else if (type.id == ContratType.reconnaissanceDette.apiValue) {
    page = const CreationReconnaissanceDettePage();
  }

  if (page != null && context.mounted) {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider.value(
          value: context.read<AutresContratsBloc>(),
          child: page!,
        ),
      ),
    );
  }
}

// ─── Modal public de sélection du type de contrat ────────────────────────────

void showContractTypeModal(BuildContext context, {User? user}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (modalCtx) => BlocProvider.value(
      value: context.read<AutresContratsBloc>(),
      child: ContractTypeModalSheet(
        onTypeSelected: (type) async {
          Navigator.pop(modalCtx);
          await navigateToContractCreation(context, type, user: user);
        },
      ),
    ),
  );
}

// ─── Widget du bottom sheet ───────────────────────────────────────────────────

class ContractTypeModalSheet extends StatelessWidget {
  final void Function(ContratTypeItem) onTypeSelected;
  const ContractTypeModalSheet({super.key, required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40, height: 4,
            decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
          ),
          // ── Titre ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nouveau contrat',
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                    SizedBox(height: 2),
                    Text('Choisissez le type',
                        style: TextStyle(fontSize: 13, color: Colors.grey)),
                  ],
                ),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle),
                    child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // ── Liste des types ───────────────────────────────────────────────
          ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.65,
            ),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: allContractTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final type = allContractTypes[index];
                return GestureDetector(
                  onTap: () => onTypeSelected(type),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: type.color.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: type.color.withValues(alpha: 0.2)),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 48, height: 48,
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(type.icon, color: type.color, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(type.titre,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                              const SizedBox(height: 3),
                              Text(type.description,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                            ],
                          ),
                        ),
                        Container(
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: type.color.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.arrow_forward_rounded, color: type.color, size: 16),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
