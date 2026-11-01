# 9. Release

How to build a version for Google Play and what the store needs. The app ID is
`io.github.tizalibre.leeconleo`, and it can never change after the first upload.

## Version

`pubspec.yaml` holds `version: <name>+<code>`, for example `1.0.0+1`. Every upload to
Google Play needs a higher code (`+2`, `+3`…). The name is what families see.

## Upload key

Google Play keeps the key that signs the app for users (Play App Signing). We keep
only the **upload key**, which proves the uploads come from us.

1. Create it once, outside the repository:

   ```
   keytool -genkey -v -keystore C:/keys/leeconleo-upload.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

2. Create `android/key.properties` (ignored by git, never committed):

   ```
   storeFile=C:/keys/leeconleo-upload.jks
   storePassword=<the keystore password>
   keyAlias=upload
   keyPassword=<the key password>
   ```

3. Back up the `.jks` file and both passwords somewhere safe. A lost upload key can
   be replaced through Play Console support, but it takes time.

Without `key.properties`, release builds fall back to the debug key, so CI and other
computers still build. Those builds can't be uploaded to Google Play.

## Build

```
flutter build appbundle
```

The bundle to upload is `build/app/outputs/bundle/release/app-release.aab`.

## Privacy policy

`site/` is published by `.github/workflows/pages.yml` on every change pushed to
`main`. Turn it on once in the repository: **Settings → Pages → Source: GitHub Actions**.
The policy is then at `https://tizalibre.github.io/LeeConLeo/privacidad/`.

The policy says what the app really does: no data leaves the device, no internet,
no ads, no analytics, no permissions. Update it whenever that changes, and have it
reviewed before publishing (Chilean data protection law, Google Play Families policy).

## Play Console checklist

- **Store listing:** name, short and full description in Spanish, icon, phone and
  tablet screenshots, a 1024×500 feature graphic, contact email, privacy policy URL.
- **Data safety:** no data collected, no data shared.
- **Content rating:** the questionnaire (no violence, no user content, no purchases).
- **Target audience:** under 8, which enrolls the app in the Families program and its
  review.
- **Testing:** new personal developer accounts need a closed test (at least 12
  testers for 14 days) before production. This doubles as the M3 beta.
