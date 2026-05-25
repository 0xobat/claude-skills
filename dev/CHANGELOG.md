# Changelog

All notable changes to the `dev` plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [2.0.0] — 2026-05-25

### Breaking

- **Renamed `initialize-project` → `design-session`.** Anyone with routing
  rules, muscle memory, or scripts invoking `/initialize-project` must update
  to `/design-session`.

### Added

- **`design-session` skill** (replaces `initialize-project`). Interactive Q&A
  + research pattern inspired by gstack's `office-hours`. Four phases —
  Context Gathering → 5 Forcing Questions → Mandatory Alternatives → Write
  Artifacts — producing `docs/<initiative>/design.md` and `features.json`.

### Changed

- **Adopted the docs-first workflow convention.** All dev skills now use
  `docs/<initiative>/{design.md, features.json, progress.md}` instead of the
  older `harness/<project>/{init.sh, verify.sh, features.json, progress.txt}`
  pattern. See `workflow-convention.md` at the marketplace root for the
  full specification.
- **`team-lead` rewritten** (399 → 251 lines). Phases consolidated from 6
  to 5; agent briefing template shortened; wave/dependency planning
  preserved but tightened.
- **`coding-session` rewritten** (255 → 142 lines). Verify commands updated
  from `./harness/verify.sh` to project-level commands
  (e.g. `pnpm check-types && pnpm build`).
- **`manage-features` rewritten** (253 → 165 lines). Path references
  migrated; operations (split / add / deprecate / re-prioritize / audit)
  preserved.
- **`recover-session` rewritten** (200 → 158 lines). Diagnostic commands
  updated to use project-level verify; git bisect / rollback guidance
  preserved.
- **`onboard` updated** to reference `docs/<initiative>/` artifacts.
- **Guardrails consolidated.** Each skill previously had three overlapping
  defensive sections (Common Mistakes, Red Flags, Anti-Patterns) — now
  collapsed into a single "Don't" section per skill.
- Total skill LOC reduced from 1351 → 921 (~32%).

### Removed

- **`initialize-project` skill** (superseded by `design-session`).
- All references to `harness/`, `init.sh`, `verify.sh`, and `progress.txt`.

## [1.0.0] — 2026-03-27

### Added

- Initial release with six skills: `coding-session`, `initialize-project`,
  `manage-features`, `onboard`, `recover-session`, `team-lead`.
- Harness-based workflow pattern with `init.sh`, `verify.sh`,
  `features.json`, and `progress.txt`.
