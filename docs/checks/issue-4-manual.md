# Issue 4 Manual Check

Manual verification target: external display disconnect.

1. Launch Magic Island with two displays connected.
2. Select the external display as the Island target when display selection UI exists.
3. Disconnect the external display or change its resolution/scaling.
4. Confirm the Island moves to the Primary Display and remains inside the visible display bounds.
5. Reconnect the external display and confirm selected-display placement is restored when that display is available.

Current automated coverage checks selected display preference, missing selected display fallback, display-origin placement, and frame clamping.
