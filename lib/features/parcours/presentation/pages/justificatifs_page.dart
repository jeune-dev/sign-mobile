import 'dart:io';
import 'package:sign_application/core/utils/marge_systeme.dart';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:toastification/toastification.dart';

import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/toastNotif.dart';
import 'package:sign_application/core/services/securite_ecran.dart';
import 'package:sign_application/injection_container.dart';

import '../../data/datasources/parcours_remote_datasource.dart';
import '../../data/models/exigences_document.dart';
import '../../data/suivi_profil_service.dart';
import '../../domain/etat_profil.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// justificatifs_page.dart — Vérification de l'identité et des informations
/// professionnelles (§ 12), avec l'information de l'utilisateur exigée au
/// § 13 sur l'usage et la conservation de ces documents.
///
/// Les justificatifs partent vers un espace privé chiffré, jamais vers une
/// boîte mail : voir `justificatif.service.js` côté backend.
///
/// Chaque pièce est transmise dès qu'elle est choisie : il n'y a rien à
/// « valider » en fin d'écran, et l'utilisateur peut quitter puis revenir
/// déposer la suivante sans rien reperdre. Le compteur en tête dit ce qu'il
/// reste à fournir.
///
/// ⚠️ Seules les photos sont proposées ici (appareil photo ou galerie). Le
/// backend accepte aussi le PDF, mais l'application n'embarque pas de
/// sélecteur de fichiers — ajouter `file_picker` au pubspec si le dépôt de
/// PDF devient nécessaire.
class JustificatifsPage extends StatefulWidget {
  const JustificatifsPage({super.key});

  @override
  State<JustificatifsPage> createState() => _JustificatifsPageState();
}

class _TypeJustificatif {
  final String cle;
  final String titre;
  final String description;
  final IconData icone;
  final bool professionnel;

  const _TypeJustificatif({
    required this.cle,
    required this.titre,
    required this.description,
    required this.icone,
    this.professionnel = false,
  });
}

class _JustificatifsPageState extends State<JustificatifsPage> {
  static const List<_TypeJustificatif> _types = [
    // La pièce d'identité se dépose EN DEUX FACES : une CNI n'est vérifiable
    // que si l'on voit le recto (photo, identité) et le verso (mentions, date
    // de délivrance). Ces clés doivent rester alignées sur TYPES_AUTORISES
    // côté backend (justificatif.service.js).
    _TypeJustificatif(
      cle: 'cni_recto',
      titre: 'CNI — recto',
      description: 'La face avec votre photo et votre identité.',
      icone: Icons.badge_outlined,
    ),
    _TypeJustificatif(
      cle: 'cni_verso',
      titre: 'CNI — verso',
      description: 'La face avec les mentions et la date de délivrance.',
      icone: Icons.badge_outlined,
    ),
    _TypeJustificatif(
      cle: 'passeport_recto',
      titre: 'Passeport — page photo',
      description: 'La page d’identification, celle qui porte votre photo.',
      icone: Icons.menu_book_outlined,
    ),
    _TypeJustificatif(
      cle: 'passeport_verso',
      titre: 'Passeport — page opposée',
      description: 'La page qui fait face à la page d’identification.',
      icone: Icons.menu_book_outlined,
    ),
    _TypeJustificatif(
      cle: 'rccm',
      titre: 'Document RCCM',
      description: 'Registre du commerce de votre entreprise.',
      icone: Icons.storefront_outlined,
      professionnel: true,
    ),
    _TypeJustificatif(
      cle: 'ninea',
      titre: 'Document NINEA',
      description: 'Attestation NINEA, si votre activité en dispose.',
      icone: Icons.receipt_long_outlined,
      professionnel: true,
    ),
  ];

  List<Justificatif> _justificatifs = [];
  MentionsJustificatifs? _mentions;
  bool _chargement = true;
  String? _envoiEnCours;

  /// Pièce d'identité choisie dans le profil : elle décide des deux faces
  /// réellement exigées parmi les quatre proposées.
  String? _typePiece;

