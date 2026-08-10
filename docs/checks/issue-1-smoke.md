# Issue 1 Smoke Check

Use this checklist after building `MagicIsland.xcodeproj` with the `MagicIsland` scheme.

- Run `xcodebuild clean test -project MagicIsland.xcodeproj -scheme MagicIsland -destination 'platform=macOS,arch=arm64'` and confirm it succeeds with no `warning:` or `error:` lines.
- Launch from Xcode or run the built `MagicIsland.app`.
- Confirm no Dock icon appears for Magic Island.
- Confirm a menu-bar item titled `MI` appears.
- Open the `MI` menu and confirm `Quit Magic Island` is present.
- Confirm a small native Island placeholder appears at the top-center of the Primary Display.
- Choose `Quit Magic Island` and confirm the app exits.
