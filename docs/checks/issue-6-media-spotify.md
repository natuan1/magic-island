# Issue 6 Spotify Compatibility Notes

Manual verification target: Spotify on macOS.

1. Launch Spotify and start playback.
2. Launch Magic Island.
3. Confirm Compact Activity shows the current track title and artist.
4. Open the Expanded Island.
5. Confirm media detail shows app name, playback state, and supported transport controls: play/pause, previous, next, and seek.
6. Stop playback.
7. Confirm the Island returns to idle or to the previous non-Media Activity.

Provider failure behavior: if AppleScript access fails, Media disables itself and removes only Media Activities. The Activity Engine and other Activities stay available.