  /// La pièce à retenir pour le décompte.
  ///
  /// Le profil fait foi. Tant qu'il ne dit rien, on suit ce qui a déjà été
  /// déposé : quelqu'un qui a envoyé une page de passeport n'a pas à se voir
  /// réclamer une CNI.
  String? get _typePieceEffectif {
    if (_typePiece != null && _typePiece!.isNotEmpty) return _typePiece;
    final aPasseport =
        _justificatifs.any((j) => j.type.startsWith('passeport'));
    return aPasseport ? 'passeport' : null;
  }

  /// Les faces attendues pour cette pièce.
  List<ElementManquant> get _facesAttendues =>
      EtatProfil.facesAttendues(_typePieceEffectif);

  /// Ce qu'il reste à transmettre. Une pièce refusée y revient : elle doit
  /// être redéposée, l'ignorer laisserait l'utilisateur attendre une
  /// validation qui ne viendrait jamais.
  List<ElementManquant> get _documentsRestants {
    final utilisables = <String>{
      for (final j in _justificatifs)
        if (!j.estRejete) j.type,
    };
    return _facesAttendues
        .where((face) => !utilisables.contains(face.cle))
        .toList();
  }

  bool _estObligatoire(String cle) =>
      _facesAttendues.any((face) => face.cle == cle);

  @override
  void initState() {
    super.initState();
    // Cet écran manipule des pièces d'identité : on interdit la capture et,
    // surtout, la vignette du gestionnaire de tâches qui survivrait à la
    // fermeture de l'application.
    SecuriteEcran.activer();
    _charger();
  }

  @override
  void dispose() {
    // Levée impérativement symétrique — sans elle, la capture resterait
    // bloquée sur tous les écrans suivants de la session.
    SecuriteEcran.desactiver();
    super.dispose();
  }

