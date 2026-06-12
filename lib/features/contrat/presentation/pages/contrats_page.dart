import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/config/contrat_type.dart';
import 'package:sign_application/core/config/env.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/autres_contrats/presentation/bloc/autres_contrats_bloc.dart';
import 'package:sign_application/features/autres_contrats/presentation/bloc/autres_contrats_event.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/autres_contrats_liste_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_caution_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_confidentialite_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_location_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_partenariat_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_contrat_prestation_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_procuration_page.dart';
import 'package:sign_application/features/autres_contrats/presentation/pages/creation_reconnaissance_dette_page.dart';
import 'package:sign_application/features/contrat/presentation/pages/creation_contrat_bail_page.dart';
import 'package:sign_application/features/contrat/presentation/pages/contrat_bail_liste_page.dart';
import 'package:sign_application/features/contrat_travail/presentation/bloc/contrat_travail_bloc.dart';
import 'package:sign_application/features/contrat_travail/presentation/bloc/contrat_travail_event.dart' show LoadContratsTravail;
import 'package:sign_application/features/contrat_travail/presentation/pages/contrats_travail_liste_page.dart';
import 'package:sign_application/features/contrat_travail/presentation/pages/creation_contrat_travail_page.dart';
import 'package:sign_application/injection_container.dart' as di;
import 'package:sign_application/features/particulier/presentation/pages/contrats_a_signer_page.dart';
import 'package:sign_application/features/particulier/presentation/bloc/particulier_bloc.dart';

class _Stats {
  final int total;
  final int signes;
  final int enAttente;
  const _Stats({this.total = 0, this.signes = 0, this.enAttente = 0});
}

class _ContratType {
  final String id;
  final String titre;
  final String shortLabel;
  final String description;
  final IconData icon;
  final Color color;
  const _ContratType({
    required this.id,
    required this.titre,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.color,
  });
}

List<_ContratType> get _allContractTypes => [
  const _ContratType(id: 'bail',    titre: 'Contrat de bail',            shortLabel: 'Bail',        description: 'Location immobilière',           icon: Icons.home_work_outlined,        color: Color(0xFF2563EB)),
  const _ContratType(id: 'travail', titre: 'Contrat de travail',          shortLabel: 'Travail',     description: 'CDI, CDD, Stage, Freelance',     icon: Icons.work_outline_rounded,      color: Color(0xFF4F46E5)),
  _ContratType(id: ContratType.prestation.apiValue,         titre: 'Contrat de prestation',      shortLabel: 'Prestation',      description: 'Mission de service',             icon: Icons.handshake_outlined,        color: const Color(0xFF2563EB)),
  _ContratType(id: ContratType.partenariat.apiValue,        titre: 'Contrat de partenariat',     shortLabel: 'Partenariat',     description: 'Accord de collaboration',        icon: Icons.people_outline_rounded,    color: const Color(0xFF4F46E5)),
  _ContratType(id: ContratType.location.apiValue,           titre: 'Contrat de location',        shortLabel: 'Location',        description: 'Location de véhicule/matériel',  icon: Icons.directions_car_outlined,   color: const Color(0xFF2563EB)),
  _ContratType(id: ContratType.caution.apiValue,            titre: 'Contrat de caution',         shortLabel: 'Caution',         description: 'Garantie de paiement',           icon: Icons.shield_outlined,           color: const Color(0xFF4F46E5)),
  _ContratType(id: ContratType.confidentialite.apiValue,    titre: 'Contrat de Confidentialité', shortLabel: 'Confidentialité', description: 'Protection des informations',    icon: Icons.lock_outline_rounded,      color: const Color(0xFF2563EB)),
  _ContratType(id: ContratType.procuration.apiValue,        titre: 'Procuration',                shortLabel: 'Procuration',     description: 'Délégation de pouvoirs',         icon: Icons.assignment_ind_outlined,   color: const Color(0xFF4F46E5)),
  _ContratType(id: ContratType.reconnaissanceDette.apiValue,titre: 'Reconnaissance de dette',    shortLabel: 'Dette',           description: 'Engagement de remboursement',    icon: Icons.account_balance_outlined,  color: const Color(0xFF2563EB)),
];

class ContratsPage extends StatefulWidget {
  final User? user;
  const ContratsPage({super.key, this.user});

  @override
  State<ContratsPage> createState() => _ContratsPageState();
}

class _ContratsPageState extends State<ContratsPage> {
  final Map<String, _Stats> _stats = {};
  bool _statsLoading  = true;

  @override
  void initState() {
    super.initState();
    _loadAllStats();
  }

