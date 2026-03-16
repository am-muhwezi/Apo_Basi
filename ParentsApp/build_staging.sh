#!/bin/bash
set -e

echo "Building ApoBasi Parents — STAGING"
echo "App ID: com.apobasi.parents.staging"
echo "Backend: https://staging.api.apobasi.com"
echo ""

flutter clean
flutter pub get
flutter build appbundle \
  --flavor staging \
  --target lib/main_staging.dart \
  --release

echo ""
echo "Done: build/app/outputs/bundle/stagingRelease/app-staging-release.aab"
echo "Upload to Google Play → Internal Testing track"
