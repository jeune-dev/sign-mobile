import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/domain/entities/dossier_client.dart';
import 'package:sign_application/features/client/presentation/bloc/dossier_client_bloc.dart';
import 'package:sign_application/features/facture/domain/entities/facture.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_bloc.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_event.dart';
import 'package:sign_application/features/facture/presentation/bloc/facture_state.dart';
import 'package:sign_application/injection_container.dart' as di;

/// La fiche d'un client : tout ce qu'on a établi avec lui.
///
/// La liste des clients ne menait nulle part — on voyait un nom sans pouvoir
/// retrouver ce qu'on lui avait facturé ni ce qu'on avait signé avec lui.
/// Deux onglets suffisent, rangés de la même façon :
///
///   • les factures, une entrée par dossier — un règlement en plusieurs fois
///     ne prend qu'une ligne, qui s'ouvre sur ses versements ;
///   • les contrats, groupés par type.
class ClientDossierPage extends StatelessWidget {
  final Client client;

  const ClientDossierPage({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => di.sl<DossierClientBloc>()..add(ChargerDossierClient(client.id)),
        ),
        // Le bloc des factures sert uniquement à ouvrir un PDF depuis cette
        // fiche : il n'y a pas de raison de dupliquer ici la récupération du
        // document, elle existe déjà.
        BlocProvider(create: (_) => di.sl<FactureBloc>()),
      ],
      child: _ClientDossierView(client: client),
    );
  }
}

class _ClientDossierView extends StatefulWidget {
  final Client client;
  const _ClientDossierView({required this.client});

  @override
  State<_ClientDossierView> createState() => _ClientDossierViewState();
}