  Future<void> _loadAllStats() async {
    setState(() => _statsLoading = true);
    try {
      final dio = di.sl<Dio>();
      final requests = <MapEntry<String, String>>[
        MapEntry('bail',    Env.contratBailStats),
        MapEntry('travail', Env.contratTravailStats),
        ..._allContractTypes
            .where((t) => t.id != 'bail' && t.id != 'travail')
            .map((t) => MapEntry(t.id, Env.autresContratsStats(t.id))),
      ];

      final results = await Future.wait(requests.map((e) async {
        try {
          final resp = await dio.get(e.value);
          final data = resp.data['data'] as Map<String, dynamic>? ?? {};
          return MapEntry(e.key, _Stats(
            total:     (data['total']     as num?)?.toInt() ?? 0,
            signes:    (data['signes']    as num?)?.toInt() ?? 0,
            enAttente: (data['enAttente'] as num?)?.toInt() ?? 0,
          ));
        } catch (_) {
          return MapEntry(e.key, const _Stats());
        }
      }));

      if (!mounted) return;
      setState(() {
        _stats..clear()..addEntries(results);
        _statsLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statsLoading = false);
    }
  }

  int get _totalAll     => _stats.values.fold(0, (s, e) => s + e.total);
  int get _totalSignes  => _stats.values.fold(0, (s, e) => s + e.signes);
  int get _totalWaiting => _stats.values.fold(0, (s, e) => s + e.enAttente);

  Future<void> _navigateToCreation(_ContratType type) async {
    Navigator.pop(context);
    Widget? page;
    switch (type.id) {
      case 'bail':                      page = CreationContratPage(user: widget.user); break;
      case 'travail':                   page = const CreationContratTravailPage(); break;
      default:
        if (type.id == ContratType.prestation.apiValue)         page = const CreationContratPrestationPage();
        else if (type.id == ContratType.partenariat.apiValue)   page = const CreationContratPartenariatPage();
        else if (type.id == ContratType.location.apiValue)      page = const CreationContratLocationPage();
        else if (type.id == ContratType.caution.apiValue)       page = const CreationContratCautionPage();
        else if (type.id == ContratType.confidentialite.apiValue) page = const CreationContratConfidentialitePage();
        else if (type.id == ContratType.procuration.apiValue)   page = const CreationProcurationPage();
        else if (type.id == ContratType.reconnaissanceDette.apiValue) page = const CreationReconnaissanceDettePage();
    }
    if (page != null) {
      await Navigator.push(context, MaterialPageRoute(
        builder: (_) => BlocProvider.value(value: context.read<AutresContratsBloc>(), child: page!),
      ));
      if (mounted) _loadAllStats();
    }
  }

  void _navigateToListe(_ContratType type) {
    Widget page;
    if (type.id == 'bail') {
      page = const ContratBailListePage();
    } else if (type.id == 'travail') {
      page = BlocProvider.value(
        value: context.read<ContratTravailBloc>()..add(LoadContratsTravail()),
        child: const ContratsTravailListePage(),
      );
    } else {
      page = BlocProvider.value(
        value: context.read<AutresContratsBloc>()..add(LoadContrats(type.id)),
        child: AutresContratsListePage(
          type: type.id, titre: type.titre,
          createPageBuilder: (_) => BlocProvider.value(
            value: context.read<AutresContratsBloc>(),
            child: _getCreationPage(type.id),
          ),
        ),
      );
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => page))
        .then((_) => _loadAllStats());
  }

  Widget _getCreationPage(String id) {
    if (id == ContratType.prestation.apiValue)          return const CreationContratPrestationPage();
    if (id == ContratType.partenariat.apiValue)         return const CreationContratPartenariatPage();
    if (id == ContratType.location.apiValue)            return const CreationContratLocationPage();
    if (id == ContratType.caution.apiValue)             return const CreationContratCautionPage();
    if (id == ContratType.confidentialite.apiValue)     return const CreationContratConfidentialitePage();
    if (id == ContratType.procuration.apiValue)         return const CreationProcurationPage();
    if (id == ContratType.reconnaissanceDette.apiValue) return const CreationReconnaissanceDettePage();
    return const SizedBox.shrink();
  }

