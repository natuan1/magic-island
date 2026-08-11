# Issue 28 Permission Center Scope Decision

Date: 2026-08-11

Decision:

- #14 keeps Permission Center in scope only as UI/UX hardening: visible rows, readable state, VoiceOver/keyboard behavior, and revocation guidance.
- Media default behavior and Spotify Automation permission gating are tracked outside #14 in #26.
- #14 should not own permission prompt timing, feature enable/disable semantics, or Spotify-not-running behavior beyond showing the current state clearly.

Implications for review:

- Diffs for #14 may update Permission Center row presentation, labels, traversal, and manual verification notes.
- Diffs for #14 should not change when Media starts, stops, prompts, or disables itself for Spotify Automation states.
- #26 is the linked follow-up for Media remaining enabled while Spotify is not running or Automation is unknown, and for denied/unavailable gating behavior.

Explicit scope mapping:

- Permission Center rows: in #14 for UI/UX hardening.
- Media default behavior: out of #14; covered by #26.
- Spotify Automation gating: out of #14; covered by #26.
