import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import '../../../../account/presentation/pages/profil_page.dart';
import '../../../../particulier/presentation/bloc/particulier_bloc.dart';
import '../../../../particulier/presentation/pages/dashboard_client_page.dart';
import '../../../../particulier/presentation/pages/factures_client_page.dart';
import '../../../../particulier/presentation/pages/contrats_client_page.dart';
import 'package:sign_application/core/widgets/network_banner.dart';
import 'package:sign_application/core/services/fcm_service.dart';
import 'package:sign_application/features/notifications/presentation/cloche_notifications.dart';
import 'package:sign_application/core/widgets/barre_navigation_flottante.dart';
import 'package:flutter/services.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/features/parcours/data/suivi_profil_service.dart';
import 'package:sign_application/injection_container.dart';

class ClientPage extends StatefulWidget {
  final User? user;
  final int initialTabIndex;

  const ClientPage({super.key, this.user, this.initialTabIndex = 0});

  @override
  State<ClientPage> createState() => _ClientPageState();
}

class _ClientPageState extends State<ClientPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.init();
      // Ce qu'il reste a completer conditionne la pastille de l'onglet
      // Profil : on le demande a l'ouverture, pas au moment ou l'utilisateur
      // arrive sur le profil — il faut precisement l'y amener.
      sl<SuiviProfilService>().rafraichir();
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ParticulierBloc>(
      create: (_) => GetIt.instance<ParticulierBloc>(),
      child: Builder(
        builder: (ctx) {
          final List<Widget> pages = [
            DashboardClientPage(user: widget.user),
            const FacturesClientPage(),
            const ContratsClientPage(),
            const ProfilPage(),
          ];

          return Scaffold(
            backgroundColor: AppColor.kFond,
            // En-tete clair : le bandeau noir ecrasait le haut de l'ecran et
            // isolait l'identite du reste de la page.
            appBar: AppBar(
              backgroundColor: AppColor.kSurface,
              surfaceTintColor: AppColor.kSurface,
              elevation: 0,
              scrolledUnderElevation: 0,
              systemOverlayStyle: SystemUiOverlayStyle.dark,
              toolbarHeight: 72,
              titleSpacing: 16,
              title: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${widget.user?.prenom ?? ''} ${widget.user?.nom ?? ''}'.trim(),
                    style: const TextStyle(
                      color: AppColor.kTexte,
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.3,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if ((widget.user?.email ?? '').isNotEmpty)
                    Text(
                      widget.user!.email,
                      style: const TextStyle(
                        color: AppColor.kTexteMoyen,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
              actions: const [
                // La déconnexion vivait ici, à portée de pouce d'un geste de
                // retour : elle a rejoint le bas de la page de profil, là où
                // on la cherche. La cloche prend sa place.
                ClocheNotifications(couleur: AppColor.kTexte),
                SizedBox(width: 8),
              ],
            ),
            body: NetworkBanner(
              child: IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ),
            // La pastille de l'onglet Profil suit l'etat du dossier : elle
            // s'allume tant qu'une information ou une piece manque, et
            // s'eteint d'elle-meme des que tout est depose.
            bottomNavigationBar: AnimatedBuilder(
              animation: sl<SuiviProfilService>(),
              builder: (context, _) {
                final aCompleter =
                    sl<SuiviProfilService>().etat?.aQuelqueChoseACompleter ?? false;
                return BarreNavigationFlottante(
                  indexCourant: _currentIndex,
                  onChange: (i) => setState(() => _currentIndex = i),
                  onglets: [
                    const OngletNavigation(
                        Icons.home_outlined, Icons.home_rounded, 'Accueil'),
                    const OngletNavigation(Icons.receipt_long_outlined,
                        Icons.receipt_long_rounded, 'Factures'),
                    const OngletNavigation(Icons.description_outlined,
                        Icons.description_rounded, 'Contrats'),
                    OngletNavigation(
                      Icons.person_outline,
                      Icons.person_rounded,
                      'Profil',
                      pastille: aCompleter,
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }
}
