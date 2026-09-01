import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/core/services/premier_lancement_service.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/theme/app_dimensions.dart';
import 'package:sign_application/core/widgets/app_bouton.dart';
import 'package:sign_application/injection_container.dart';
import 'package:sign_application/core/theme/app_typo.dart';

/// bienvenue_page.dart — Page de bienvenue (§ 1 du cahier des charges).
///
/// Affichée une seule fois, juste après l'animation de démarrage
/// (logo puis écran « documents »), et avant l'inscription rapide.
///
/// Un écran unique, volontairement : l'utilisateur vient déjà de patienter
/// pendant l'animation, l'enchaîner sur un carrousel le retiendrait pour rien.
///
/// C'est le premier écran que l'on voit de SIGNS : il doit donc annoncer la
/// couleur, au sens propre comme au figuré. L'application est monochrome — une
/// seule encre noire sur blanc, comme les documents qu'elle produit — et
/// l'écran s'en tient à cette règle, à une exception près : le sceau de
/// validation, seule touche de couleur, qui dit d'emblée ce que fait le
/// produit. Signer.
///
/// L'illustration est dessinée directement (voir [_PeintreSignature]) : pas
/// d'image bitmap à charger, un rendu net à toutes les tailles d'écran, et
/// surtout un tracé que l'on peut animer. La signature s'écrit sous les yeux
/// de l'utilisateur, puis le sceau vient se poser — la promesse du produit
/// jouée plutôt qu'expliquée en trois paragraphes.
///
/// Ce geste tourne en boucle : l'encre s'efface en fin de cycle et la plume
/// reprend. L'écran reste devant l'utilisateur le temps qu'il veut, et rien
/// ne dit qu'il regardait pendant les deux premières secondes.
class BienvenuePage extends StatefulWidget {
  const BienvenuePage({super.key});

  @override
  State<BienvenuePage> createState() => _BienvenuePageState();
}

