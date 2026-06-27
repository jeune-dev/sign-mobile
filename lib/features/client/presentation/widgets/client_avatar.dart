import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Avatar d'un client : photo Cloudinary si disponible, sinon initiales colorées
Widget buildClientAvatar(
  Map<String, dynamic> client, {
  double radius = 24,
  int colorIndex = 0,
}) {
  final String? photoUrl = client['photoProfil']?.toString();
  final String prenom = client['prenom']?.toString() ?? '';
  final String nom = client['nom']?.toString() ?? '';
  final String initiale =
      (prenom.isNotEmpty ? prenom[0] : (nom.isNotEmpty ? nom[0] : '?'))
          .toUpperCase();

  // Palette de couleurs pour les avatars sans photo
  final List<Color> palette = [
    const Color(0xFF6C63FF),
    const Color(0xFF00C896),
    const Color(0xFFFF6B6B),
    const Color(0xFFFFB347),
    const Color(0xFF4ECDC4),
    const Color(0xFF45B7D1),
  ];
  final bg = palette[colorIndex % palette.length];

  if (photoUrl != null && photoUrl.isNotEmpty) {
    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: photoUrl,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => _initialeAvatar(initiale, radius, bg),
        errorWidget: (_, __, ___) => _initialeAvatar(initiale, radius, bg),
      ),
    );
  }

  return _initialeAvatar(initiale, radius, bg);
}

Widget _initialeAvatar(String initiale, double radius, Color bg) {
  return CircleAvatar(
    radius: radius,
    backgroundColor: bg.withValues(alpha: 0.15),
    child: Text(
      initiale,
      style: TextStyle(
        fontWeight: FontWeight.bold,
        color: bg,
        fontSize: radius * 0.75,
      ),
    ),
  );
}
