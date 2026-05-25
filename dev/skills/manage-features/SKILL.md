---
name: manage-features
description: Use when the feature list needs to evolve mid-project — splitting an oversized feature, adding work you didn't anticipate, deprecating obsolete entries, re-prioritizing around blockers, or auditing the list against reality. Triggers on "split feature", "add feature", "re-prioritize", "audit features", "feature is too big". Operates on docs/<initiative>/features.json.
---

# Manage Features

## Overview

The feature list in `docs/<initiative>/features.json` is a living document. When reality drifts from the original plan — work is bigger than expected, new requirements surface, something becomes obsolete — update the list. Don't pretend the original plan still holds.

Every change gets a `docs/<initiative>/progress.md` entry. See `workflow-convention.md` for the artifact layout.

## When to Use

- A feature turns out too large to complete in one session
- New requirements surface that aren't in the list
- A feature is now obsolete or superseded
- Dependencies make the current ordering wrong
- Auditing list health (stale entries, broken dependencies)

## When Not to Use

- Initial feature list creation (use design-session)
- Implementing features (use coding-session)
- Fixing broken tests (use recover-session)

## Operations

### 1. Split a feature

When during a coding-session you realize the feature is too big:

1. Stop implementation immediately
2. Change the original feature's description to reflect reduced scope
3. Create new features for extracted work, using the original ID as a prefix (`F012a`, `F012b`...)
4. Document the split in `progress.md`

Each split piece must be completable in one session.

```json
// Before
{ "id": "F012", "description": "User authentication system",
  "steps": ["Login", "JWT", "Sessions", "Password reset", "OAuth"],
  "passes": false }

// After
{ "id": "F012", "description": "Basic login with JWT",
  "steps": ["Login form", "JWT generation", "Token validation"],
  "passes": false },
{ "id": "F012a", "description": "Session management and refresh",
  "steps": ["Refresh flow", "Expiry", "Concurrent limits"],
  "passes": false },
{ "id": "F012b", "description": "Password reset flow",
  "steps": ["Reset request", "Email token", "Confirmation"],
  "passes": false },
{ "id": "F012c", "category": "integration",
  "description": "OAuth provider integration",
  "steps": ["OAuth callback", "Provider config", "Account linking"],
  "passes": false }
```

### 2. Add a new feature

When you discover work that isn't in the list:

1. Decide: truly new, or belongs as a step inside an existing feature?
2. Assign the next available ID in sequence
3. Set `"passes": false`

```json
{
  "id": "F045",
  "category": "operations",
  "description": "Rate limiting for API endpoints",
  "steps": ["Configure limiter", "Add middleware", "Return rate headers", "Load test"],
  "passes": false
}
```

Add a new feature when the work stands alone. Expand an existing feature's `steps` when it's an additional step within the same scope.

### 3. Deprecate a feature

When a feature is no longer relevant:

1. Don't delete it — IDs are referenced in commits and progress entries
2. Add a `"deprecated"` field with the reason
3. Set `"passes": true` (it "passes" by not needing to exist)

```json
{
  "id": "F023",
  "category": "integration",
  "description": "DEPRECATED: XML feed parser",
  "deprecated": "Replaced by JSON API in F031",
  "steps": [],
  "passes": true
}
```

### 4. Re-prioritize

When dependencies or blockers make the current order suboptimal, skip ahead. Add a `"blocked_by"` field to blocked features and document the re-sequencing in `progress.md`:

```json
{
  "id": "F015",
  "description": "Exchange API data fetching",
  "steps": ["API client", "Authentication", "Normalization"],
  "passes": false,
  "blocked_by": "Waiting for API credentials from user"
}
```

### 5. Audit

Every 10-20 completed features, audit the list:

- **Consistency** — every `"passes": true` feature actually has working code; no duplicates or overlaps
- **Completeness** — implemented functionality is reflected in the list; no orphaned code; categories aren't lopsided (50 core, 2 testing)
- **Granularity** — no remaining feature would take more than one session; no trivially small ones that should merge
- **Dependencies** — blocked features have documented reasons; no circular deps; order is reasonable

Document audit findings in `progress.md`:

```markdown
## Session 2026-02-22-audit

- **Agent:** <model>
- **Worked on:** Feature list audit
- **Findings:**
  - F008 marked passing but test was skipped — reverted to false
  - Split F034 into F034/F034a (too large for one session)
  - Deprecated F011 (superseded by F029)
  - Added F046-F048 for error handling
  - Total: 48/52 passing (92%)
- **Next:** F034 (reduced scope)
- **Commit:** chore(<initiative>): audit and update feature list
```

## Progress Documentation

Every features.json change gets a progress.md entry:

```markdown
## Session 2026-02-22-02

- **Agent:** <model>
- **Worked on:** Split F012 (auth system)
- **Completed:**
  - Split F012 → F012, F012a, F012b, F012c
  - F012 reduced to basic login + JWT scope
  - Implemented F012 — verify passes
- **Next:** F012a — session management
- **Commit:** feat(<initiative>): basic login (F012), split auth features
```

## Don't

- **Don't squeeze an oversized feature into one session.** Two clean sessions beat one rushed, half-tested one. If it's too big, split it.
- **Don't delete features — deprecate them.** Deleting breaks references in commits and `progress.md`. Deprecation preserves the audit trail.
- **Don't add features as procrastination.** If you're adding to avoid finishing current work, finish current work first.
- **Don't leave dependency reasons undocumented.** Obvious to you now, opaque to a future session. Write the reason in `blocked_by` or `progress.md`.
- **Don't mass-edit `features.json` without a `progress.md` entry.** Untracked changes drift the list from reality and lose the audit trail.
