import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/theme/app_typo.dart';
import 'package:sign_application/core/utils/download_helper.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';
import 'package:sign_application/core/widgets/pdf_viewer_page.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';

/// document_genere_page.dart — Confirmation après génération (§ 9).
///
/// Jusqu'ici, une création réussie affichait un message fugace puis refermait
/// l'écran : l'utilisateur était renvoyé à une liste, c'est-à-dire au moment le
/// moins gratifiant du parcours, juste après l'effort de saisie.
///
/// Cet écran rend le résultat tangible — le document est là, on peut le voir,
/// l'enregistrer et le transmettre — et sert de point d'accroche naturel à la
/// proposition de compte complet (§ 10), qui s'affichait auparavant par-dessus
/// une liste, sans contexte.
///
/// Le téléchargement est délégué à [telecharger] : chaque fonctionnalité
/// possède déjà son point d'accès, cet écran n'a pas à les connaître.
class DocumentGenerePage extends StatefulWidget {
  /// Nom du document tel qu'on s'adresse à l'utilisateur : « facture »,
  /// « contrat de bail »… Utilisé dans le titre.
  final String libelle;

  /// Accord du participe : « prête » pour une facture, « prêt » pour un contrat.
  final bool feminin;

  /// Numéro ou référence, affiché sous le titre quand il est connu.
  final String? reference;

  /// Récupère les octets du PDF. Appelée une fois à l'ouverture.
  final Future<List<int>> Function() telecharger;

  /// Action d'envoi par e-mail, si la fonctionnalité en propose une.
  final Future<void> Function()? envoyerParEmail;

  const DocumentGenerePage({
    super.key,
    required this.libelle,
    required this.telecharger,
    this.feminin = false,
    this.reference,
    this.envoyerParEmail,
  });

  @override
  State<DocumentGenerePage> createState() => _DocumentGenerePageState();
}

class _DocumentGenerePageState extends State<DocumentGenerePage> {
  Uint8List? _octets;
  String? _cheminTemporaire;
  bool _chargement = true;
  String? _erreur;
  bool _envoiEmail = false;

  @override
  void initState() {
    super.initState();
    _recupererDocument();
  }

  String get _nomFichier {
    final base = widget.libelle.toLowerCase().replaceAll(' ', '-');
    final reference = (widget.reference ?? '').replaceAll(RegExp(r'[^\w\-]'), '');
    return reference.isEmpty ? '$base.pdf' : '$base-$reference.pdf';
  }

