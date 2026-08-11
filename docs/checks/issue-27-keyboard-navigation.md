# Issue 27 Expanded Island Keyboard Navigation Notes

Date: 2026-08-11

Automated coverage:

- `IslandInteractionControllerTests.testExpandedMediaKeyboardControlsFollowTransportOrderBeforeHomeNavigation` verifies Media keyboard order and activation identities: Previous track, Play or pause media, Next track, Seek forward 15 seconds, then Home navigation. The same model drives SwiftUI accessibility sort priority.
- `IslandInteractionControllerTests.testExpandedTimerKeyboardControlsCoverStartAndRunningStates` verifies Timer start controls, running controls, and their activation identities. The same model drives SwiftUI accessibility sort priority.
- `IslandInteractionControllerTests.testExpandedFileShelfAndClipboardKeyboardControlsExposeQuickActionsAndDeletes` verifies File Shelf quick actions, Clipboard quick actions/delete, and their activation identities before Home navigation. The same model drives SwiftUI accessibility sort priority.
- `IslandInteractionControllerTests.testPermissionCenterRowsExposeSingleKeyboardReadableLabel` verifies Permission Center rows expose one readable keyboard/VoiceOver label with state, feature, purpose, and revoke guidance.
- `IslandInteractionControllerTests.testRepeatedExpandCollapseReturnsToPassiveWithoutAccumulatingState` keeps repeated expand/collapse covered so the Island returns to passive focus behavior.

Manual keyboard traversal:

1. Expand from passive Island with the configured shortcut. Expected focus behavior: window opens expanded without stealing input focus until a control needs keyboard interaction.
2. Press Tab into Media activity controls. Expected order: Previous track, Play or pause media, Next track, Seek forward 15 seconds, Media, File Shelf, Clipboard History, Timer, Settings. Press Space or Return on each transport control and confirm playback command fires.
3. Open Timer from Home navigation, then Tab. Expected order when no timer is active: Start 5 minute timer, Start 10 minute timer, Start 25 minute timer, Timer, Settings. Start a timer and repeat. Expected order while running: Pause timer, Restart timer, Cancel timer, Close timer, Timer, Settings.
4. Open File Shelf from Home navigation with at least one available file. Expected order for each row: Open, Preview, Reveal, Copy Path, then Home navigation. Missing files should not expose enabled quick actions.
5. Open Clipboard History from Home navigation with at least one item. Expected order for each visible row: Copy, Search Web, optional Open URL, Delete item, then Home navigation. Search field accepts input only after the Island enters input-allowed interaction.
6. Open Settings and navigate Permission Center rows. Expected row label: permission title, grant state, feature, purpose, and revoke guidance. Rows are readable as one combined element.
7. Press Escape to collapse. Expected focus behavior: Island returns to passive presentation and does not remain key after repeated expand/collapse cycles.