class _ClientDossierViewState extends State<_ClientDossierView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  String _formatMontant(double v) {
    final s = v.round().toString();
    final buf = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      if (i > 0 && (s.length - i) % 3 == 0) buf.write(' ');
      buf.write(s[i]);
    }
    return '${buf.toString()} FCFA';
  }

  String _formatDate(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso);
    if (d == null) return '—';
    return '${d.day.toString().padLeft(2, '0')}/'
        '${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  /// Écrit le PDF reçu dans un fichier temporaire puis l'affiche — la visionneuse
  /// lit un chemin, pas des octets.
  Future<void> _afficherPdf(List<int> bytes, String titre) async {
    try {
      final dir = await getTemporaryDirectory();
      final fichier = File('${dir.path}/doc_$titre.pdf');
      await fichier.writeAsBytes(bytes);
      if (!mounted) return;
      await Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PdfViewerPage(filePath: fichier.path, titre: titre),
        ),
      );
    } catch (e) {
      if (mounted) {
        showToast(context, 'Erreur', "Impossible d'ouvrir le document : $e",
            ToastificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final nomComplet = '${widget.client.prenom} ${widget.client.nom}'.trim();

    return BlocListener<FactureBloc, FactureState>(
      listener: (context, state) {
        if (state is DocumentBytes) {
          _afficherPdf(state.bytes, state.titre);
        }
        if (state is FactureError) {
          showToast(context, 'Erreur', state.message, ToastificationType.error);
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF7F8FA),
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          foregroundColor: Colors.black87,
          title: Text(
            nomComplet.isEmpty ? 'Client' : nomComplet,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.w800, color: Colors.black87),
          ),
          bottom: TabBar(
            controller: _tabs,
            labelColor: Colors.black87,
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xFF6C63FF),
            indicatorWeight: 2.5,
            labelStyle:
                const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            tabs: const [
              Tab(text: 'Factures'),
              Tab(text: 'Contrats'),
            ],
          ),
        ),
        body: BlocBuilder<DossierClientBloc, DossierClientState>(
          builder: (context, state) {
            if (state is DossierClientLoading || state is DossierClientInitial) {
              return const Padding(
                padding: EdgeInsets.all(16),
                child: ShimmerList(),
              );
            }

            if (state is DossierClientError) {
              return _erreur(context, state.message);
            }

            final dossier = (state as DossierClientLoaded).dossier;

            return Column(
              children: [
                _bandeauResume(dossier.resume),
                Expanded(
                  child: TabBarView(
                    controller: _tabs,
                    children: [
                      _ongletFactures(dossier.factures),
                      _ongletContrats(dossier.contrats),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // ── Résumé ────────────────────────────────────────────────────────────────

  Widget _bandeauResume(ResumeDossierClient resume) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
      child: Row(
        children: [
          Expanded(
            child: _stat('Facturé', _formatMontant(resume.montantFacture),
                const Color(0xFF6C63FF)),
          ),
          Expanded(
            child: _stat('Réglé', _formatMontant(resume.montantRegle),
                const Color(0xFF22C55E)),
          ),
          Expanded(
            child: _stat('Reste', _formatMontant(resume.resteAPayer),
                resume.resteAPayer > 0
                    ? const Color(0xFFF97316)
                    : Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String valeur, Color couleur) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: 11,
                color: Colors.grey[500],
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 3),
        Text(valeur,
            style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w800, color: couleur)),
      ],
    );
  }

  // ── Factures ──────────────────────────────────────────────────────────────

  Widget _ongletFactures(List<Facture> factures) {
    if (factures.isEmpty) {
      return _vide(Icons.receipt_long_outlined,
          'Aucune facture', "Vous n'avez encore rien facturé à ce client.");
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: factures.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _carteFacture(factures[index]),
    );
  }

  Widget _carteFacture(Facture facture) {
    final estDossier = facture.dossier.estDossier;
    final soldee = facture.resteAPayer <= 0;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            leading: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: (estDossier
                        ? const Color(0xFF6C63FF)
                        : const Color(0xFF00C896))
                    .withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(13),
              ),
              child: Icon(
                estDossier
                    ? Icons.folder_copy_outlined
                    : Icons.receipt_long_rounded,
                color: estDossier
                    ? const Color(0xFF6C63FF)
                    : const Color(0xFF00C896),
                size: 20,
              ),
            ),
            title: Text(facture.numeroFacture ?? '—',
                style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                estDossier
                    ? '${facture.dossier.nombreFactures} factures · ${soldee ? 'soldée' : 'reste ${_formatMontant(facture.resteAPayer)}'}'
                    : '${_formatDate(facture.dateGeneration)} · ${soldee ? 'soldée' : 'reste ${_formatMontant(facture.resteAPayer)}'}',
                style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500),
              ),
            ),
            trailing: Text(_formatMontant(facture.dossier.totalTtc),
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: Colors.black87)),
          ),

          // Le dossier n'affiche pas ses versements par défaut : la fiche
          // resterait illisible pour un client qui règle tout en plusieurs
          // fois. On les déplie à la demande.
          if (estDossier)
            Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: const EdgeInsets.symmetric(horizontal: 14),
                childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
                title: Text('Voir les ${facture.dossier.nombreFactures} factures',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF6C63FF))),
                children: _piecesDuDossier(facture),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
              child: _boutonOuvrir(
                  facture.id, facture.numeroFacture ?? 'facture'),
            ),
        ],
      ),
    );
  }

  /// La facture d'origine puis chaque facture émise à un versement.
  List<Widget> _piecesDuDossier(Facture facture) {
    final pieces = <Widget>[
      _lignePiece(
        facture.id,
        facture.numeroFacture ?? '—',
        'Facture initiale',
        facture.historiqueVersements.isNotEmpty
            ? facture.historiqueVersements.first.montant
            : 0,
      ),
    ];

    for (final v in facture.versements) {
      pieces.add(_lignePiece(
        v['id']?.toString() ?? '',
        v['numero_facture']?.toString() ?? '—',
        'Versement',
        (v['montant_versement'] ?? 0).toDouble(),
      ));
    }
    return pieces;
  }

  Widget _lignePiece(String id, String numero, String libelle, double montant) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: InkWell(
        onTap: id.isEmpty
            ? null
            : () => context
                .read<FactureBloc>()
                .add(OuvrirDocumentEvent(id, titre: numero)),
        borderRadius: BorderRadius.circular(11),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(11),
            border: Border.all(color: Colors.grey[200]!),
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(numero,
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Colors.black87)),
                    const SizedBox(height: 2),
                    Text(libelle,
                        style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              Text(_formatMontant(montant),
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87)),
              const SizedBox(width: 8),
              Icon(Icons.open_in_new_rounded, size: 15, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _boutonOuvrir(String id, String titre) {
    return GestureDetector(
      onTap: () => context
          .read<FactureBloc>()
          .add(OuvrirDocumentEvent(id, titre: titre)),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.open_in_new_rounded, size: 15, color: Colors.black87),
            SizedBox(width: 6),
            Text('Ouvrir la facture',
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87)),
          ],
        ),
      ),
    );
  }

  // ── Contrats ──────────────────────────────────────────────────────────────

  Widget _ongletContrats(List<GroupeContrats> groupes) {
    if (groupes.isEmpty) {
      return _vide(Icons.description_outlined, 'Aucun contrat',
          "Vous n'avez encore établi aucun document avec ce client.");
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
      itemCount: groupes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _carteGroupe(groupes[index]),
    );
  }

  Widget _carteGroupe(GroupeContrats groupe) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          // Un seul document ne se cache pas derrière un dossier fermé.
          initiallyExpanded: groupe.documents.length == 1,
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          leading: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF6C63FF).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: const Icon(Icons.folder_outlined,
                color: Color(0xFF6C63FF), size: 20),
          ),
          title: Text(groupe.typeLabel,
              style: const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87)),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${groupe.documents.length} document${groupe.documents.length > 1 ? 's' : ''}',
              style: TextStyle(
                  fontSize: 11.5,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500),
            ),
          ),
          children: groupe.documents.map(_ligneContrat).toList(),
        ),
      ),
    );
  }

  Widget _ligneContrat(ContratResume contrat) {
    final couleurStatut =
        contrat.estSigne ? const Color(0xFF22C55E) : const Color(0xFFF97316);
    final libelleStatut = contrat.estSigne
        ? 'Signé'
        : (contrat.statut == 'genere' ? 'Établi' : 'En attente');

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(contrat.numero ?? '—',
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.black87)),
                  const SizedBox(height: 2),
                  Text(_formatDate(contrat.date),
                      style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: couleurStatut.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border:
                    Border.all(color: couleurStatut.withValues(alpha: 0.3)),
              ),
              child: Text(libelleStatut,
                  style: TextStyle(
                      color: couleurStatut,
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      ),
    );
  }

  // ── États vides / erreur ──────────────────────────────────────────────────

  Widget _vide(IconData icone, String titre, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icone, size: 46, color: Colors.grey[300]),
            const SizedBox(height: 14),
            Text(titre,
                style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: Colors.black54)),
            const SizedBox(height: 6),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12.5, color: Colors.grey[500], height: 1.4)),
          ],
        ),
      ),
    );
  }

  Widget _erreur(BuildContext context, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded,
                size: 46, color: Color(0xFFEF4444)),
            const SizedBox(height: 14),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 13, color: Colors.grey[600], height: 1.4)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context
                  .read<DossierClientBloc>()
                  .add(ChargerDossierClient(widget.client.id)),
              child: const Text('Réessayer'),
            ),
          ],
        ),
      ),
    );
  }
}
