# Direct Distribution Release Path

## Prerequisites

- Developer ID Application certificate installed in the build keychain.
- App-specific password or notarytool keychain profile configured for notarization.
- Sparkle/appcast credentials configured if automatic updates are enabled later.

## Build

1. Archive Release build from Xcode with Developer ID signing.
2. Export the `.app` with hardened runtime enabled.
3. Verify signature:

   ```sh
   codesign --verify --deep --strict --verbose=2 MagicIsland.app
   spctl --assess --type execute --verbose MagicIsland.app
   ```

## Notarize And Staple

1. Zip the app for notarization:

   ```sh
   ditto -c -k --keepParent MagicIsland.app MagicIsland.zip
   ```

2. Submit and wait:

   ```sh
   xcrun notarytool submit MagicIsland.zip --keychain-profile "MagicIsland Notary" --wait
   ```

3. Staple:

   ```sh
   xcrun stapler staple MagicIsland.app
   xcrun stapler validate MagicIsland.app
   ```

## DMG

1. Create a signed DMG containing `MagicIsland.app` and an `/Applications` symlink.
2. Sign and verify the DMG:

   ```sh
   codesign --sign "Developer ID Application: TEAM" MagicIsland.dmg
   spctl --assess --type open --context context:primary-signature --verbose MagicIsland.dmg
   ```

## Appcast

1. Publish the signed DMG to the release host.
2. Generate the appcast item with version, minimum macOS version, file size, signature, and release notes.
3. Upload the appcast XML after the DMG is reachable.
4. Use the in-app `ApplicationUpdating` adapter to check the production appcast URL.
