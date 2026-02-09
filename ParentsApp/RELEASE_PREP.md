Release prep checklist — Play Store (Android)

Summary
- This file contains the commands and checklist to prepare the `ParentsApp` Flutter app for publishing to Google Play (AAB upload).

Prerequisites
- Install Flutter and Android SDK and ensure `flutter doctor` shows no errors.
- Have access to Google Play Console for the target developer account.

1) Versioning
- Update `pubspec.yaml` `version:` field. Format: `x.y.z+buildNumber` (the `+buildNumber` is Android `versionCode`).
  - Example: `version: 1.2.0+3` (versionName=1.2.0, versionCode=3)

2) Signing (create a private keystore)
- Create a release keystore (example):

```bash
keytool -genkey -v -keystore release-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias app_key
```

- Keep the keystore and passwords secret. Do NOT commit the keystore or your passwords to source control.

- Create a `key.properties` file with your values (see `android/key.properties.template`). Typical keys:

```
storePassword=YOUR_STORE_PASSWORD
keyPassword=YOUR_KEY_PASSWORD
keyAlias=app_key
storeFile=app/release-keystore.jks
```

- Add `release-keystore.jks` and `key.properties` to `.gitignore`.

3) Configure Android signing in `android/app/build.gradle`
- If you want, I can add the standard `signingConfigs` snippet to `android/app/build.gradle` to read `key.properties` and use it for release builds. Tell me if you'd like me to apply this change.

4) Build the AAB
- Commands to build the app bundle:

```bash
cd ParentsApp
flutter clean
flutter pub get
flutter build appbundle --release
```

Artifact: `build/app/outputs/bundle/release/app-release.aab`

5) Play Console checklist
- Create new app in Play Console: platform=Android, default language, app name.
- Prepare store listing:
  - Short description and full description
  - High-res icon: 512x512 PNG, 32-bit, no alpha
  - Feature graphic: 1024x500 PNG (for store listing)
  - Screenshots: at least 2 phone screenshots (JPEG/PNG). Follow Play Console guidelines; provide landscape/portrait as appropriate.
  - Promo video (optional)
- App content:
  - Privacy policy URL (required if app collects personal data)
  - Ads declaration
  - Data safety form (complete accurately in Play Console)
  - Content rating questionnaire
- Pricing & distribution: countries, free vs paid, opt-in to distribution agreements

6) App Signing by Google Play
- Recommended: opt-in to Google Play App Signing when creating the app. You keep an upload key (the keystore you generate) and Google manages the app signing key.

7) Release flow (recommended)
- Upload AAB to internal testing track first, verify install and behavior.
- After verification, promote to closed/beta, then gradually to production.

8) Post-release
- Monitor Play Console for crashes, ANRs, and user feedback.
- Ensure crash reporting (Sentry / Firebase Crashlytics) is configured and tested.

Useful asset sizes
- App icon (Play): 512x512 PNG
- Feature graphic: 1024x500 PNG
- Phone screenshots: minimum width 320px; recommended phone screenshot size ~1080x1920

If you want, I can:
- Inspect `pubspec.yaml` and suggest the exact version bump.
- Add the Gradle signing config automatically (creating `android/key.properties.template` and instructions) so you only need to place your `release-keystore.jks` and fill `key.properties`.
- Build the AAB here (if Flutter SDK is available in this environment) or show exact commands to run locally.
