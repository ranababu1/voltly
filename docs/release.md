# Release Process

## Versioning

- `pubspec.yaml` uses `MAJOR.MINOR.PATCH+BUILD`.
- Stable tags use `vMAJOR.MINOR.PATCH`, for example `v0.6.0`.
- Preview tags use a hyphenated suffix, for example `v0.9.0-preview` or
  `v0.9.0-rc.1`; these are published as GitHub pre-releases.
- Asset filenames use the release tag version:
  - `Voltly-v0.9.0-preview-universal.apk`
  - `Voltly-v0.9.0-preview-arm64-v8a.apk`
  - `Voltly-v0.9.0-preview.aab` (Google Play artifact, not installable)
- The tag, `versionName` and asset version must match, allowing the documented
  preview suffix. The AAB does not replace either required APK.

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

Public certificate fingerprint:

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
builds both APKs and the AAB, verifies the APK and AAB signatures, and publishes
the GitHub Release. A tag exactly matching the pubspec version is a stable
release; tags containing a hyphen are marked as pre-releases. The AAB is
uploaded as a separate Google Play artifact and is not presented as an
installable APK.

`v0.6.0` was published manually before the workflow was added; its signed assets
were verified by downloading them again.

## Published v0.9.0-preview

- Tag: `v0.9.0-preview` at commit `8eacc32`
- Release: https://github.com/ranababu1/voltly/releases/tag/v0.9.0-preview
- Assets:
  - `Voltly-v0.9.0-preview-universal.apk` — 53,968,846 bytes, SHA-256
    `A0A7DD579C690A5CB5C09A361E1C73EDDD0640586E9E536C48121520B59C59D9`
  - `Voltly-v0.9.0-preview-arm64-v8a.apk` — 18,716,326 bytes, SHA-256
    `47C3AB6B44C66A81794BA874307FF066BCC45588897C4FC6CC7ACFE279DB0096`
  - `Voltly-v0.9.0-preview.aab` — 53,558,550 bytes, SHA-256
    `1D137BE4FB509E48B7344899824B6308769D57D83A129DB0CD3445CC6328E958`
- GitHub marks it as a pre-release because physical-device telemetry validation
  and human TalkBack validation remain outstanding.
- All three assets were downloaded again. Both APKs pass `apksigner` with
  `CN=Voltly Release`; the AAB passes `jarsigner`. The universal APK installed
  and cold-launched on the Pixel 10a AVD. The arm64 APK was signature/ABI-checked
  but cannot install on the x86_64 emulator. The AAB was not uploaded to Google
  Play.
- The workflow initially failed because the Gradle wrapper was ignored; commit
  `8eacc32` tracks `gradlew`, `gradlew.bat` and `gradle-wrapper.jar`, and the
  retagged run published successfully.

This preview is not a stable release. Do not move the published tag or replace
the assets.

## Safety

- Do not upload debug-signed APKs.
- Do not move or recreate a published tag.
- Do not overwrite a release without owner approval.
- Record physical-device validation limitations in the release notes.
- A stable release may only be published after the required release checks; a
  preview release must be marked as a pre-release.
