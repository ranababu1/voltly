# Release Process

## Versioning

- `pubspec.yaml` uses `MAJOR.MINOR.PATCH+BUILD`.
- Tags use `vMAJOR.MINOR.PATCH`, for example `v0.6.0`.
- APK assets include the app and version:
  - `Voltly-v0.6.0-universal.apk`
  - `Voltly-v0.6.0-arm64-v8a.apk`
- The tag, `versionName`, and asset version must match.

## Signing

Release signing is configured through `android/key.properties`, which is
git-ignored. The keystore itself is stored outside the repository. The four
GitHub Actions secrets mirroring this configuration are:

- `ANDROID_KEYSTORE_BASE64`
- `ANDROID_KEYSTORE_PASSWORD`
- `ANDROID_KEY_ALIAS`
- `ANDROID_KEY_PASSWORD`

Never commit the keystore, `key.properties`, passwords, or base64 copies. Back
up the keystore and credentials; losing them prevents installing updates over an
existing installation signed with the same key.

Public certificate fingerprint for `v0.6.0`:

```text
SHA-256 54:3D:C7:A8:C3:D4:E3:3D:63:E8:18:0F:09:1F:2A:BD:07:9D:10:2D:3E:32:E8:71:50:38:8F:04:FE:34:D6:41
```

## Manual publication (v0.6.0)

1. Run `dart run build_runner build`, format, analyze, tests and Kotlin tests.
2. Build the signed universal APK:
   `flutter build apk --release`
3. Build the signed arm64 APK:
   `flutter build apk --release --split-per-abi --target-platform android-arm64`
4. Stage the files under the public names above.
5. Verify each APK with `apksigner verify --print-certs`; the signer must not be
   `CN=Android Debug`, and the certificate must match the fingerprint above.
6. Verify package `com.voltly`, `versionName 0.6.0`, and expected ABIs.
7. Commit and push the release source, create and push tag `v0.6.0`, then create
   the GitHub Release with both APK assets.
8. Download both assets again and verify their SHA-256 hashes and sizes.

## Automated future releases

`.github/workflows/release.yml` runs on `v*` tags. It builds and tests the
project, materializes the signing material from the four repository secrets,
builds both APKs, verifies that they are not debug-signed, and publishes the
GitHub Release. Tags containing a hyphen are marked as pre-releases.

`v0.6.0` was published manually before the workflow was added; its signed assets
were verified by downloading them again.

## Safety

- Do not upload debug-signed APKs.
- Do not move or recreate a published tag.
- Do not overwrite a release without owner approval.
- Record physical-device validation limitations in the release notes.
- A stable release may only be published after the required release checks; a
  preview release must be marked as a pre-release.
