# Desktop Island

Desktop Island is a macOS utility that turns the top-center screen area into a small, fast productivity surface. Its domain is the behavior and language of that surface, its activities, and the productivity features that appear inside it.

## Language

**Island**:
The always-available top-center productivity surface that can appear over the user's current work without becoming a normal application window.
_Avoid_: Notch, popup, dashboard

**Physical Notch**:
The camera housing area present on some MacBook displays.
_Avoid_: Island

**Floating Island**:
The Island geometry used on displays without a Physical Notch, including external monitors.
_Avoid_: Fake notch

**Compact Activity**:
A small representation of the current Activity shown while the Island is not expanded.
_Avoid_: Mini widget, notification

**Expanded Island**:
The larger interactive form of the Island where the user can inspect an Activity or navigate to feature views.
_Avoid_: Dashboard

**Current Activity**:
The Activity currently selected by the Activity Engine as the most relevant thing for the Island to represent.
_Avoid_: Active feature

**Home View**:
The compact navigation surface inside the Expanded Island that gives access to core features without becoming a full dashboard.
_Avoid_: Dashboard, control center

**Activity**:
A time-bound or source-bound piece of user-relevant state that competes to be represented by the Island.
_Avoid_: Event, notification, widget

**Activity Engine**:
The application service that ranks Activities and selects the current Activity for presentation.
_Avoid_: Island state machine, feature coordinator

**Island State**:
The interaction state of the Island, such as idle, hovering, expanded, interacting, drag target, or collapsing.
_Avoid_: Activity state

**Peek**:
A lightweight hover response that previews Island content without committing the user to keyboard focus or a full interaction flow.
_Avoid_: Auto-open

**Drag Target**:
The Island state where it visually accepts files being dragged into the top-center area.
_Avoid_: Upload zone

**Feature**:
A product capability that can publish Activities and own its own lifecycle, resources, and settings.
_Avoid_: Plugin, module

**Feature Toggle**:
A user or build setting that enables or disables an entire Feature, including its background observers and resource usage.
_Avoid_: Hide setting

**File Shelf**:
The productivity feature that temporarily or persistently holds file references or managed file copies for later action.
_Avoid_: File manager, downloads

**Shelf Item**:
One file entry held by the File Shelf.
_Avoid_: File record

**Clipboard History**:
The local-only history of recent clipboard items captured by Desktop Island.
_Avoid_: Cloud clipboard

**Retention Policy**:
The rule that decides how long local Clipboard History or Temporary Copy Shelf data remains available.
_Avoid_: Cache setting

**Quick Action**:
A contextual command offered for text, files, images, or other content already present in the Island.
_Avoid_: Automation, plugin

**Passive Mode**:
The Island mode where it stays visible or clickable without taking keyboard focus from the current app.
_Avoid_: Background mode

**Interactive Mode**:
The Island mode where keyboard focus is allowed because the user is typing, searching, renaming, or editing settings.
_Avoid_: Active mode

**Private Integration**:
A platform integration using non-public macOS APIs behind a replaceable adapter with health checks, fallback, logging, and feature flags.
_Avoid_: Core dependency

**Local First**:
The product privacy stance that user content stays on the device unless the user explicitly performs an action that sends it elsewhere.
_Avoid_: Offline-only

**Permission Center**:
The Settings area that explains feature permissions, current grant state, and revocation paths without asking for all permissions at first launch.
_Avoid_: Onboarding checklist

**Primary Display**:
The display selected as the default home for the Island when no more specific display rule applies.
_Avoid_: Main screen
