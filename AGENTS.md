# AGENTS.md

These shared instructions apply to every coding agent working in this repository.

## Working Agreement

- Preserve unrelated work in a dirty worktree. Do not reset, discard, or reformat files outside the requested change.
- Keep changes focused and verify them in proportion to their risk. For documentation-only changes, check links, commands, and referenced paths. For code or configuration changes, run the relevant project checks.
- Implement and verify in the parent session by default: build, run the relevant tests, and exercise the affected flow. Trivial, documentation-only, and configuration-only changes need only proportional checks. Before committing a behavior-changing code change that spans multiple files, have a fresh reviewer check the diff.
- Use a fresh, independent verifier and reviewer for high-risk changes affecting persisted credentials, authentication, privacy, analytics, advertising, deployment, purchases, or external systems. They must not validate their own implementation.
- Only the orchestrating parent delegates workflow roles. Child implementers, verifiers, and reviewers return evidence to that parent without recursively spawning workflow agents. Use parallel agents only for genuinely independent work that materially improves speed or quality. Record any material limitation when a required check cannot run.
- Escalate ambiguity, risky changes, or an unavailable required model or tool instead of silently substituting a weaker workflow.

## Project Overview

Nekofunjatter is a macOS 13+ menu-bar app that detects sustained simultaneous key presses and plays audio. It optionally blocks keyboard input while detection is active. `Package.swift` declares a Swift 5.9 executable; `README.md` documents operation and packaging.

`Sources/Nekofunjatter/` separates CGEventTap monitoring, CatDetector logic, menu controls, UserDefaults settings, and playback. `Resources/` contains audio, icons, entitlements, and localization. Preserve manual stop/key-unblock and the documented 60-second hard timeout. Never leave input blocked after cancellation, errors, or shutdown.

## Verification and Agent Routing

Codex follows [docs/codex-workflow.md](docs/codex-workflow.md). For documentation/configuration changes, check references, TOML, and diffs. For code changes run `swift build`; no test target is currently declared. `Scripts/build-app.sh` packages/signs the app and may use local signing configuration.

Runtime verification must cover detection thresholds, preview/custom audio, settings persistence, and emergency stop. Accessibility permission and global input interception require macOS runtime checks; coordinate input-blocking tests so the user retains control. Use synthetic key scenarios rather than requesting an animal to test behavior.

Preserve the distinction between code licensing (`LICENSE`) and audio licensing (`License.md`). Do not regenerate bundled audio or icons as an incidental build step. Keep local .env credentials private. Notarization and distribution scripts are release actions, executed only when authorized.
