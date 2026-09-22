#!/bin/bash
# Build APK release avec obfuscation Dart complète
# Usage : bash build_release.sh
#
# Prérequis :
#   - android/key.properties configuré avec le keystore de production
#   - android/app/google-services.json présent
#   - Variables --dart-define définies ci-dessous (ou via CI/CD)

set -e

# URL de production unique. Doit rester alignee sur :
#   - le fallback de lib/core/config/env.dart
#   - le domaine de android/app/src/main/res/xml/network_security_config.xml
#   - les racines epinglees dans assets/certs/backend_ca.pem
API_BASE_URL="https://api.app-signs.com/sign"

echo "=== Nettoyage ==="
flutter clean

echo "=== Récupération des dépendances ==="
flutter pub get

echo "=== Build APK Release (obfusqué) ==="
flutter build apk \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols \
  --dart-define=API_BASE_URL=$API_BASE_URL

echo ""
echo "=== Build terminé ==="
echo "APK : build/app/outputs/flutter-apk/app-release.apk"
echo "Symbols : build/symbols/ (conserver pour Crashlytics)"