  void _showContractTypeModal() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ContractTypeModal(onTypeSelected: _navigateToCreation),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      color: Colors.black87,
      onRefresh: _loadAllStats,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(child: _buildHeader()),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: ElevatedButton.icon(
                onPressed: _showContractTypeModal,
                icon: const Icon(Icons.add_rounded, size: 20),
                label: const Text('Nouveau contrat', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.black, foregroundColor: Colors.white,
                  elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => di.sl<ParticulierBloc>(),
                      child: const ContratsASignerPage(),
                    ),
                  ));
                },
                icon: const Icon(Icons.draw_outlined, size: 20, color: Colors.black87),
                label: const Text('Mes contrats à signer', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.black87, width: 1.5),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: Row(
                children: [
                  const Text('Mes contrats', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.black87)),
                  const Spacer(),
                  if (_statsLoading)
                    const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.black54, strokeWidth: 2))
                  else
                    GestureDetector(
                      onTap: _loadAllStats,
                      child: Row(
                        children: [
                          Icon(Icons.refresh_rounded, size: 14, color: Colors.grey[500]),
                          const SizedBox(width: 4),
                          Text('Actualiser', style: TextStyle(fontSize: 11, color: Colors.grey[500], fontWeight: FontWeight.w600)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.92,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, i) => _buildCard(_allContractTypes[i], _stats[_allContractTypes[i].id] ?? const _Stats()),
                childCount: _allContractTypes.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)], begin: Alignment.topLeft, end: Alignment.bottomRight),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.18), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.12), borderRadius: BorderRadius.circular(8)),
                        child: const Text('📋  Mes contrats', style: TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                      const SizedBox(height: 12),
                      _statsLoading
                          ? Container(width: 60, height: 44, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)))
                          : Text('$_totalAll', style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, letterSpacing: -2, height: 1)),
                      const SizedBox(height: 4),
                      Text('Sur 9 types de contrats', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 11)),
                    ],
                  ),
                ),
                Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.08), borderRadius: BorderRadius.circular(18)),
                  child: const Icon(Icons.description_rounded, color: Colors.white38, size: 32),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _miniStatCard('Signés', '$_totalSignes', Colors.black87, Icons.check_circle_outline_rounded)),
              const SizedBox(width: 12),
              Expanded(child: _miniStatCard('En attente', '$_totalWaiting', Colors.grey[600]!, Icons.hourglass_bottom_rounded)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStatCard(String title, String value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey[100]!),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Row(
        children: [
          Container(width: 36, height: 36, decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(icon, color: color, size: 18)),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.black87, height: 1)),
              Text(title, style: TextStyle(fontSize: 11, color: Colors.grey[500])),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCard(_ContratType type, _Stats stats) {
    return GestureDetector(
      onTap: () => _navigateToListe(type),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey[100]!),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.grey[50],
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40, height: 40,
                    decoration: BoxDecoration(color: Colors.black, borderRadius: BorderRadius.circular(12)),
                    child: Icon(type.icon, color: Colors.white, size: 22),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(_statsLoading ? '…' : '${stats.total}', style: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w800, fontSize: 13)),
                  ),
                ],
              ),
            ),
            // Body
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(type.shortLabel, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13, color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(type.description, style: TextStyle(fontSize: 10, color: Colors.grey[500]), maxLines: 2, overflow: TextOverflow.ellipsis),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: _chip(Icons.check_circle_outline_rounded, _statsLoading ? '…' : '${stats.signes}', const Color(0xFF00C896), 'Signés')),
                        const SizedBox(width: 6),
                        Expanded(child: _chip(Icons.hourglass_bottom_rounded, _statsLoading ? '…' : '${stats.enAttente}', const Color(0xFFFFB347), 'Attente')),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icon, String value, Color color, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(color: color.withOpacity(0.08), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.2))),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 11),
          const SizedBox(width: 3),
          Text(value, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 11)),
          const SizedBox(width: 3),
          Flexible(child: Text(label, style: TextStyle(color: color.withOpacity(0.7), fontSize: 9), maxLines: 1, overflow: TextOverflow.clip)),
        ],
      ),
    );
  }
}

// ── Modal ─────────────────────────────────────────────────────────────────────
class _ContractTypeModal extends StatelessWidget {
  final void Function(_ContratType) onTypeSelected;
  const _ContractTypeModal({required this.onTypeSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Nouveau contrat', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Colors.black87)),
                  SizedBox(height: 2),
                  Text('Choisissez le type', style: TextStyle(fontSize: 13, color: Colors.grey)),
                ]),
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(width: 36, height: 36, decoration: BoxDecoration(color: Colors.grey[100], shape: BoxShape.circle), child: const Icon(Icons.close_rounded, size: 18, color: Colors.black54)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.65),
            child: ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.all(16),
              itemCount: _allContractTypes.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final type = _allContractTypes[index];
                return GestureDetector(
                  onTap: () => onTypeSelected(type),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(color: type.color.withOpacity(0.04), borderRadius: BorderRadius.circular(16), border: Border.all(color: type.color.withOpacity(0.2))),
                    child: Row(
                      children: [
                        Container(width: 48, height: 48, decoration: BoxDecoration(color: type.color.withOpacity(0.12), borderRadius: BorderRadius.circular(14)), child: Icon(type.icon, color: type.color, size: 24)),
                        const SizedBox(width: 14),
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(type.titre, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: Colors.black87)),
                          const SizedBox(height: 3),
                          Text(type.description, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                        ])),
                        Container(width: 32, height: 32, decoration: BoxDecoration(color: type.color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)), child: Icon(Icons.arrow_forward_rounded, color: type.color, size: 16)),
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
