import 'package:flutter/material.dart';

enum ContratType {
  prestation,
  partenariat,
  location,
  reconnaissanceDette,
  procuration,
  caution,
  confidentialite,
}

extension ContratTypeX on ContratType {
  /// Valeur envoyée à l'API et présente dans les réponses backend.
  String get apiValue {
    switch (this) {
      case ContratType.prestation:          return 'contrat-prestation';
      case ContratType.partenariat:         return 'contrat-partenariat';
      case ContratType.location:            return 'contrat-location';
      case ContratType.reconnaissanceDette: return 'reconnaissance-dette';
      case ContratType.procuration:         return 'procuration';
      case ContratType.caution:             return 'contrat-caution';
      case ContratType.confidentialite:     return 'contrat-confidentialite';
    }
  }

  String get label {
    switch (this) {
      case ContratType.prestation:          return 'Services & missions';
      case ContratType.partenariat:         return 'Accord de partenariat';
      case ContratType.location:            return 'Location de bien';
      case ContratType.reconnaissanceDette: return 'Reconnaissance de dette';
      case ContratType.procuration:         return 'Mandat & délégation';
      case ContratType.caution:             return 'Engagement de caution';
      case ContratType.confidentialite:     return 'Clause de confidentialité';
    }
  }

  String get seeLabel {
    switch (this) {
      case ContratType.prestation:          return 'Voir Contrat de Prestation';
      case ContratType.partenariat:         return 'Voir Contrat de Partenariat';
      case ContratType.location:            return 'Voir Contrat de Location';
      case ContratType.reconnaissanceDette: return 'Voir Reconnaissance de Dette';
      case ContratType.procuration:         return 'Voir Procuration';
      case ContratType.caution:             return 'Voir Contrat de Caution';
      case ContratType.confidentialite:     return "Voir Accord de Confidentialité";
    }
  }

  IconData get icon {
    switch (this) {
      case ContratType.prestation:          return Icons.handshake_outlined;
      case ContratType.partenariat:         return Icons.people_outline;
      case ContratType.location:            return Icons.directions_car_outlined;
      case ContratType.reconnaissanceDette: return Icons.receipt_long_outlined;
      case ContratType.procuration:         return Icons.gavel_outlined;
      case ContratType.caution:             return Icons.verified_user_outlined;
      case ContratType.confidentialite:     return Icons.lock_outline;
    }
  }

  /// Parse depuis une valeur API (insensible à la casse).
  /// Retourne null si la valeur est inconnue.
  static ContratType? fromString(String? raw) {
    if (raw == null) return null;
    for (final t in ContratType.values) {
      if (t.apiValue == raw.trim().toLowerCase()) return t;
    }
    return null;
  }
}
