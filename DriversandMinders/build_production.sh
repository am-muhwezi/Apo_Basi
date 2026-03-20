#!/bin/bash
set -e

echo "Building Basi Driver — PRODUCTION"
echo "App ID: com.apobasi.driver"
echo "Backend: https://api.apobasi.com"
echo ""

read -p "You are building for PRODUCTION. Continue? (yes/no): " -r
if [[ ! $REPLY =~ ^[Yy][Ee][Ss]$ ]]; then
  echo "Build cancelled."
  exit 1
fi

flutter clean
flutter pub get
flutter build appbundle \
  --flavor prod \
  --target lib/main_prod.dart \
  --release

echo ""
echo "Done: build/app/outputs/bundle/prodRelease/app-prod-release.aab"
echo "Upload to Google Play → Production track"
