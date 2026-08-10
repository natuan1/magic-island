# Ship as a Native Local-First Direct Distribution Utility

Desktop Island will ship outside the Mac App Store as a Developer ID signed, hardened, notarized, stapled DMG app with Sparkle updates. The app is local-first by default: no account, no cloud sync, no clipboard uploads, no file uploads, and no content telemetry.

This is a deliberate trade-off for a native macOS utility that needs tight system integration and user trust. Production builds must not require Gatekeeper bypasses, SIP changes, or terminal commands from users.
