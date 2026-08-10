# Issue 2 Manual Verification

Date: 2026-08-10
Machine setup: single non-notch display, 1440 x 900.

## Display geometry

`NSScreen` reported:

- `frame`: `(0.0, 0.0, 1440.0, 900.0)`
- `visibleFrame`: `(0.0, 58.0, 1440.0, 812.0)`
- `safeAreaInsets`: `top: 0.0, left: 0.0, bottom: 0.0, right: 0.0`
- `auxiliaryTopLeftArea`: `nil`
- `auxiliaryTopRightArea`: `nil`

Expected decision: Floating Island.
Expected AppKit frame: `(646.0, 854.0, 148.0, 38.0)`.

## App launch check

Launched debug build from DerivedData and inspected the on-screen window with
`CGWindowListCopyWindowInfo`.

Observed window:

- owner: `MagicIsland`
- bounds: `X = 646`, `Y = 8`, `Width = 148`, `Height = 38`
- on screen: `1`

The observed top-origin `Y = 8` matches the AppKit bottom-origin `Y = 854` on a
900 point tall display. Window size matches the Floating Island instead of a
full-screen transparent overlay.
