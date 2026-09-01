import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_event.dart';
import 'package:sign_application/features/account/presentation/bloc/account_state.dart';
import 'package:sign_application/features/account/presentation/pages/profil_page.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/dashboard/presentation/pages/accueil_professionnel_page.dart';
import 'package:sign_application/features/client/presentation/pages/listeclients_page.dart';
import 'package:sign_application/features/facture/presentation/pages/factures_page.dart';
import 'package:sign_application/features/contrat/presentation/pages/contrats_page.dart';
import 'package:sign_application/core/widgets/network_banner.dart';
import 'package:sign_application/core/services/fcm_service.dart';
import 'package:sign_application/features/notifications/presentation/cloche_notifications.dart';
import 'package:flutter/services.dart';
import 'package:sign_application/core/theme/app_color.dart';
import 'package:sign_application/core/widgets/barre_navigation_flottante.dart';
import 'package:sign_application/features/parcours/data/suivi_profil_service.dart';
import 'package:sign_application/features/parcours/presentation/widgets/pastille_profil.dart';
import 'package:sign_application/injection_container.dart';

class ProfessionnelPage extends StatefulWidget {
  final User? user;
  final int initialTabIndex;
  const ProfessionnelPage({super.key, this.user, this.initialTabIndex = 0});

  @override
  State<ProfessionnelPage> createState() => _ProfessionnelPageState();
}

class _ProfessionnelPageState extends State<ProfessionnelPage> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialTabIndex;
    context.read<AccountBloc>().add(LoadMe());
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FcmService.init();
      // Alimente la pastille du bouton de reglage : ce qui reste a saisir ou
      // a deposer pour que le compte soit complet.
      sl<SuiviProfilService>().rafraichir();
    });
  }

  // ─── URL de la photo — Cloudinary retourne déjà une URL complète ──────────
  String? _buildPhotoUrl(String? photoProfil) {
    if (photoProfil == null || photoProfil.trim().isEmpty) return null;
    return photoProfil.trim();
  }


  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      HomeProfessionnelPage(
        user: widget.user,
        onVoirContrats: () => setState(() => _currentIndex = 3),
      ),
      ClientsPage(user: widget.user),
      FacturesPage(user: widget.user),
      ContratsPage(user: widget.user),
    ];

    return BlocBuilder<AccountBloc, AccountState>(
      builder: (context, state) {
        String fullName = 'Professionnel';
        String email = '';
        String? photoProfil;

        if (state is AccountLoaded) {
          fullName = state.user.fullName;
          email = state.user.email ?? '';
          photoProfil = _buildPhotoUrl(state.user.photoProfil);
        } else if (state is AccountSuccess) {
          fullName = state.user.fullName;
          email = state.user.email ?? '';
          photoProfil = _buildPhotoUrl(state.user.photoProfil);
        }

        return Scaffold(
          backgroundColor: AppColor.kFond,
          // En-tete clair : le bandeau noir ecrasait le haut de l'ecran et
          // isolait l'identite du reste de la page. Fondu dans le fond, il
          // laisse la place aux donnees.
          appBar: AppBar(
            backgroundColor: AppColor.kSurface,
            surfaceTintColor: AppColor.kSurface,
            elevation: 0,
            scrolledUnderElevation: 0,
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            toolbarHeight: 72,
            titleSpacing: 16,
            title: Row(
              children: [
                // ── Photo de profil à GAUCHE ──────────────────────────────
                _buildAppBarAvatar(state, photoProfil),
                const SizedBox(width: 12),
                // ── Nom + email ───────────────────────────────────────────
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (state is AccountLoading)
                        Container(
                          width: 120,
                          height: 14,
                          decoration: BoxDecoration(
                            color: AppColor.kNeutreClair,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        )
                      else
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: AppColor.kTexte,
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: AppColor.kTexteMoyen,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              // Cloche puis profil, comme sur la maquette. La déconnexion
              // occupait cette place : elle a rejoint le bas du profil.
              const ClocheNotifications(couleur: AppColor.kTexte),
              IconButton(
                tooltip: 'Mon profil',
                // Le point rouge dit que le profil attend encore quelque
                // chose : c'est ici, et nulle part ailleurs, que cela se
                // regle.
                icon: const PastilleProfil(
                  child: Icon(Icons.settings_outlined,
                      color: AppColor.kTexte, size: 24),
                ),
                onPressed: () async {
                  final user = state is AccountLoaded
                      ? state.user
                      : state is AccountSuccess
                          ? state.user
                          : null;
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AccountBloc>(),
                        child: ProfilPage(user: user),
                      ),
                    ),
                  );
                  // Au retour du profil, l'utilisateur a pu completer ou
                  // deposer : la pastille doit refleter l'etat reel.
                  await sl<SuiviProfilService>().rafraichir();
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: NetworkBanner(child: pages[_currentIndex]),
          bottomNavigationBar: BarreNavigationFlottante(
            indexCourant: _currentIndex,
            onChange: (i) => setState(() => _currentIndex = i),
            onglets: const [
              OngletNavigation(Icons.home_outlined, Icons.home_rounded, 'Accueil'),
              OngletNavigation(Icons.people_outline, Icons.people_rounded, 'Clients'),
              OngletNavigation(Icons.receipt_long_outlined, Icons.receipt_long_rounded, 'Factures'),
              OngletNavigation(Icons.description_outlined, Icons.description_rounded, 'Contrats'),
            ],
          ),
        );
      },
    );
  }

  // ── Avatar dans l'AppBar : photo réseau ou initiales ──────────────────────
  Widget _buildAppBarAvatar(AccountState state, String? photoUrl) {
    if (state is AccountLoading) {
      return Container(
        width: 44,
        height: 44,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: AppColor.kNeutreClair,
        ),
      );
    }

    if (photoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 44,
          height: 44,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialesAvatar(state),
          errorWidget: (_, __, ___) => _initialesAvatar(state),
        ),
      );
    }

    return _initialesAvatar(state);
  }

  Widget _initialesAvatar(AccountState state) {
    String initials = '?';
    if (state is AccountLoaded) {
      initials = _getInitials(state.user.prenom, state.user.nom);
    } else if (state is AccountSuccess) {
      initials = _getInitials(state.user.prenom, state.user.nom);
    }
    return CircleAvatar(
      radius: 22,
      backgroundColor: AppColor.kPrimary,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 15,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }

  String _getInitials(String? prenom, String? nom) {
    final p = (prenom?.isNotEmpty == true) ? prenom![0].toUpperCase() : '';
    final n = (nom?.isNotEmpty == true) ? nom![0].toUpperCase() : '';
    return '$p$n'.isEmpty ? '?' : '$p$n';
  }
}
