# Feature Toggles Stop the Feature, Not Just Hide UI

Disabling a Feature must stop its observers, polling, subscriptions, background tasks, activities, and menu visibility where appropriate. It is not enough to hide the Feature's view while leaving monitoring active.

This decision supports performance, privacy, and user trust. If Clipboard History is off, it should not read the pasteboard; if Calendar is off, it should not hold calendar permissions or watchers; if Mirror is closed, the camera should be released.