class _BienvenuePageState extends State<BienvenuePage>
    with TickerProviderStateMixin {
  /// Arrivée de l'écran : jouée une fois, elle n'a pas à se répéter.
  late final AnimationController _controleurEntree;

  /// Signature et sceau : rejoués en boucle. C'est le geste que vend le
  /// produit — le montrer une seule fois le réservait à qui regardait l'écran
  /// pendant les deux premières secondes.
  late final AnimationController _controleurEncre;

  /// Entrées en cascade. Les intervalles se chevauchent : l'écran doit se
  /// déployer d'un seul mouvement, pas apparaître élément par élément.
  late final Animation<double> _feuille;
  late final Animation<double> _titre;
  late final Animation<double> _soustitre;
  late final Animation<double> _atouts;
  late final Animation<double> _pied;

  /// Les trois temps d'un cycle : la plume écrit, le sceau se pose, puis tout
  /// s'efface pour laisser la place au cycle suivant.
  late final Animation<double> _signature;
  late final Animation<double> _sceau;
  late final Animation<double> _effacement;

  /// Vrai quand le système demande de limiter les animations : la boucle est
  /// alors figée sur son état d'arrivée — document signé, sceau posé.
  bool _boucleActive = false;

  Animation<double> _phase(
    AnimationController controleur,
    double debut,
    double fin, {
    Curve courbe = Curves.easeOutCubic,
  }) =>
      CurvedAnimation(parent: controleur, curve: Interval(debut, fin, curve: courbe));

  @override
  void initState() {
    super.initState();
    _controleurEntree = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1700),
    );
    _controleurEncre = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4400),
    );

    _feuille   = _phase(_controleurEntree, 0.00, 0.50);
    _titre     = _phase(_controleurEntree, 0.21, 0.61);
    _soustitre = _phase(_controleurEntree, 0.31, 0.71);
    _atouts    = _phase(_controleurEntree, 0.49, 0.89);
    _pied      = _phase(_controleurEntree, 0.71, 1.00);

    // Le tracé démarre pendant que les textes finissent d'arriver : le regard
    // est déjà revenu sur l'illustration quand la plume se met en marche.
    _signature  = _phase(_controleurEncre, 0.08, 0.42, courbe: Curves.easeInOut);
    _sceau      = _phase(_controleurEncre, 0.44, 0.58, courbe: Curves.easeOutBack);
    // Long palier entre la pose du sceau et l'effacement : c'est le moment où
    // le dessin se lit. Sans lui, la boucle deviendrait un clignotement.
    _effacement = _phase(_controleurEncre, 0.88, 1.00, courbe: Curves.easeIn);

    _controleurEntree.forward();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Une animation qui tourne sans fin est exactement ce que « réduire les
    // animations » désigne : on la remplace alors par l'image d'arrivée.
    final boucleSouhaitee = !MediaQuery.disableAnimationsOf(context);
    if (boucleSouhaitee == _boucleActive) return;

    _boucleActive = boucleSouhaitee;
    if (_boucleActive) {
      _controleurEncre.repeat();
    } else {
      _controleurEncre.stop();
      // 0,70 : après la pose du sceau, avant l'effacement.
      _controleurEncre.value = 0.70;
    }
  }

  @override
  void dispose() {
    _controleurEntree.dispose();
    _controleurEncre.dispose();
    super.dispose();
  }

  /// « J'ai déjà un compte » — même sortie que depuis l'inscription.
  ///
  /// La page de bienvenue ne s'affiche qu'une fois, mais elle s'affiche aussi
  /// à celui qui réinstalle l'application : l'envoyer créer un second compte
  /// serait la mauvaise réponse.
  Future<void> _seConnecter() async {
    await sl<PremierLancementService>().marquerBienvenueVue();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.loginRoute,
      (route) => false,
    );
  }

  Future<void> _commencer() async {
    // Le drapeau est posé avant la navigation : la page ne revient pas, même
    // si l'utilisateur abandonne l'inscription en route (il retomberait alors
    // sur l'écran de connexion, qui propose lui-même de créer un compte).
    await sl<PremierLancementService>().marquerBienvenueVue();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil(
      AppRouter.inscriptionRapideRoute,
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColor.kWhite,
      body: Stack(
        children: [
          const Positioned.fill(child: _FondDiscret()),
          SafeArea(
            child: Column(
              children: [
                Expanded(
                  // Le bloc illustration + textes est centré verticalement dans
                  // l'espace disponible. Le ConstrainedBox force la colonne à
                  // occuper toute la hauteur du viewport : sans lui, une colonne
                  // placée dans une zone défilante se cale en haut. Le
                  // SingleChildScrollView reste là pour les petits écrans et les
                  // grandes tailles de police.
                  child: LayoutBuilder(
                    builder: (context, contraintes) => SingleChildScrollView(
                      child: ConstrainedBox(
                        constraints:
                            BoxConstraints(minHeight: contraintes.maxHeight),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: AppEspace.xl),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(height: AppEspace.l),
                              _Apparition(
                                progression: _feuille,
                                child: _IllustrationSignature(
                                  feuille: _feuille,
                                  signature: _signature,
                                  sceau: _sceau,
                                  effacement: _effacement,
                                ),
                              ),
                              const SizedBox(height: AppEspace.xxxl),
                              _Apparition(
                                progression: _titre,
                                child: Text(
                                  'Bienvenue sur SIGNS',
                                  textAlign: TextAlign.center,
                                  style: AppTypo.jakarta(
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                    color: AppColor.kGrayscaleDark100,
                                    height: 1.15,
                                    letterSpacing: -0.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppEspace.m),
                              _Apparition(
                                progression: _soustitre,
                                child: Text(
                                  'Rédigez, signez et transmettez vos documents '
                                  'officiels depuis votre téléphone.',
                                  textAlign: TextAlign.center,
                                  style: AppTypo.jakarta(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w400,
                                    color: AppColor.kTexteMoyen,
                                    height: 1.6,
                                  ),
                                ),
                              ),
                              const SizedBox(height: AppEspace.xxl),
                              // Trois lignes plutôt qu'un paragraphe : ce que
                              // l'application sait faire se lit d'un coup d'œil,
                              // et chaque ligne annonce une famille de documents
                              // que l'utilisateur retrouvera dans le menu.
                              _Apparition(
                                progression: _atouts,
                                child: const Column(
                                  children: [
                                    _Atout(
                                      icone: Icons.description_outlined,
                                      titre: 'Contrats et baux',
                                      detail: 'Modèles conformes, prêts à remplir',
                                    ),
                                    SizedBox(height: AppEspace.m),
                                    _Atout(
                                      icone: Icons.receipt_long_outlined,
                                      titre: 'Factures et quittances',
                                      detail: 'Générées et envoyées en un geste',
                                    ),
                                    SizedBox(height: AppEspace.m),
                                    _Atout(
                                      icone: Icons.verified_outlined,
                                      titre: 'Signature électronique',
                                      detail: 'Chaque document daté et horodaté',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: AppEspace.l),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                _Apparition(
                  progression: _pied,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                        AppEspace.xl, AppEspace.s, AppEspace.xl, AppEspace.l),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AppBouton(
                          libelle: 'Commencer',
                          iconeFin: Icons.arrow_forward_rounded,
                          onPressed: _commencer,
                        ),
                        const SizedBox(height: AppEspace.s),
                        TextButton(
                          onPressed: _seConnecter,
                          child: Text(
                            'J’ai déjà un compte',
                            style: AppTypo.jakarta(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w700,
                              color: AppColor.kTexte,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                        const SizedBox(height: AppEspace.s),
                        // Dernière ligne de l'écran, et première réponse à la
                        // question que se pose quiconque s'apprête à confier des
                        // documents officiels à une application.
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.lock_outline_rounded,
                                size: 13, color: AppColor.kTexteFaible),
                            const SizedBox(width: AppEspace.xs + 2),
                            Flexible(
                              child: Text(
                                'Vos documents restent privés et vous appartiennent',
                                textAlign: TextAlign.center,
                                style: AppTypo.jakarta(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColor.kTexteFaible,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Fond : deux halos très pâles, en haut à droite et en bas à gauche.
///
/// À peine perceptibles (4 % d'encre au plus fort), ils suffisent à sortir la
/// page du blanc plat sans introduire de couleur ni concurrencer le dessin.
class _FondDiscret extends StatelessWidget {
  const _FondDiscret();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.9, -0.85),
          radius: 1.15,
          colors: [
            AppColor.kPrimary.withValues(alpha: 0.04),
            AppColor.kWhite.withValues(alpha: 0.0),
          ],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1.0, 0.95),
            radius: 1.0,
            colors: [
              AppColor.kPrimary.withValues(alpha: 0.035),
              AppColor.kWhite.withValues(alpha: 0.0),
            ],
          ),
        ),
      ),
    );
  }
}

/// Fondu + légère remontée. Le même mouvement pour tous les blocs de la page :
/// c'est ce qui donne l'impression d'un écran qui se déploie, et non d'une
/// collection d'animations indépendantes.
class _Apparition extends StatelessWidget {
  final Animation<double> progression;
  final Widget child;

  const _Apparition({required this.progression, required this.child});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: progression,
      builder: (context, enfant) => Opacity(
        opacity: progression.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, 18 * (1 - progression.value)),
          child: enfant,
        ),
      ),
      child: child,
    );
  }
}

/// Une capacité de l'application : icône encadrée, intitulé, précision.
class _Atout extends StatelessWidget {
  final IconData icone;
  final String titre;
  final String detail;

  const _Atout({
    required this.icone,
    required this.titre,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColor.kChamp,
            borderRadius: BorderRadius.circular(AppRayon.champ),
            border: Border.all(color: AppColor.kBordure),
          ),
          child: Icon(icone, size: 19, color: AppColor.kTexte),
        ),
        const SizedBox(width: AppEspace.l),
        // Les deux textes prennent la largeur restante : sur un petit écran ou
        // avec une police agrandie, ils passent à la ligne au lieu de déborder.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titre,
                style: AppTypo.jakarta(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  color: AppColor.kTexte,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                detail,
                style: AppTypo.jakarta(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w400,
                  color: AppColor.kTexteFaible,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Le document que l'on signe : une feuille officielle, la signature qui
/// s'écrit, le sceau qui se pose.
class _IllustrationSignature extends StatelessWidget {
  final Animation<double> feuille;
  final Animation<double> signature;
  final Animation<double> sceau;

  /// Fin de cycle : l'encre s'efface pour que la plume puisse reprendre.
  final Animation<double> effacement;

  const _IllustrationSignature({
    required this.feuille,
    required this.signature,
    required this.sceau,
    required this.effacement,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 300),
        child: AspectRatio(
          aspectRatio: _PeintreSignature.largeurReference /
              _PeintreSignature.hauteurReference,
          child: AnimatedBuilder(
            animation: Listenable.merge([feuille, signature, sceau, effacement]),
            builder: (context, _) => CustomPaint(
              painter: _PeintreSignature(
                trait: AppColor.kGrayscaleDark100,
                fond: AppColor.kWhite,
                accent: AppColor.kSucces,
                avanceeFeuille: feuille.value,
                avanceeSignature: signature.value,
                avanceeSceau: sceau.value,
                opaciteEncre: 1 - effacement.value,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PeintreSignature extends CustomPainter {
  /// Repère de dessin : toutes les coordonnées ci-dessous sont exprimées dans
  /// cette grille, puis mises à l'échelle de la taille réelle du widget.
  static const double largeurReference = 320;
  static const double hauteurReference = 250;

  final Color trait;
  final Color fond;
  final Color accent;

  /// Avancées respectives des trois temps du dessin, entre 0 et 1.
  final double avanceeFeuille;
  final double avanceeSignature;
  final double avanceeSceau;

  /// Opacité de ce que la plume dépose — paraphe et sceau. Descend à 0 en fin
  /// de cycle : l'encre s'efface, et le cycle suivant repart d'une page nette.
  /// La feuille et son contenu imprimé, eux, ne bougent pas.
  final double opaciteEncre;

  const _PeintreSignature({
    required this.trait,
    required this.fond,
    required this.accent,
    required this.avanceeFeuille,
    required this.avanceeSignature,
    required this.avanceeSceau,
    required this.opaciteEncre,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final e = size.width / largeurReference; // facteur d'échelle

    Rect r(double x, double y, double l, double h) =>
        Rect.fromLTWH(x * e, y * e, l * e, h * e);
    Offset p(double x, double y) => Offset(x * e, y * e);

    final contour = Paint()
      ..color = trait
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6 * e
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    final plein = Paint()
      ..color = trait
      ..style = PaintingStyle.fill;

    final blanc = Paint()
      ..color = fond
      ..style = PaintingStyle.fill;

    /// Feuille à coin supérieur droit replié.
    Path feuille(
            double gauche, double haut, double droite, double bas, double pli) =>
        Path()
          ..moveTo(gauche * e, haut * e)
          ..lineTo((droite - pli) * e, haut * e)
          ..lineTo(droite * e, (haut + pli) * e)
          ..lineTo(droite * e, bas * e)
          ..lineTo(gauche * e, bas * e)
          ..close();

    // ── Ombre portée douce, pour poser la composition ──────────────────────
    canvas.drawOval(
      r(72, 216, 176, 18),
      Paint()..color = trait.withValues(alpha: 0.07 * avanceeFeuille),
    );

    // ── Feuille du dessous, légèrement pivotée ─────────────────────────────
    // C'est elle qui donne l'impression d'un dossier plutôt que d'une page
    // isolée. Son bord reste caché derrière la feuille principale, remplie en
    // blanc. Elle se redresse à mesure que le dessin arrive : le mouvement
    // évoque une pile que l'on vient de poser.
    canvas.save();
    canvas.translate(160 * e, 120 * e);
    canvas.rotate(-0.075 * avanceeFeuille);
    canvas.translate(-160 * e, -120 * e);
    final feuilleArriere = feuille(74, 30, 236, 196, 18);
    canvas.drawPath(feuilleArriere, blanc);
    canvas.drawPath(feuilleArriere, contour);
    canvas.restore();

    // ── Feuille principale ─────────────────────────────────────────────────
    const gauche = 86.0, haut = 22.0, droite = 250.0, bas = 208.0, pli = 30.0;
    final feuillePrincipale = feuille(gauche, haut, droite, bas, pli);
    canvas.drawPath(feuillePrincipale, blanc);
    canvas.drawPath(feuillePrincipale, contour);

    // Le rabat du coin plié.
    canvas.drawPath(
      Path()
        ..moveTo((droite - pli) * e, haut * e)
        ..lineTo((droite - pli) * e, (haut + pli) * e)
        ..lineTo(droite * e, (haut + pli) * e),
      contour,
    );

    // ── En-tête du document : un titre appuyé, puis son sous-titre ─────────
    canvas.drawRRect(
      RRect.fromRectAndRadius(r(106, 52, 76, 9), Radius.circular(4.5 * e)),
      plein,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(r(106, 68, 46, 6), Radius.circular(3 * e)),
      Paint()..color = trait.withValues(alpha: 0.28),
    );

    // ── Corps du texte, de longueurs inégales comme sur un vrai document ───
    final ligne = Paint()
      ..color = trait.withValues(alpha: 0.16)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 5.4 * e
      ..strokeCap = StrokeCap.round;

    void tracerLigne(double y, double xFin) {
      canvas.drawLine(p(106, y), Offset(xFin * e, y * e), ligne);
    }

    tracerLigne(96, 230);
    tracerLigne(112, 230);
    tracerLigne(128, 206);

    // ── Zone de signature ──────────────────────────────────────────────────
    // Un cartouche discret : c'est l'endroit du document que l'application
    // remplit, autant le montrer comme tel.
    canvas.drawRRect(
      RRect.fromRectAndRadius(r(104, 146, 132, 46), Radius.circular(9 * e)),
      Paint()
        ..color = trait.withValues(alpha: 0.045)
        ..style = PaintingStyle.fill,
    );

    // Ligne de signature.
    canvas.drawLine(
      p(116, 180),
      p(224, 180),
      Paint()
        ..color = trait.withValues(alpha: 0.30)
        ..strokeWidth = 1.6 * e
        ..strokeCap = StrokeCap.round,
    );

    // ── La signature, tracée progressivement ───────────────────────────────
    // Le paraphe est décrit une fois, puis extrait partiellement grâce aux
    // métriques du chemin : c'est ce qui donne l'impression d'une main qui
    // écrit, plutôt que d'un dessin qui apparaît en fondu.
    if (avanceeSignature > 0) {
      final paraphe = Path()
        ..moveTo(120 * e, 176 * e)
        ..cubicTo(130 * e, 148 * e, 138 * e, 186 * e, 148 * e, 166 * e)
        ..cubicTo(156 * e, 150 * e, 160 * e, 184 * e, 170 * e, 168 * e)
        ..cubicTo(178 * e, 154 * e, 184 * e, 180 * e, 196 * e, 162 * e)
        ..cubicTo(203 * e, 151 * e, 206 * e, 172 * e, 220 * e, 158 * e);

      final encre = Paint()
        ..color = trait.withValues(alpha: opaciteEncre.clamp(0.0, 1.0))
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.1 * e
        ..strokeJoin = StrokeJoin.round
        ..strokeCap = StrokeCap.round;

      for (final mesure in paraphe.computeMetrics()) {
        canvas.drawPath(
          mesure.extractPath(0, mesure.length * avanceeSignature.clamp(0.0, 1.0)),
          encre,
        );
      }
    }

    // ── Sceau de validation ────────────────────────────────────────────────
    // Seule touche de couleur de l'écran, posée en dernier : le document est
    // signé. C'est le geste que l'application fait faire, et le seul élément
    // qui méritait de sortir du noir et blanc.
    if (avanceeSceau > 0) {
      final avancee = avanceeSceau.clamp(0.0, 1.2);
      final opacite = opaciteEncre.clamp(0.0, 1.0);
      final centre = p(238, 196);
      final rayon = 25.0 * e * avancee;

      // Halo : détache la pastille du bord de la feuille. Il s'efface avec
      // elle, sans quoi un disque blanc resterait sur la page en fin de cycle.
      canvas.drawCircle(
          centre, rayon + 7 * e, Paint()..color = fond.withValues(alpha: opacite));
      canvas.drawCircle(
        centre,
        rayon + 7 * e,
        Paint()
          ..color = accent.withValues(alpha: 0.10 * avancee.clamp(0.0, 1.0) * opacite)
          ..style = PaintingStyle.fill,
      );
      canvas.drawCircle(
          centre, rayon, Paint()..color = accent.withValues(alpha: opacite));

      // La coche se trace elle aussi, juste après l'arrivée de la pastille.
      final avanceeCoche = ((avanceeSceau - 0.35) / 0.65).clamp(0.0, 1.0);
      if (avanceeCoche > 0) {
        final coche = Path()
          ..moveTo(centre.dx - 10 * e, centre.dy)
          ..lineTo(centre.dx - 3 * e, centre.dy + 7 * e)
          ..lineTo(centre.dx + 10.5 * e, centre.dy - 7.5 * e);

        final craie = Paint()
          ..color = fond.withValues(alpha: opacite)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.4 * e
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round;

        for (final mesure in coche.computeMetrics()) {
          canvas.drawPath(
            mesure.extractPath(0, mesure.length * avanceeCoche),
            craie,
          );
        }
      }
    }

    // ── Trombone, en haut à gauche ─────────────────────────────────────────
    // Le détail qui dit « pièce jointe » sans avoir à l'écrire, et qui équilibre
    // la composition face au sceau, en diagonale.
    final metal = Paint()
      ..color = trait
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4 * e
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;

    canvas.save();
    canvas.translate(64 * e, 96 * e);
    canvas.rotate(-math.pi / 9);
    canvas.drawPath(
      Path()
        ..moveTo(0, 6 * e)
        ..lineTo(0, 34 * e)
        ..arcToPoint(Offset(18 * e, 34 * e),
            radius: Radius.circular(9 * e), clockwise: true)
        ..lineTo(18 * e, 10 * e)
        ..arcToPoint(Offset(6 * e, 10 * e),
            radius: Radius.circular(6 * e), clockwise: false)
        ..lineTo(6 * e, 32 * e),
      metal,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PeintreSignature ancien) =>
      ancien.trait != trait ||
      ancien.fond != fond ||
      ancien.accent != accent ||
      ancien.avanceeFeuille != avanceeFeuille ||
      ancien.avanceeSignature != avanceeSignature ||
      ancien.avanceeSceau != avanceeSceau ||
      ancien.opaciteEncre != opaciteEncre;
}
