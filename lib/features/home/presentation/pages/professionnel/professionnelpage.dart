import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_event.dart';
import 'package:sign_application/features/account/presentation/bloc/account_state.dart';
import 'package:sign_application/features/account/presentation/pages/profil_page.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/core/widgets/logout_dialog.dart';
import 'package:sign_application/features/dashboard/presentation/pages/accueil_professionnel_page.dart';
import 'package:sign_application/features/client/presentation/pages/listeclients_page.dart';
import 'package:sign_application/features/facture/presentation/pages/factures_page.dart';
import 'package:sign_application/features/contrat/presentation/pages/contrats_page.dart';
import 'package:sign_application/core/widgets/network_banner.dart';
import 'package:sign_application/core/services/fcm_service.dart';

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
      FcmService.init(context);
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
      HomeProfessionnelPage(user: widget.user),
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
          backgroundColor: Colors.white,
          appBar: AppBar(
            backgroundColor: Colors.black,
            titleSpacing: 12,
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
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(7),
                          ),
                        )
                      else
                        Text(
                          fullName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            color: Colors.white60,
                            fontSize: 11,
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
              // ── Icône de navigation vers la page de profil ────────────
              IconButton(
                tooltip: 'Mon profil',
                icon: const Icon(Icons.manage_accounts_outlined,
                    color: Colors.white, size: 26),
                onPressed: () {
                  final user = state is AccountLoaded
                      ? state.user
                      : state is AccountSuccess
                          ? state.user
                          : null;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => BlocProvider.value(
                        value: context.read<AccountBloc>(),
                        child: ProfilPage(user: user),
                      ),
                    ),
                  );
                },
              ),
              // ── Déconnexion ───────────────────────────────────────────
              IconButton(
                icon: const Icon(Icons.logout_rounded, color: Colors.white),
                onPressed: () => LogoutDialog.show(context),
                tooltip: 'Déconnexion',
              ),
            ],
          ),
          body: NetworkBanner(child: pages[_currentIndex]),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: _currentIndex,
            selectedItemColor: Colors.black,
            unselectedItemColor: Colors.grey,
            backgroundColor: Colors.white,
            type: BottomNavigationBarType.fixed,
            selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600),
            onTap: (index) => setState(() => _currentIndex = index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Clients',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.receipt_outlined),
                activeIcon: Icon(Icons.receipt),
                label: 'Factures',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.description_outlined),
                activeIcon: Icon(Icons.description),
                label: 'Contrats',
              ),
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
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white24,
        ),
      );
    }

    if (photoUrl != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: photoUrl,
          width: 36,
          height: 36,
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
      radius: 18,
      backgroundColor: Colors.white24,
      child: Text(
        initials,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.bold,
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