  /// Récupère le PDF et le dépose dans un fichier temporaire, que toutes les
  /// actions réutilisent — inutile de le retélécharger à chaque appui.
  Future<void> _recupererDocument() async {
    setState(() {
      _chargement = true;
      _erreur = null;
    });
    try {
      final octets = Uint8List.fromList(await widget.telecharger());
      final dossier = await getTemporaryDirectory();
      final fichier = File('${dossier.path}/$_nomFichier');
      await fichier.writeAsBytes(octets, flush: true);
      if (!mounted) return;
      setState(() {
        _octets = octets;
        _cheminTemporaire = fichier.path;
        _chargement = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _chargement = false;
        _erreur = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  void _apercu() {
    if (_cheminTemporaire == null) return;
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => PdfViewerPage(
        filePath: _cheminTemporaire!,
        titre: widget.reference ?? widget.libelle,
      ),
    ));
  }

  Future<void> _telechargerSurLAppareil() async {
    if (_octets == null) return;
    try {
      final chemin = await savePdfToDownloads(_octets!, _nomFichier);
      if (!mounted) return;
      showDownloadSuccessSnackBar(context, _nomFichier, chemin,
          isIos: Platform.isIOS);
    } catch (e) {
      if (!mounted) return;
      showDownloadErrorSnackBar(context, e.toString());
    }
  }

  /// Ouvre le PDF dans l'application de lecture du téléphone, depuis laquelle
  /// l'utilisateur dispose du partage natif (WhatsApp, e-mail, impression).
  ///
  /// Une feuille de partage directe demanderait le paquet `share_plus`, absent
  /// du projet — voir la note en fin de fichier.
  Future<void> _ouvrirEtPartager() async {
    if (_cheminTemporaire == null) return;
    final resultat = await OpenFile.open(_cheminTemporaire!);
    if (!mounted) return;
    if (resultat.type != ResultType.done) {
      showToast(
        context,
        'Ouverture impossible',
        "Aucune application de lecture de PDF n'a été trouvée sur ce téléphone.",
        ToastificationType.warning,
      );
    }
  }

  Future<void> _envoyerParEmail() async {
    final envoi = widget.envoyerParEmail;
    if (envoi == null) return;
    setState(() => _envoiEmail = true);
    try {
      await envoi();
      if (!mounted) return;
      showToast(context, 'Document envoyé',
          'Le document a été transmis par e-mail.', ToastificationType.success);
    } catch (e) {
      if (!mounted) return;
      showToast(context, 'Envoi impossible',
          e.toString().replaceAll('Exception: ', ''), ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoiEmail = false);
    }
  }

  void _terminer() => Navigator.of(context).pop(true);

  // ── Construction ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    // Le retour matériel équivaut à « Terminé » : le document est créé, il n'y
    // a rien à annuler, et le parcours doit recevoir sa confirmation.
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _terminer();
      },
      child: Scaffold(
        backgroundColor: AppColor.kSurface,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: AppEspace.xl),
                  child: Column(
                    children: [
                      const SizedBox(height: AppEspace.xxl),
                      _pastilleSucces(),
                      const SizedBox(height: AppEspace.xl),
                      _titre(),
                      const SizedBox(height: AppEspace.xxl),
                      _carteDocument(),
                      const SizedBox(height: AppEspace.xl),
                      if (_erreur == null) _actions(),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                    AppEspace.xl, AppEspace.s, AppEspace.xl, AppEspace.xxl),
                child: AppBouton(libelle: 'Terminé', onPressed: _terminer),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pastilleSucces() {
    return Container(
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColor.fondEtat(AppColor.kSucces),
        shape: BoxShape.circle,
      ),
      child: Icon(Icons.check_rounded, size: 40, color: AppColor.kSucces),
    );
  }

  Widget _titre() {
    return Column(
      children: [
        Text(
          'Votre ${widget.libelle.toLowerCase()} est ${widget.feminin ? 'prête' : 'prêt'}',
          textAlign: TextAlign.center,
          style: AppTypo.jakarta(
            fontSize: 24,
            fontWeight: FontWeight.w800,
            color: AppColor.kTexte,
            height: 1.25,
          ),
        ),
        if (widget.reference != null && widget.reference!.isNotEmpty) ...[
          const SizedBox(height: AppEspace.s),
          Text(
            widget.reference!,
            textAlign: TextAlign.center,
            style: AppTypo.jakarta(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColor.kTexteMoyen,
            ),
          ),
        ],
      ],
    );
  }

  Widget _carteDocument() {
    return Container(
      padding: const EdgeInsets.all(AppEspace.l),
      decoration: BoxDecoration(
        color: AppColor.kChamp,
        borderRadius: BorderRadius.circular(AppRayon.carte),
        border: Border.all(color: AppColor.kBordure, width: 1.2),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColor.kSurface,
              borderRadius: BorderRadius.circular(AppRayon.champ),
              border: Border.all(color: AppColor.kBordure),
            ),
            child: Icon(Icons.picture_as_pdf_outlined,
                size: 22, color: AppColor.kTexte),
          ),
          const SizedBox(width: AppEspace.m),
          Expanded(child: _etatDocument()),
        ],
      ),
    );
  }

  Widget _etatDocument() {
    if (_chargement) {
      return Row(
        children: [
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          const SizedBox(width: AppEspace.m),
          Text(
            'Préparation du document…',
            style: AppTypo.jakarta(fontSize: 13.5, color: AppColor.kTexteMoyen),
          ),
        ],
      );
    }

    if (_erreur != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document créé, mais non récupéré',
            style: AppTypo.jakarta(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              color: AppColor.kTexte,
            ),
          ),
          const SizedBox(height: AppEspace.xs),
          // On insiste : l'échec porte sur le téléchargement, pas sur la
          // création. Le document existe et reste accessible depuis la liste.
          Text(
            'Il est bien enregistré et reste accessible depuis la liste. $_erreur',
            style: AppTypo.jakarta(
              fontSize: 12.5,
              color: AppColor.kTexteMoyen,
              height: 1.45,
            ),
          ),
          const SizedBox(height: AppEspace.s),
          GestureDetector(
            onTap: _recupererDocument,
            child: Text(
              'Réessayer',
              style: AppTypo.jakarta(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColor.kPrimary,
              ),
            ),
          ),
        ],
      );
    }

    final tailleKo = ((_octets?.length ?? 0) / 1024).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _nomFichier,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTypo.jakarta(
            fontSize: 13.5,
            fontWeight: FontWeight.w700,
            color: AppColor.kTexte,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'PDF · $tailleKo Ko',
          style: AppTypo.jakarta(fontSize: 12.5, color: AppColor.kTexteMoyen),
        ),
      ],
    );
  }

  Widget _actions() {
    final pret = !_chargement && _cheminTemporaire != null;
    return Column(
      children: [
        _action(
          icone: Icons.visibility_outlined,
          libelle: 'Aperçu du document',
          onTap: pret ? _apercu : null,
        ),
        _action(
          icone: Icons.download_outlined,
          libelle: 'Enregistrer sur le téléphone',
          onTap: pret ? _telechargerSurLAppareil : null,
        ),
        _action(
          icone: Icons.ios_share_outlined,
          libelle: 'Ouvrir et partager',
          onTap: pret ? _ouvrirEtPartager : null,
        ),
        if (widget.envoyerParEmail != null)
          _action(
            icone: Icons.mail_outline_rounded,
            libelle: 'Envoyer par e-mail',
            onTap: _envoiEmail ? null : _envoyerParEmail,
            enCours: _envoiEmail,
          ),
      ],
    );
  }

  Widget _action({
    required IconData icone,
    required String libelle,
    required VoidCallback? onTap,
    bool enCours = false,
  }) {
    final actif = onTap != null;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppEspace.m),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRayon.carte),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: AppEspace.l, vertical: AppEspace.l),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRayon.carte),
              border: Border.all(color: AppColor.kBordure, width: 1.2),
            ),
            child: Row(
              children: [
                Icon(icone,
                    size: 20,
                    color: actif ? AppColor.kTexte : AppColor.kTexteFaible),
                const SizedBox(width: AppEspace.m),
                Expanded(
                  child: Text(
                    libelle,
                    style: AppTypo.jakarta(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w600,
                      color: actif ? AppColor.kTexte : AppColor.kTexteFaible,
                    ),
                  ),
                ),
                if (enCours)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(Icons.chevron_right_rounded,
                      size: 20,
                      color: actif ? AppColor.kTexteMoyen : AppColor.kTexteFaible),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// À prévoir : « Ouvrir et partager » délègue au lecteur PDF du téléphone, d'où
// l'utilisateur atteint le partage natif. Une feuille de partage directe
// (WhatsApp, e-mail, impression en un appui) demanderait d'ajouter `share_plus`
// au pubspec — dépendance volontairement non ajoutée sans validation, l'app
// étant en production.
// ─────────────────────────────────────────────────────────────────────────────
