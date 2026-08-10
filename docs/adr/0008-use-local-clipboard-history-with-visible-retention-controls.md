# Use Local Clipboard History with Visible Retention Controls

Clipboard History should be local-only, disabled or pausable by the user, and default to a bounded retention policy rather than unlimited storage. The recommended default is seven days, with clear controls for pause, clear history, and retention changes.

Clipboard content is sensitive, so the UX must make control obvious without turning first launch into a privacy questionnaire. Polling via pasteboard change count is acceptable only when Clipboard History is enabled and must not update UI unless content actually changes.
