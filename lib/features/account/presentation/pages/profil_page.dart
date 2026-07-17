import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sign_application/core/config/user_role.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/core/routes/app_router.dart';
import 'package:sign_application/features/account/domain/entities/account_user.dart';
import 'package:sign_application/features/account/presentation/bloc/account_bloc.dart';
import 'package:sign_application/features/account/presentation/bloc/account_event.dart';
import 'package:sign_application/features/account/presentation/bloc/account_state.dart';
import 'package:sign_application/features/account/presentation/pages/modifier_profil_page.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:sign_application/features/auth/presentation/bloc/auth_event.dart';

class ProfilPage extends StatefulWidget {
  final AccountUser? user;
  const ProfilPage({super.key, this.user});

  @override
  State<ProfilPage> createState() => _ProfilPageState();
}

class _ProfilPageState extends State<ProfilPage> {
  final Set<String> _expandedSections = {'Informations personnelles'};

  @override
  void initState() {
    super.initState();
    // Recharger si pas encore chargé
    final state = context.read<AccountBloc>().state;
    if (state is AccountInitial) {
      context.read<AccountBloc>().add(LoadMe());
    }
  }

  // Photos hébergées sur Cloudflare R2 → URL complète directement utilisable
  String? _buildUrl(String? path) {
    if (path == null || path.trim().isEmpty) return null;
    return path.trim();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      body: BlocListener<AccountBloc, AccountState>(
        listener: (context, state) {
          if (state is AccountDeleted) {
            context.read<AuthBloc>().add(LogoutRequested());
            Navigator.of(context).pushNamedAndRemoveUntil(
              AppRouter.loginRoute,
              (route) => false,
            );
          }
          if (state is AccountError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red[700],
              ),
            );
          }
        },
        child: BlocBuilder<AccountBloc, AccountState>(
          builder: (context, state) {
            if (state is AccountLoading) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.black87),
              );
            }

            AccountUser? user;
            if (state is AccountLoaded) user = state.user;
            if (state is AccountSuccess) user = state.user;
            user ??= widget.user;

            if (user == null) {
              return _buildError();
            }

            return _buildContent(user);
          },
        ),
      ),
    );
  }

  Widget _buildContent(AccountUser user) {
    final photoUrl = _buildUrl(user.photoProfil);
    final logoUrl = _buildUrl(user.logo);
    final signatureUrl = _buildUrl(user.signature);

    final role      = UserRoleX.fromString(user.role);
    final isPro       = role.isPro;
    final isEntreprise = role.isEntreprise;

    return CustomScrollView(
      slivers: [
        // ── AppBar avec grande photo ────────────────────────────────────────
        SliverAppBar(
          expandedHeight: 220,
          pinned: true,
          backgroundColor: Colors.black,
          iconTheme: const IconThemeData(color: Colors.white),
          actions: [
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: Colors.white),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => ModifierProfilPage(user: user),
                ),
              ),
              tooltip: 'Modifier',
            ),
            IconButton(
              icon: const Icon(Icons.refresh, color: Colors.white),
              onPressed: () => context.read<AccountBloc>().add(LoadMe()),
              tooltip: 'Actualiser',
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Fond dégradé
                Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1a1a1a), Color(0xFF3a3a3a)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                // Contenu centré : photo + nom
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 32),
                    // Photo de profil grande
                    _buildLargeAvatar(photoUrl, user),
                    const SizedBox(height: 14),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 2,
                        textAlign: TextAlign.center,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    _buildRoleBadge(user.role),
                  ],
                ),
              ],
            ),
          ),
        ),

        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Informations personnelles ──────────────────────────────
                _buildSection(
                  title: 'Informations personnelles',
                  icon: Icons.person_outline,
                  children: [
                    _buildInfoRow(Icons.badge_outlined, 'Prénom', user.prenom),
                    _buildInfoRow(Icons.badge_outlined, 'Nom', user.nom),
                    _buildInfoRow(Icons.email_outlined, 'Email', user.email),
                    _buildInfoRow(Icons.phone_outlined, 'Téléphone', user.telephone),
                    _buildInfoRow(Icons.location_on_outlined, 'Adresse', user.adresse),
                    _buildInfoRow(
                      Icons.credit_card_outlined,
                      'N° CIN',
                      user.carteIdentiteNationalNum,
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ── Informations pro (Professionnel ET Indépendant) ────────
                if (isPro) ...[
                  _buildSection(
                    title: isEntreprise
                        ? 'Informations entreprise'
                        : 'Informations professionnelles',
                    icon: isEntreprise
                        ? Icons.business_outlined
                        : Icons.work_outline,
                    children: [
                      _buildInfoRow(
                          Icons.store_outlined, 'Raison sociale', user.nomEntreprise),
                      _buildInfoRow(
                          Icons.location_city_outlined,
                          'Adresse pro',
                          user.adresseEntreprise),
                      _buildInfoRow(
                          Icons.phone_in_talk_outlined,
                          'Tél. professionnel',
                          user.telephoneEntreprise),
                      _buildInfoRow(
                          Icons.alternate_email,
                          'Email professionnel',
                          user.emailEntreprise),
                      // RC et NINEA uniquement pour les Professionnels (entreprise)
                      if (isEntreprise) ...[
                        _buildInfoRow(
                            Icons.tag_outlined, 'NINEA', user.ninea),
                        _buildInfoRow(
                            Icons.numbers_outlined, 'RC', user.rc),
                      ],
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Logo (si pro) ──────────────────────────────────────────
                if (isPro && logoUrl != null) ...[
                  _buildSection(
                    title: 'Logo',
                    icon: Icons.image_outlined,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: CachedNetworkImage(
                          imageUrl: logoUrl,
                          height: 80,
                          fit: BoxFit.contain,
                          errorWidget: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Signature ──────────────────────────────────────────────
                if (signatureUrl != null) ...[
                  _buildSection(
                    title: 'Signature',
                    icon: Icons.draw_outlined,
                    children: [
                      Container(
                        width: double.infinity,
                        height: 100,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[200]!),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: CachedNetworkImage(
                            imageUrl: signatureUrl,
                            fit: BoxFit.contain,
                            errorWidget: (_, __, ___) => Center(
                              child: Text('Signature non disponible',
                                  style: TextStyle(color: Colors.grey[400])),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],

                // ── Statut du compte ───────────────────────────────────────
                _buildSection(
                  title: 'Compte',
                  icon: Icons.security_outlined,
                  children: [
                    _buildStatusRow(user.statut),
                    _buildInfoRow(Icons.manage_accounts_outlined, 'Rôle', user.role),
                  ],
                ),

                const SizedBox(height: 32),

                // ── Politique de confidentialité ──────────────────────────
                _buildPrivacyPolicyButton(),

                const SizedBox(height: 12),

                // ── Supprimer le compte (exigence Google Play) ─────────────
                _buildDeleteAccountButton(),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrivacyPolicyButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () => Navigator.of(context).pushNamed(AppRouter.politiqueConfRoute),
        icon: const Icon(Icons.privacy_tip_outlined, color: Colors.black87),
        label: const Text(
          'Politique de confidentialité',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.w600,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        ),
      ),
    );
  }

  Widget _buildDeleteAccountButton() {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextButton.icon(
        onPressed: () => _confirmDeleteAccount(),
        icon: const Icon(Icons.delete_forever_outlined, color: Colors.red),
        label: const Text(
          'Supprimer mon compte',
          style: TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 18),
          alignment: Alignment.centerLeft,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
          ),
        ),
      ),
    );
  }

  Future<void> _confirmDeleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Supprimer le compte',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
        ),
        content: const Text(
          'Cette action est irréversible. Toutes vos données (contrats, documents, signatures) seront définitivement supprimées.\n\nÊtes-vous sûr de vouloir continuer ?',
          style: TextStyle(fontSize: 14, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Annuler',
                style: TextStyle(color: Colors.black54, fontWeight: FontWeight.w600)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Supprimer',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      context.read<AccountBloc>().add(DeleteAccountEvent());
    }
  }

  // ── Grande photo de profil ─────────────────────────────────────────────────
  Widget _buildLargeAvatar(String? photoUrl, AccountUser user) {
    const double size = 86;
    final initials = _getInitials(user.prenom, user.nom);

    if (photoUrl != null) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white, width: 3),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4)),
          ],
        ),
        child: ClipOval(
          child: CachedNetworkImage(
            imageUrl: photoUrl,
            width: size,
            height: size,
            fit: BoxFit.cover,
            placeholder: (_, __) => _defaultAvatar(initials, size),
            errorWidget: (_, __, ___) => _defaultAvatar(initials, size),
          ),
        ),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.24),
        border: Border.all(color: Colors.white, width: 3),
      ),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _defaultAvatar(String initials, double size) {
    return Container(
      width: size,
      height: size,
      color: Colors.white.withValues(alpha: 0.24),
      child: Center(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            initials,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // ── Badge de rôle ─────────────────────────────────────────────────────────
  Widget _buildRoleBadge(String? role) {
    if (role == null || role.isEmpty) return const SizedBox.shrink();

    final r = UserRoleX.fromString(role);
    final label = r == UserRole.unknown ? role : r.label;
    final badgeColor = r.badgeColor;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
      decoration: BoxDecoration(
        color: badgeColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (r != UserRole.unknown) ...[
          Icon(r.icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
        ],
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ]),
    );
  }

  // ── Section card (accordion) ──────────────────────────────────────────────
  Widget _buildSection({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final nonEmpty = children
        .where((w) => w is! SizedBox || (w).height != 0)
        .toList();
    if (nonEmpty.isEmpty) return const SizedBox.shrink();

    final isExpanded = _expandedSections.contains(title);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // En-tête cliquable
          GestureDetector(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  _expandedSections.remove(title);
                } else {
                  _expandedSections.add(title);
                }
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: isExpanded ? 0 : -0.25,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: Colors.grey.shade400,
                      size: 22,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (isExpanded) ...[
            Divider(color: Colors.grey[100], height: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              child: Column(children: nonEmpty),
            ),
          ],
        ],
      ),
    );
  }

  // ── Ligne d'info ──────────────────────────────────────────────────────────
  Widget _buildInfoRow(IconData icon, String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox(height: 0);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey[500]),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[400],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Ligne de statut avec badge coloré ────────────────────────────────────
  Widget _buildStatusRow(String? statut) {
    final isActif = statut == null || statut == 'actif';
    final label = isActif ? 'Actif' : statut;
    final color = isActif ? Colors.green : Colors.orange;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Icon(Icons.circle, size: 10, color: color),
          const SizedBox(width: 10),
          Text(
            'Statut du compte',
            style: TextStyle(
              fontSize: 11,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Écran d'erreur ────────────────────────────────────────────────────────
  Widget _buildError() {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_off_outlined, size: 60, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text('Impossible de charger le profil',
                style: TextStyle(color: Colors.grey[500], fontSize: 16)),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.read<AccountBloc>().add(LoadMe()),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.black),
              child: const Text('Réessayer',
                  style: TextStyle(color: Colors.white)),
            ),
          ],
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
