# Repository Instructions

<!-- CODEGRAPH_START -->
## CodeGraph

In repositories indexed by CodeGraph (a `.codegraph/` directory exists at the repo root), reach for it BEFORE grep/find or reading files when you need to understand or locate code:

- **MCP tool** (when available): `codegraph_explore` answers most code questions in one call — the relevant symbols' verbatim source plus the call paths between them, including dynamic-dispatch hops grep can't follow. Name a file or symbol in the query to read its current line-numbered source. If it's listed but deferred, load it by name via tool search.
- **Shell** (always works): `codegraph explore "<symbol names or question>"` prints the same output.

If there is no `.codegraph/` directory, skip CodeGraph entirely — indexing is the user's decision.
<!-- CODEGRAPH_END -->

Speak Vietnamese with me ! and alway use caveman

## Learning rules

- When a build failure, review finding, or missed acceptance criterion is preventable by process, add one durable rule to `AGENTS.md` or the narrowest relevant agent doc in the same change.
- Keep new rules specific to the failure mode. Prefer "Before commit, check `git status --short` includes expected new files" over broad advice like "be careful".
- Before committing issue work, verify untracked files. New docs, manual notes, tests, and fixtures must be staged intentionally or deleted intentionally.
- For macOS display geometry, prefer public `NSScreen` geometry (`safeAreaInsets`, `auxiliaryTopLeftArea`, `auxiliaryTopRightArea`) over Mac model-name checks.
- Treat SDK-imported optional AppKit geometry as optional even when Objective-C headers look non-optional; coalesce missing auxiliary areas to `.zero`.
- When adding AppKit subclasses or event monitor wrappers under Swift 6, account for required superclass initializers and non-Sendable monitor tokens before the first build.
- For app-owned repeating `Timer`s under Swift 6, prefer target/selector timers over closure timers that capture `self`.
- When invalidating AppKit-owned `Timer`s from `deinit` under Swift 6, account for nonisolated deinitializers before the first build.
- When AppDelegate starts feature lifecycles, skip background macOS integrations under `XCTestConfigurationFilePath` so unit test hosts do not poll AppleScript, pasteboard, or permissions.
- After resolving merge conflicts between branches that both touch visible permission or accessibility strings, run the affected focused test before the full suite.

## Agent skills

### Issue tracker

Issues are tracked in GitHub Issues for `natuan1/magic-island`. See `docs/agents/issue-tracker.md`.

### Triage labels

Triage uses the default five canonical labels: `needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`. See `docs/agents/triage-labels.md`.

### Domain docs

This repo uses a single-context domain-doc layout: root `CONTEXT.md` plus `docs/adr/`. See `docs/agents/domain.md`.
