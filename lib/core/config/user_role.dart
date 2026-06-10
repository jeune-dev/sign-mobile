import 'package:flutter/material.dart';

enum UserRole { particulier, professionnel, independant, admin, unknown }

extension UserRoleX on UserRole {
  /// Parse depuis la chaîne stockée côté backend/storage (insensible à la casse).
  static UserRole fromString(String? raw) {
    switch (raw?.toLowerCase().trim()) {
      case 'particulier':
      case 'client':
        return UserRole.particulier;
      case 'professionnel':
        return UserRole.professionnel;
      case 'independant':
      case 'indépendant':
        return UserRole.independant;
      case 'admin':
        return UserRole.admin;
      default:
        return UserRole.unknown;
    }
  }

  bool get isPro => this == UserRole.professionnel || this == UserRole.independant;
  bool get isEntreprise => this == UserRole.professionnel;
  bool get isClient => this == UserRole.particulier;

  String get label {
    switch (this) {
      case UserRole.professionnel: return '🏢 Professionnel';
      case UserRole.independant:   return '💼 Indépendant';
      case UserRole.particulier:   return '👤 Particulier';
      case UserRole.admin:         return '⚙️ Admin';
      case UserRole.unknown:       return 'Inconnu';
    }
  }

  Color get badgeColor {
    switch (this) {
      case UserRole.professionnel: return Colors.blue.withValues(alpha: 0.25);
      case UserRole.independant:   return Colors.orange.withValues(alpha: 0.25);
      case UserRole.particulier:   return Colors.green.withValues(alpha: 0.20);
      default:                     return Colors.white.withValues(alpha: 0.15);
    }
  }
}
