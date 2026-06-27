import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:sign_application/core/widgets/empty_state.dart';
import 'package:sign_application/core/widgets/shimmer_list.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sign_application/features/auth/domain/entities/user.dart';
import 'package:sign_application/features/client/domain/entities/client.dart';
import 'package:sign_application/features/client/presentation/bloc/client_bloc.dart';
import 'package:sign_application/features/client/presentation/bloc/client_event.dart';
import 'package:sign_application/features/client/presentation/bloc/client_state.dart';

class ClientsPage extends StatefulWidget {
  final User? user;
  const ClientsPage({super.key, this.user});

  @override
  State<ClientsPage> createState() => _ClientsPageState();
}

class _ClientsPageState extends State<ClientsPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  List<Client> _filtered = [];
  List<Client> _all = [];

  @override
  void initState() {
    super.initState();
    context.read<ClientBloc>().add(LoadClients());
    _searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    final query = _searchCtrl.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filtered = _all;
      } else {
        _filtered = _all.where((c) {
          return '${c.prenom} ${c.nom}'.toLowerCase().contains(query) ||
              (c.email?.toLowerCase().contains(query) ?? false) ||
              (c.telephone?.contains(query) ?? false);
        }).toList();
      }
    });
  }

  // ── Palette couleurs par index ─────────────────────────────────────────────
  static const List<Color> _palette = [
    Color(0xFF6C63FF),
    Color(0xFF00C896),
    Color(0xFFFF6B6B),
    Color(0xFFFFB347),
    Color(0xFF4ECDC4),
    Color(0xFF45B7D1),
  ];

  Color _colorFor(int index) => _palette[index % _palette.length];

  // ── Sheet de détail client ────────────────────────────────────────────────
  void _showClientDetails(BuildContext context, Client client, int index) {
    final color = _colorFor(index);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ClientDetailSheet(
        client: client,
        color: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ClientBloc, ClientState>(
      listener: (context, state) {
        if (state is ClientsLoaded) {
          setState(() {
            _all = state.clients;
            _filtered = _all;
            _onSearch(); // réappliquer filtre si recherche active
          });
        }
      },
      child: BlocBuilder<ClientBloc, ClientState>(
        builder: (context, state) {
          final isLoading = state is ClientLoading;
          final total = state is ClientsLoaded ? state.total : 0;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ─────────────────────────────────────────────────
              _buildHeader(total, isLoading, state),

              // ── Barre de recherche ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                child: _buildSearchBar(),
              ),

              // ── Contenu ────────────────────────────────────────────────
              Expanded(child: _buildContent(state, isLoading)),
            ],
          );
        },
      ),
    );
  }

  // ── Header avec stats ──────────────────────────────────────────────────────
  Widget _buildHeader(int total, bool isLoading, ClientState state) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 20, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1a1a1a), Color(0xFF2d2d2d)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          // Icône
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.people_rounded,
                color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          // Textes
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Liste de mes clients',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
              ],
            ),
          ),
          // Bouton actualiser
          GestureDetector(
            onTap: isLoading
                ? null
                : () => context.read<ClientBloc>().add(LoadClients()),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: isLoading ? 0.05 : 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            color: Colors.white54, strokeWidth: 2),
                      ),
                    )
                  : const Icon(Icons.refresh_rounded,
                      color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  // ── Barre de recherche ─────────────────────────────────────────────────────
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: TextField(
        controller: _searchCtrl,
        style: const TextStyle(fontSize: 14, color: Colors.black87),
        decoration: InputDecoration(
          hintText: 'Rechercher un client…',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
          prefixIcon: Icon(Icons.search, color: Colors.grey[400], size: 20),
          suffixIcon: _searchCtrl.text.isNotEmpty
              ? GestureDetector(
                  onTap: () {
                    _searchCtrl.clear();
                    _onSearch();
                  },
                  child: Icon(Icons.clear, color: Colors.grey[400], size: 18),
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  // ── Contenu principal ──────────────────────────────────────────────────────
  Widget _buildContent(ClientState state, bool isLoading) {
    if (isLoading && _all.isEmpty) {
      return const ShimmerList(padding: EdgeInsets.fromLTRB(16, 0, 16, 24));
    }

    if (state is ClientError && _all.isEmpty) {
      return _buildError(state.message);
    }

    if (_filtered.isEmpty) {
      return _buildEmpty();
    }

    return RefreshIndicator(
      color: Colors.black87,
      onRefresh: () async => context.read<ClientBloc>().add(LoadClients()),
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: _filtered.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) =>
            _buildClientCard(_filtered[index], index),
      ),
    );
  }

  // ── Carte client ───────────────────────────────────────────────────────────
  Widget _buildClientCard(Client client, int index) {
    final color = _colorFor(index);
    final hasPhoto =
        client.photoProfil != null && client.photoProfil!.isNotEmpty;

    return GestureDetector(
      onTap: () => _showClientDetails(context, client, index),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // ── Avatar / Photo ───────────────────────────────────────
              _buildAvatar(client, hasPhoto, color, index),
              const SizedBox(width: 14),

              // ── Infos ────────────────────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${client.prenom} ${client.nom}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                        color: Colors.black87,
                        letterSpacing: -0.2,
                      ),
                    ),
                    if (client.email != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.email_outlined,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              client.email!,
                              style: TextStyle(
                                  fontSize: 12, color: Colors.grey[500]),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (client.telephone != null) ...[
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined,
                              size: 12, color: Colors.grey[400]),
                          const SizedBox(width: 4),
                          Text(
                            client.telephone!,
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey[500]),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // ── Bouton Voir ──────────────────────────────────────────
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  'Voir',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Avatar ─────────────────────────────────────────────────────────────────
  Widget _buildAvatar(
      Client client, bool hasPhoto, Color color, int index) {
    const double size = 52;

    if (hasPhoto) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: CachedNetworkImage(
          imageUrl: client.photoProfil!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, __) => _initialeBox(client, size, color),
          errorWidget: (_, __, ___) => _initialeBox(client, size, color),
        ),
      );
    }

    return _initialeBox(client, size, color);
  }

  Widget _initialeBox(Client client, double size, Color color) {
    final initiale =
        client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?';
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Text(
          initiale,
          style: TextStyle(
            color: color,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }

  // ── État vide ──────────────────────────────────────────────────────────────
  Widget _buildEmpty() {
    final isSearching = _searchCtrl.text.isNotEmpty;
    return EmptyState(
      icon: isSearching ? Icons.search_off_rounded : Icons.people_outline_rounded,
      title: isSearching ? 'Aucun résultat' : 'Aucun client',
      subtitle: isSearching
          ? 'Essayez un autre terme de recherche'
          : 'Ajoutez votre premier client pour commencer',
      scrollable: false,
    );
  }

  // ── État erreur ────────────────────────────────────────────────────────────
  Widget _buildError(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration:
                BoxDecoration(color: Colors.red[50], shape: BoxShape.circle),
            child: Icon(Icons.error_outline, color: Colors.red[300], size: 32),
          ),
          const SizedBox(height: 14),
          const Text('Impossible de charger',
              style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
          const SizedBox(height: 4),
          Text(message,
              style: const TextStyle(color: Colors.grey, fontSize: 12),
              textAlign: TextAlign.center),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () => context.read<ClientBloc>().add(LoadClients()),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text('Réessayer',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Bottom Sheet de détail client
// ─────────────────────────────────────────────────────────────────────────────
class _ClientDetailSheet extends StatelessWidget {
  final Client client;
  final Color color;

  const _ClientDetailSheet({required this.client, required this.color});

  @override
  Widget build(BuildContext context) {
    final hasPhoto =
        client.photoProfil != null && client.photoProfil!.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          const SizedBox(height: 24),

          // ── Avatar grand format ───────────────────────────────────────
          if (hasPhoto)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: CachedNetworkImage(
                imageUrl: client.photoProfil!,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                placeholder: (_, __) => _bigInitiale(client, color),
                errorWidget: (_, __, ___) => _bigInitiale(client, color),
              ),
            )
          else
            _bigInitiale(client, color),

          const SizedBox(height: 14),

          // Nom
          Text(
            '${client.prenom} ${client.nom}',
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
              letterSpacing: -0.3,
            ),
          ),

          // Badge statut
          if (client.statut != null) ...[
            const SizedBox(height: 6),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
              ),
              child: Text(
                client.statut!,
                style: const TextStyle(
                    color: Colors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ),
          ],

          const SizedBox(height: 24),

          // ── Infos ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                if (client.email != null)
                  _infoRow(Icons.email_outlined, 'Email', client.email!, color),
                if (client.telephone != null)
                  _infoRow(Icons.phone_outlined, 'Téléphone',
                      client.telephone!, color),
                if (client.adresse != null)
                  _infoRow(Icons.location_on_outlined, 'Adresse',
                      client.adresse!, color),

              ],
            ),
          ),

          const SizedBox(height: 24),

          // ── Bouton Fermer ─────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: SafeArea(
              top: false,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: const Text('Fermer',
                      style: TextStyle(
                          fontWeight: FontWeight.w700, fontSize: 15)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _bigInitiale(Client client, Color color) {
    final initiale =
        client.prenom.isNotEmpty ? client.prenom[0].toUpperCase() : '?';
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Center(
        child: Text(
          initiale,
          style: TextStyle(
              color: color, fontSize: 34, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value, Color color) {
    if (value.trim().isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
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
                      fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

}
