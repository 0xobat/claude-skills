---
name: manage-features
description: Use when the feature list needs to evolve mid-project. Triggers when user says "split feature", "add feature", "re-prioritize", "audit features", "feature is too big", or when coding-session discovers a feature needs splitting. Provides protocols for adding, splitting, deprecating, and auditing features in features.json.
---

# Manage Features

## Overview

Structured feature list management for harness-based projects. Feature lists are living documents — they evolve as you learn more about the project. **Every change to features.json must be deliberate and documented.**

**Core principle:** The feature list reflects reality. When reality changes, update the list — don't pretend the original plan still works.

## When to Use

Use this skill when:
- A feature is too large and needs splitting
- New requirements surface mid-project
- Features are obsolete or redundant
- You need to re-prioritize based on dependencies or blockers
- Auditing feature list health (stale entries, broken dependencies)

Do NOT use for:
- Initial feature list creation (use initialize-project skill)
- Implementing features (use coding-session skill)
- Fixing broken tests (use recover-session skill)

## Operations

### 1. Split a Feature

**When:** During coding-session, you realize a feature is too big for one session.

**Protocol:**

1. STOP implementation immediately
2. Change the original feature's description to reflect reduced scope
3. Create new features for the extracted work
4. Use the original ID as a prefix for traceability

```json
// BEFORE: One big feature
{
  "id": "F012",
  "category": "core",
  "description": "User authentication system",
  "steps": ["Login form", "JWT tokens", "Session management", "Password reset", "OAuth"],
  "passes": false
}

// AFTER: Split into atomic pieces
{
  "id": "F012",
  "category": "core",
  "description": "Basic login with JWT token generation",
  "steps": ["Login form", "JWT token generation", "Token validation middleware"],
  "passes": false
},
{
  "id": "F012a",
  "category": "core",
  "description": "Session management and token refresh",
  "steps": ["Refresh token flow", "Session expiry", "Concurrent session limits"],
  "passes": false
},
{
  "id": "F012b",
  "category": "core",
  "description": "Password reset flow",
  "steps": ["Reset request endpoint", "Email token generation", "Reset confirmation"],
  "passes": false
},
{
  "id": "F012c",
  "category": "integration",
  "description": "OAuth provider integration",
  "steps": ["OAuth callback handler", "Provider config", "Account linking"],
  "passes": false
}
```

**Rules:**
- Original ID keeps the most fundamental piece
- Suffixed IDs (a, b, c) for extracted work
- Each piece must be completable in one session
- Document the split in progress.txt

### 2. Add New Features

**When:** You discover work that isn't captured in the feature list.

**Protocol:**

1. Determine if this is truly new or belongs in an existing feature
2. Assign the next available ID in sequence
3. Place it in the correct category
4. Add it with `"passes": false`

```json
{
  "id": "F045",
  "category": "operations",
  "description": "Rate limiting for API endpoints",
  "steps": ["Configure rate limiter", "Add middleware", "Add rate limit headers", "Test under load"],
  "passes": false
}
```

**When to add vs. when to expand existing:**
- **Add new feature:** Distinct functionality that stands alone
- **Expand existing:** Additional steps within an already-scoped feature

**Red flag:** Adding features as an excuse to avoid finishing current work. Complete the current feature first, then add new ones.

### 3. Deprecate Features

**When:** A feature is no longer relevant (requirements changed, superseded by another approach).

**Protocol:**

1. Do NOT delete the feature — mark it deprecated
2. Add a `"deprecated"` field with the reason
3. Set `"passes": true` (it passes by not needing to exist)

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

**Why not delete?** Feature IDs are referenced in progress.txt and git history. Deleting creates gaps that confuse future sessions. Deprecating preserves the audit trail.

### 4. Re-prioritize Features

**When:** Dependencies make the current order suboptimal, or blockers require re-sequencing.

**Protocol:**

Features should generally be implemented in ID order, but sometimes you need to skip ahead. Document re-prioritization in progress.txt:

```
--- Session 2026-02-22-03 ---
Agent: Claude Opus 4.6
Worked on: Feature re-prioritization
Completed:
  - Skipping F015-F017 (blocked by external API access)
  - Prioritizing F021 (unblocks F018-F020)
  - Added dependency notes to F015, F016, F017
Blocked: F015-F017 require API credentials from user
Next: F021 - Database connection pooling
Commit: chore(project): re-prioritize features (F015-F017 blocked)
```

**Add dependency notes to blocked features:**

```json
{
  "id": "F015",
  "category": "integration",
  "description": "Exchange API data fetching",
  "steps": ["API client setup", "Authentication", "Data normalization"],
  "passes": false,
  "blocked_by": "Waiting for API credentials"
}
```

### 5. Audit Feature List

**When:** Periodically (every 10-20 features completed), or when something feels off.

**Audit checklist:**

```
1. Consistency check:
   - [ ] All passing features actually pass verify.sh
   - [ ] No features marked passing that have broken tests
   - [ ] No duplicate or overlapping features

2. Completeness check:
   - [ ] No implemented functionality missing from feature list
   - [ ] No orphaned code (code without a corresponding feature)
   - [ ] Categories are balanced (not 50 core, 2 testing)

3. Granularity check:
   - [ ] No remaining features that would take more than one session
   - [ ] No features so small they're trivial (merge with neighbors)

4. Dependency check:
   - [ ] Blocked features have documented reasons
   - [ ] No circular dependencies
   - [ ] Features in reasonable implementation order
```

**After audit, document findings:**

```
--- Session 2026-02-22-audit ---
Agent: Claude Opus 4.6
Worked on: Feature list audit
Completed:
  - Found F008 marked passing but test actually skipped — reverted to false
  - Split F034 into F034/F034a (too large for one session)
  - Deprecated F011 (superseded by F029)
  - Added 3 missing features for error handling (F046-F048)
  - Total: 48/52 features passing (92%)
Blocked: none
Next: F034 - Notification system (reduced scope)
Commit: chore(project): audit and update feature list
```

## Progress Documentation

Every features.json change gets a progress.txt entry:

```
--- Session 2026-02-22-02 ---
Agent: Claude Opus 4.6
Worked on: Feature management - split F012
Completed:
  - Split F012 (auth system) into F012, F012a, F012b, F012c
  - F012 reduced to basic login + JWT (one session scope)
  - Implemented F012 (basic login) — verify.sh passes
Blocked: none
Next: F012a - Session management
Commit: feat(project): implement basic login (F012), split auth features
```

## Common Mistakes & Rationalizations

| Excuse | Reality | Counter |
|--------|---------|---------|
| "I'll just squeeze it into one session" | Oversized features produce rushed, untested code | Split it. Two clean sessions > one messy one. |
| "Adding features slows us down" | Missing features means missing tests and undocumented work | 2 minutes to add a feature saves hours of confusion later. |
| "I'll delete the old feature" | Deleting breaks references in progress.txt and git history | Deprecate, never delete. Preserve the audit trail. |
| "Dependencies are obvious, no need to document" | Obvious to you now. Opaque to the next session. | Write it down. Takes 30 seconds. |
| "Feature list is fine, no need to audit" | Drift accumulates silently. Audit catches it early. | Audit every 10-20 features. Cheap insurance. |

## Red Flags - STOP and Reconsider

If you're thinking any of these:

- "This feature is big but I can handle it"
- "No need to split, I'm almost done"
- "I'll add the missing features later"
- "The feature list is just a guideline"
- "Auditing is overhead, let's keep building"

**All of these mean: The feature list is drifting from reality. Fix it now.**