  Future<void> _charger() async {
    try {
      final source = sl<ParcoursRemoteDataSource>();
      final resultat = await source.listerJustificatifs();
      // Le profil dit quelle pièce a été choisie — sans lui, impossible de
      // savoir si ce sont les faces de la CNI ou celles du passeport qui
      // manquent.
      final profil = await source.prereemplissage();

      // L'état est calculé ici puis poussé au service : cet écran vient de
      // charger les deux moitiés de l'information, le refaire ailleurs serait
      // deux appels pour rien.
      sl<SuiviProfilService>().appliquer(EtatProfil.analyser(
        profil: profil,
        justificatifs: resultat.justificatifs,
      ));

      if (!mounted) return;
      setState(() {
        _justificatifs = resultat.justificatifs;
        _mentions = resultat.mentions;
        _typePiece = profil['type_document_identite']?.toString();
        _chargement = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _chargement = false);
    }
  }

  /// Une pièce d'identité n'est vérifiable que si ses DEUX faces sont
  /// déposées. L'utilisateur choisit CNI ou passeport, jamais les deux : le
  /// dossier est donc complet dès qu'une paire l'est.
  ///
  /// Une face refusée ne compte pas : annoncer « profil complet » alors qu'une
  /// pièce est à redéposer ferait attendre une validation qui ne viendra pas.
  bool get _identiteComplete => _documentsRestants.isEmpty;

  Justificatif? _justificatifPour(String type) {
    for (final j in _justificatifs) {
      if (j.type == type) return j;
    }
    return null;
  }

  // ── Dépôt ───────────────────────────────────────────────────────────────

  Future<void> _deposer(_TypeJustificatif type) async {
    final source = await _choisirSource();
    if (source == null) return;

    final XFile? fichier = await ImagePicker().pickImage(
      source: source,
      // Compression raisonnable : un document reste parfaitement lisible et
      // le fichier passe sous la limite de 5 MB du backend.
      imageQuality: 85,
      maxWidth: 2000,
    );
    if (fichier == null) return;

    setState(() => _envoiEnCours = type.cle);
    try {
      await sl<ParcoursRemoteDataSource>().deposerJustificatif(
        type: type.cle,
        fichier: File(fichier.path),
      );
      if (!mounted) return;
      await _charger();
      if (!mounted) return;
      // Le message dit où l'on en est : ce qui vient d'être déposé est acquis,
      // et l'utilisateur peut s'arrêter là s'il ne peut pas continuer tout de
      // suite.
      final restants = _documentsRestants.length;
      showToast(
        context,
        _identiteComplete ? 'Pièce d’identité complète' : 'Justificatif transmis',
        _identiteComplete
            ? 'Votre dossier part en examen. Vous serez prévenu par e-mail.'
            : 'Il est enregistré. Il reste $restants document'
                '${restants > 1 ? 's' : ''} à transmettre — vous pouvez y '
                'revenir plus tard.',
        ToastificationType.success,
      );
    } on ParcoursException catch (e) {
      if (!mounted) return;
      showToast(context, 'Envoi impossible', e.message, ToastificationType.error);
    } catch (_) {
      if (!mounted) return;
      showToast(context, 'Envoi impossible',
          'Vérifiez votre connexion et réessayez.', ToastificationType.error);
    } finally {
      if (mounted) setState(() => _envoiEnCours = null);
    }
  }

  Future<ImageSource?> _choisirSource() {
    return showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            ListTile(
              leading: Icon(Icons.photo_camera_outlined, color: AppColor.kPrimary),
              title: Text('Prendre une photo',
                  style: AppTypo.jakarta(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.camera),
            ),
            ListTile(
              leading: Icon(Icons.photo_library_outlined, color: AppColor.kPrimary),
              title: Text('Choisir dans la galerie',
                  style: AppTypo.jakarta(fontWeight: FontWeight.w600)),
              onTap: () => Navigator.of(context).pop(ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  /// § 13 : suppression à la demande de l'utilisateur.
  Future<void> _supprimer(Justificatif justificatif) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: Text(
          'Supprimer ce justificatif ?',
          style: AppTypo.jakarta(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
        content: Text(
          'Le document sera définitivement effacé de nos serveurs. Vous pourrez '
          'en déposer un nouveau à tout moment.',
          style: AppTypo.jakarta(
            fontSize: 14,
            color: AppColor.kGrayscale40,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Annuler',
                style: AppTypo.jakarta(color: AppColor.kGrayscale40)),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Supprimer',
                style: AppTypo.jakarta(
                    color: AppColor.kDanger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirme != true) return;

    try {
      await sl<ParcoursRemoteDataSource>().supprimerJustificatif(justificatif.id);
      if (!mounted) return;
      showToast(context, 'Justificatif supprimé',
          'Le document a été effacé.', ToastificationType.success);
      await _charger();
    } on ParcoursException catch (e) {
      if (!mounted) return;
      showToast(context, 'Suppression impossible', e.message, ToastificationType.error);
    }
  }

  // ── Construction ────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: AppColor.kGrayscaleDark100,
        title: Text(
          'Vérification',
          style: AppTypo.jakarta(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: AppColor.kGrayscaleDark100,
          ),
        ),
      ),
      body: _chargement
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _charger,
              child: ListView(
                padding: avecMargeBasse(context, const EdgeInsets.fromLTRB(24, 8, 24, 32)),
                children: [
                  _introduction(),
                  const SizedBox(height: 20),
                  if (_identiteComplete)
                    _bandeauComplet()
                  else
                    _compteurDocumentsRestants(),
                  const SizedBox(height: 24),
                  ..._types.map(_carteType),
                  const SizedBox(height: 8),
                  if (_mentions != null) _blocMentions(),
                ],
              ),
            ),
    );
  }

  Widget _introduction() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Vérifiez votre identité et vos informations professionnelles',
          style: AppTypo.jakarta(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColor.kGrayscaleDark100,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Pour sécuriser votre compte et garantir la fiabilité de vos documents, '
          'transmettez les justificatifs correspondant aux informations que vous '
          'avez renseignées.',
          style: AppTypo.jakarta(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: AppColor.kGrayscale40,
            height: 1.55,
          ),
        ),
      ],
    );
  }

