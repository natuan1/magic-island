# Isolate Private macOS APIs Behind Replaceable Adapters

Desktop Island may use private macOS integrations such as MediaRemote only as optional Private Integrations behind public application protocols, health checks, fallbacks, logging, and feature flags. Private frameworks must not leak into Domain, Application, or Presentation code.

Direct distribution makes MediaRemote research viable, but macOS updates can break private APIs. If the adapter fails, the affected feature degrades or disables itself while the Island, Shelf, Clipboard, Timer, and other features continue working.
