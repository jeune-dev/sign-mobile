#!/bin/bash
# Build IPA release pour App Store Connect / TestFlight
# Usage : bash build_release_ios.sh
#
# Prérequis (à faire une seule fois, dans Xcode) :
#   - Xcode 16.4 installé dans /Applications et sélectionné (xcode-select)
#   - ios/Runner.xcodeproj -> target Runner -> Signing & Capabilities :
#       - Team Apple Developer renseignée
#       - Capacité "Push Notifications" ajoutée (relie Runner.entitlements)
#   - ios/Runner/GoogleService-Info.plist présent (Firebase Console)
#   - pod install déjà exécuté au moins une fois dans ios/

set -e

API_BASE_URL="https://api.app-signs.com/sign"

echo "=== Nettoyage ==="
flutter clean

echo "=== Récupération des dépendances ==="
flutter pub get

echo "=== Installation des pods iOS ==="
cd ios
pod install --repo-update
cd ..

echo "=== Build IPA Release (obfusqué) ==="
flutter build ipa \
  --release \
  --obfuscate \
  --split-debug-info=build/symbols_ios \
  --dart-define=API_BASE_URL=$API_BASE_URL

echo ""
echo "=== Build terminé ==="
echo "IPA : build/ios/ipa/*.ipa"
echo "Symbols : build/symbols_ios/ (conserver pour Crashlytics)"
echo ""
echo "Pour uploader vers App Store Connect :"
echo "  xcrun altool --upload-app -f build/ios/ipa/*.ipa -t ios \\"
echo "    --apiKey <VOTRE_API_KEY_ID> --apiIssuer <VOTRE_ISSUER_ID>"
echo "  (ou ouvrir l'archive dans Xcode Organizer -> Distribute App)"