  /// Confirme que le dossier est constitué et annonce la suite. Sans ce
  /// retour, l'utilisateur ne sait pas s'il doit encore faire quelque chose :
  /// il a déposé ses pièces et l'écran ne dit rien de plus qu'avant.
  Widget _bandeauComplet() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5EE),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFBFE3CE)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.verified_outlined, size: 20, color: Color(0xFF1B7F4B)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Profil complet',
                  style: AppTypo.jakarta(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF14603A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Vos justificatifs vont être examinés par notre équipe. '
                  'Vous serez prévenu par e-mail dès que votre compte sera vérifié.',
                  style: AppTypo.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF14603A),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Combien de pièces manquent encore, et lesquelles.
  ///
  /// Six cartes sont proposées mais deux seulement sont exigées — celles de la
  /// pièce choisie dans le profil. Sans ce décompte, l'utilisateur ne peut pas
  /// savoir quand il a fini.
  Widget _compteurDocumentsRestants() {
    final restants = _documentsRestants;
    if (restants.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF3DCB0)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.file_upload_outlined, size: 20, color: AppColor.kAlerte),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${restants.length} document${restants.length > 1 ? 's' : ''} '
                  'restant${restants.length > 1 ? 's' : ''} à transmettre',
                  style: AppTypo.jakarta(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF7A4E00),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${restants.map((d) => d.libelle).join(' · ')}.\n'
                  'Chaque pièce est enregistrée dès son envoi : vous pouvez '
                  'revenir déposer les suivantes plus tard.',
                  style: AppTypo.jakarta(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF7A4E00),
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Distingue les deux pièces réellement exigées des quatre autres.
  ///
  /// La liste propose CNI et passeport côte à côte : sans repère, on ne sait
  /// pas laquelle des deux séries l'application attend.
  Widget _etiquetteExigence(bool obligatoire) {
    final couleur = obligatoire ? AppColor.kAlerte : AppColor.kGrayscale40;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Text(
        obligatoire ? 'Requis' : 'Facultatif',
        style: AppTypo.jakarta(
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          color: couleur,
          letterSpacing: 0.2,
        ),
      ),
    );
  }

  Widget _carteType(_TypeJustificatif type) {
    final existant = _justificatifPour(type.cle);
    final envoi = _envoiEnCours == type.cle;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColor.kLine, width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(type.icone, size: 24, color: AppColor.kGrayscaleDark100),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            type.titre,
                            style: AppTypo.jakarta(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kGrayscaleDark100,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        _etiquetteExigence(_estObligatoire(type.cle)),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      type.description,
                      style: AppTypo.jakarta(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w400,
                        color: AppColor.kGrayscale40,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (existant != null) ...[
            const SizedBox(height: 14),
            _pastilleStatut(existant),
            if (existant.estRejete && existant.motifRejet != null) ...[
              const SizedBox(height: 8),
              Text(
                existant.motifRejet!,
                style: AppTypo.jakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                  color: AppColor.kDanger,
                  height: 1.4,
                ),
              ),
            ],
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: envoi ? null : () => _deposer(type),
                  icon: envoi
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(
                          existant == null
                              ? Icons.upload_outlined
                              : Icons.refresh_rounded,
                          size: 18,
                        ),
                  label: Text(
                    existant == null ? 'Ajouter' : 'Remplacer',
                    style: AppTypo.jakarta(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColor.kGrayscaleDark100,
                    side: BorderSide(color: AppColor.kLine, width: 1.3),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              if (existant != null) ...[
                const SizedBox(width: 10),
                IconButton(
                  onPressed: () => _supprimer(existant),
                  icon: const Icon(Icons.delete_outline_rounded, size: 20),
                  color: AppColor.kDanger,
                  tooltip: 'Supprimer',
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _pastilleStatut(Justificatif justificatif) {
    final couleur = justificatif.estValide
        ? AppColor.kSucces
        : justificatif.estRejete
            ? AppColor.kDanger
            : AppColor.kAlerte;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: couleur.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            justificatif.estValide
                ? Icons.verified_outlined
                : justificatif.estRejete
                    ? Icons.cancel_outlined
                    : Icons.schedule_rounded,
            size: 15,
            color: couleur,
          ),
          const SizedBox(width: 6),
          Text(
            justificatif.libelleStatut,
            style: AppTypo.jakarta(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: couleur,
            ),
          ),
        ],
      ),
    );
  }

  /// § 13 : information claire de l'utilisateur sur l'usage de ses documents.
  Widget _blocMentions() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColor.kBackground2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.shield_outlined, size: 18, color: AppColor.kGrayscaleDark100),
              const SizedBox(width: 8),
              Text(
                'Ce que SIGNS fait de vos documents',
                style: AppTypo.jakarta(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: AppColor.kGrayscaleDark100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._mentions!.toutes.where((m) => m.isNotEmpty).map(
                (mention) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 6),
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: AppColor.kGrayscale40,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          mention,
                          style: AppTypo.jakarta(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w400,
                            color: AppColor.kGrayscale40,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
