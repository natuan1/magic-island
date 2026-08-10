# Separate Activity Selection from Island Interaction State

The Activity Engine selects which Activity should be represented; it does not own expand, collapse, hover, drag target, or keyboard-focus transitions. Island State belongs to a separate Island state machine so features can publish Activities without directly controlling the Island's interaction behavior.

This keeps product behavior coherent when multiple features compete for attention. A timer finishing may outrank media, but that priority decision should not let the Timer feature directly force arbitrary UI transitions.
