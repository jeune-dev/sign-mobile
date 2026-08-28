import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:sign_application/features/parcours/presentation/parcours_document.dart';
import 'package:sign_application/features/parcours/type_document_signs.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:toastification/toastification.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import '../bloc/quittance_loyer_bloc.dart';
import '../bloc/quittance_loyer_event.dart';
import '../bloc/quittance_loyer_state.dart';
import '../../domain/entities/quittance_loyer.dart';
import 'creation_quittance_page.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/theme/app_color.dart';

class QuittancesListePage extends StatefulWidget {
  // false côté client (destinataire) : pas de création, lecture seule.
  final bool canCreate;
  const QuittancesListePage({super.key, this.canCreate = true});

  @override
  State<QuittancesListePage> createState() => _QuittancesListePageState();
}

class _QuittancesListePageState extends State<QuittancesListePage> {
  static final _montantFmt = NumberFormat('#,###', 'fr_FR');

  // Filtre actif : 'tous' | 'envoyes' | 'recus'
  String _filtre = 'tous';

  @override
  void initState() {
    super.initState();
    context.read<QuittanceLoyerBloc>().add(LoadQuittances());
  }

  // Ouvre dans le lecteur PDF (mode 'view') ou enregistre dans Téléchargements (mode 'download').
  Future<void> _handleBytes(QuittanceBytes state) async {
    final id = state.quittanceId.length >= 8 ? state.quittanceId.substring(0, 8) : state.quittanceId;
    final fileName = 'quittance_$id.pdf';
    try {
      if (state.mode == 'view') {
        final dir  = await getTemporaryDirectory();
        final file = File('${dir.path}/$fileName');
        await file.writeAsBytes(state.bytes, flush: true);
        if (!mounted) return;
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => PdfViewerPage(filePath: file.path, titre: 'Quittance')),
        );
      } else {
        final path = await savePdfToDownloads(Uint8List.fromList(state.bytes), fileName);
        if (!mounted) return;
        showDownloadSuccessSnackBar(context, fileName, path);
      }
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    }
  }

  List<QuittanceLoyer> _appliquerFiltre(List<QuittanceLoyer> all) {
    switch (_filtre) {
      case 'envoyes':
        return all.where((q) => !q.estRecue).toList();
      case 'recus':
        return all.where((q) => q.estRecue).toList();
      default:
        return all;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kFond,
      floatingActionButton: widget.canCreate
          ? FloatingActionButton.extended(
              backgroundColor: AppColor.kTexte,
              foregroundColor: Colors.white,
              elevation: 4,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Nouvelle', style: TextStyle(fontWeight: FontWeight.w700)),
              onPressed: () async {
                await ParcoursDocument.ouvrir(
                  context,
                  typeDocument: TypeDocumentSigns.quittanceLoyer,
                  page: (_) => const CreationQuittancePage(),
                );
                if (context.mounted) {
                  context.read<QuittanceLoyerBloc>().add(LoadQuittances());
                }
              },
            )
          : null,
      body: Column(
        children: [
          _buildTopBar(context),
          Expanded(
            child: BlocConsumer<QuittanceLoyerBloc, QuittanceLoyerState>(
              listener: (context, state) {
                if (state is QuittanceBytes) {
                  _handleBytes(state);
                }
                if (state is QuittanceLoyerError) {
                  showToast(context, 'Erreur', state.message, ToastificationType.error);
                }
              },
              builder: (context, state) {
                if (state is QuittanceLoyerLoading) {
                  return const ShimmerList(itemCount: 4, padding: EdgeInsets.fromLTRB(16, 16, 16, 100));
                }

                if (state is QuittancesLoaded) {
                  final all = state.quittances;
                  if (all.isEmpty) return _buildEmpty();
                  final quittances = _appliquerFiltre(all);
                  return Column(
                    children: [
                      _buildFilterBar(all),
                      Expanded(
                        child: RefreshIndicator(
                          color: Colors.black87,
                          onRefresh: () async => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
                          child: quittances.isEmpty
                              ? _buildEmptyFiltre()
                              : ListView.separated(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                                  itemCount: quittances.length,
                                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                                  itemBuilder: (context, index) => _QuittanceCard(
                                    quittance:  quittances[index],
                                    montantFmt: _montantFmt,
                                    onView:     () => context.read<QuittanceLoyerBloc>().add(TelechargerQuittanceEvent(quittances[index].id, mode: 'view')),
                                    onDownload: () => context.read<QuittanceLoyerBloc>().add(TelechargerQuittanceEvent(quittances[index].id, mode: 'download')),
                                  ),
                                ),
                        ),
                      ),
                    ],
                  );
                }

                if (state is QuittanceLoyerError) {
                  return _buildError(context, state.message);
                }

                return const Center(child: CircularProgressIndicator(color: Colors.black87, strokeWidth: 2.5));
              },
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre supérieure (même style que Fiches de paie) ──────────────────────────
  Widget _buildTopBar(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    return Container(
      decoration: const BoxDecoration(
        color: AppColor.kTexte,
        borderRadius: BorderRadius.only(
          bottomLeft:  Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: EdgeInsets.fromLTRB(20, topPad + 14, 20, 24),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
            ),
          ),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quittances de loyer',
                    style: TextStyle(
                        color: Colors.white, fontSize: 20,
                        fontWeight: FontWeight.w900, letterSpacing: -0.5)),
                SizedBox(height: 2),
                Text('Historique de vos quittances',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.home_work_outlined, color: Colors.white, size: 14),
              SizedBox(width: 5),
              Text('Loyer', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
            ]),
          ),
        ],
      ),
    );
  }

  // ── Barre de filtres Tous / Envoyées / Reçues ────────────────────────────────
  Widget _buildFilterBar(List<QuittanceLoyer> all) {
    final nbEnvoyes = all.where((q) => !q.estRecue).length;
    final nbRecus   = all.where((q) => q.estRecue).length;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 2),
      child: Row(children: [
        _filterChip('Tous', 'tous', all.length),
        const SizedBox(width: 8),
        _filterChip('Envoyées', 'envoyes', nbEnvoyes),
        const SizedBox(width: 8),
        _filterChip('Reçues', 'recus', nbRecus),
      ]),
    );
  }

  Widget _filterChip(String label, String value, int count) {
    final selected = _filtre == value;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _filtre = value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 9),
          decoration: BoxDecoration(
            color: selected ? AppColor.kTexte : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: selected ? AppColor.kTexte : AppColor.kBordure),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text(label, style: TextStyle(
              fontSize: 12.5, fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColor.kTexteFort,
            )),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
              decoration: BoxDecoration(
                color: selected ? Colors.white.withValues(alpha: 0.22) : AppColor.kNeutreClair,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$count', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w700,
                color: selected ? Colors.white : AppColor.kTexteMoyen,
              )),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _buildEmptyFiltre() => ListView(
    children: [
      const SizedBox(height: 80),
      Icon(_filtre == 'recus' ? Icons.inbox_outlined : Icons.outbox_outlined, size: 48, color: const Color(0xFFB0B0B0)),
      const SizedBox(height: 12),
      Center(child: Text(
        _filtre == 'recus' ? 'Aucune quittance reçue' : 'Aucune quittance envoyée',
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColor.kTexteMoyen),
      )),
    ],
  );

  Widget _buildEmpty() => const EmptyState(
    icon: Icons.receipt_long_outlined,
    title: 'Aucune quittance',
    subtitle: 'Vos quittances de loyer apparaîtront ici',
    scrollable: false,
  );

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64, height: 64,
              decoration: const BoxDecoration(color: AppColor.kNeutreClair, shape: BoxShape.circle),
              child: const Icon(Icons.error_outline_rounded, color: AppColor.kTexte, size: 32),
            ),
            const SizedBox(height: 16),
            Text('Impossible de charger', style: AppTypo.jakarta(fontWeight: FontWeight.w700, fontSize: 15, color: AppColor.kTexte)),
            const SizedBox(height: 6),
            Text(message, style: AppTypo.jakarta(color: AppColor.kTexteMoyen, fontSize: 13), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87, foregroundColor: Colors.white,
                elevation: 0, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 13),
              ),
              onPressed: () => context.read<QuittanceLoyerBloc>().add(LoadQuittances()),
              child: const Text('Réessayer', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Carte quittance ───────────────────────────────────────────────────────────
class _QuittanceCard extends StatelessWidget {
  final QuittanceLoyer quittance;
  final NumberFormat   montantFmt;
  final VoidCallback   onView;
  final VoidCallback   onDownload;

  const _QuittanceCard({required this.quittance, required this.montantFmt, required this.onView, required this.onDownload});

  // Statut de paiement — même logique visuelle que les factures.
  Color _statusColor() {
    if (quittance.estTotal == true) return Colors.green;
    if ((quittance.montantPayePartiel ?? 0) > 0) return Colors.orange;
    return Colors.red;
  }

  String _statusText() {
    if (quittance.estTotal == true) return 'Payée';
    if ((quittance.montantPayePartiel ?? 0) > 0) return 'Partiel';
    return 'En attente';
  }

  @override
  Widget build(BuildContext context) {
    final estRecue = quittance.estRecue;
    // Contrepartie : si reçue, on affiche le bailleur (expéditeur) ; sinon le locataire.
    final contrepartie = estRecue ? quittance.bailleur : quittance.locataire;
    final contrepartieNom = contrepartie != null
        ? '${contrepartie['prenom'] ?? ''} ${contrepartie['nom'] ?? ''}'.trim()
        : 'N/A';
    final locataireNom = '${estRecue ? 'De' : 'À'} : ${contrepartieNom.isEmpty ? 'N/A' : contrepartieNom}';
    final montant = quittance.montantTotal != null
        ? '${montantFmt.format(quittance.montantTotal!).replaceAll(',', ' ')} FCFA'
        : '—';

    final statusColor = _statusColor();
    final statusText  = _statusText();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: [
        Padding(
        padding: const EdgeInsets.all(16),
        child: Row(children: [
          // Icône
          Container(
            width: 46, height: 46,
            decoration: BoxDecoration(
              color: AppColor.kTexte,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.receipt_long_rounded, color: Colors.white, size: 22),
          ),
          const SizedBox(width: 14),

          // Infos
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(
                  child: Text(
                    quittance.numeroQuittance ?? 'Quittance #${quittance.id.substring(0, 8)}',
                    style: AppTypo.jakarta(fontWeight: FontWeight.w800, fontSize: 14, color: AppColor.kTexte),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: estRecue ? const Color(0xFFEAF2FF) : const Color(0xFFF0FAF2),
                    borderRadius: BorderRadius.circular(7),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(estRecue ? Icons.south_west_rounded : Icons.north_east_rounded,
                        size: 11, color: estRecue ? const Color(0xFF2563EB) : const Color(0xFF16A34A)),
                    const SizedBox(width: 3),
                    Text(estRecue ? 'Reçue' : 'Envoyée',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: estRecue ? const Color(0xFF2563EB) : const Color(0xFF16A34A))),
                  ]),
                ),
              ]),
              if (quittance.adresseLogement != null) ...[
                const SizedBox(height: 3),
                Text(quittance.adresseLogement!, style: AppTypo.jakarta(fontSize: 12, color: AppColor.kTexteMoyen), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
              const SizedBox(height: 6),
              Row(children: [
                if (quittance.mois != null && quittance.annee != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(color: AppColor.kNeutreClair, borderRadius: BorderRadius.circular(8)),
                    child: Text('${quittance.mois} ${quittance.annee}', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColor.kTexteFort)),
                  ),
                  const SizedBox(width: 8),
                ],
                Text(montant, style: AppTypo.jakarta(fontWeight: FontWeight.w700, fontSize: 13, color: AppColor.kTexte)),
              ]),
              const SizedBox(height: 4),
              Text(locataireNom, style: AppTypo.jakarta(fontSize: 11, color: AppColor.kTexteFaible)),
            ]),
          ),
          const SizedBox(width: 8),

          // Droite : statut de paiement
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20), border: Border.all(color: statusColor.withValues(alpha: 0.3))),
            child: Text(statusText, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
        ]),
        ),
        Divider(height: 1, color: Colors.grey[100]),
        // ── Actions : Voir + Télécharger ──────────────────────────────────
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            Expanded(child: _actionBtn('Voir', Icons.visibility_outlined, onView, filled: false)),
            const SizedBox(width: 10),
            Expanded(child: _actionBtn('Télécharger', Icons.download_rounded, onDownload, filled: true)),
          ]),
        ),
      ]),
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap, {required bool filled}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: filled ? AppColor.kTexte : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: filled ? AppColor.kTexte : AppColor.kBordure),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: 16, color: filled ? Colors.white : AppColor.kTexteFort),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: filled ? Colors.white : AppColor.kTexteFort)),
        ]),
      ),
    );
  }
}
