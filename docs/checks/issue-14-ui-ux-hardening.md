# Issue 14 UI/UX Hardening Checklist

Date: 2026-08-11

Automated coverage added:

- Reduce Motion policy keeps Island sizing and presentation behavior intact while disabling geometry animation.
- Repeated hover, expand, interaction, and collapse cycles return to passive focus behavior.
- Core Island icon controls now expose explicit VoiceOver labels and hover help.
- Hover timers are invalidated when the hosting view is released.
- Expanded Island keyboard order and activation labels are covered for Media, Timer, File Shelf, Clipboard History, Home navigation, and Permission Center rows. See `docs/checks/issue-27-keyboard-navigation.md`.
- Permission Center rows remain in scope for UI/UX hardening, but Media default behavior and Spotify Automation gating are tracked separately in #26. See `docs/checks/issue-28-permission-center-scope.md`.

Manual verification still required before closing the HITL acceptance criteria:

1. Enable macOS Reduce Motion, then repeat hover, click expand, shortcut expand, feature switch, and collapse flows. Confirm geometry changes are immediate or subdued and no control disappears.
2. Navigate the Expanded Island with keyboard and VoiceOver using `docs/checks/issue-27-keyboard-navigation.md`. Confirm Media transport, Timer controls, File Shelf quick actions, Clipboard actions, Home navigation, and Permission Center rows have understandable labels and predictable activation order.
3. Repeat 50 cycles each: expand/collapse, activity switch, file drop, clipboard capture. Watch Activity Monitor memory and CPU for obvious growth or stuck work.
4. Sleep and wake the Mac with the app running. Confirm Island returns to the selected display, remains unobtrusive, and focus is not stolen.
5. Move between Spaces, open a fullscreen app, disconnect/reconnect an external display, and change the Primary Display selection. Confirm Island placement and passive/input focus behavior remain correct.
6. Human UX review: confirm the Island feels native, fast, unobtrusive, and useful before broadening feature scope.
