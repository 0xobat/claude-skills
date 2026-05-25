# Workflow Convention for Claude Code Sessions

This document describes a lightweight convention for managing design and implementation work across Claude Code sessions. It replaces heavier harness-based approaches (init.sh, verify.sh, progress.txt) with a docs-first structure that any coding agent can discover via onboarding.

---

## Core Principle

Design and implementation are separate sessions. Design sessions produce artifacts that implementation sessions consume. Progress is tracked by appending to a log, not by maintaining complex state.

## Session Types

### Design Session

**Purpose:** Produce a design spec and feature list that a coding agent can take and run with.

**Flow:** `onboard` -> brainstorm -> produce `design.md` + `features.json`

**Output:**

- `docs/<initiative>/design.md` — Architecture, decisions, constraints, data models, acceptance criteria
- `docs/<initiative>/features.json` — Ordered, machine-parseable feature list

### Implementation Session

**Purpose:** Implement features from the design spec, one at a time or in small batches.

**Flow:** `onboard` -> read `design.md` + `features.json` -> implement -> append to `progress.md`

**Output:**

- Code changes committed to git
- `features.json` updated (`"passes": true` for completed features)
- `docs/<initiative>/progress.md` entry appended

## Directory Layout

```
docs/
  <initiative>/           # e.g., ai-advisor, plaid-integration
    design.md             # The "what and why" — read-only during implementation
    features.json         # The "what to build" — updated as features complete
    progress.md           # The "what happened" — append-only session log
```

Each project initiative gets its own directory. The initiative name should be descriptive and match how you'd refer to the work in conversation.

## File Formats

### design.md

Free-form markdown. Should contain enough context that a coding agent starting fresh (via onboard) can understand:

- What is being built and why
- Architecture decisions and constraints
- Data models or schema changes
- Key integration points
- Acceptance criteria for the overall initiative

### features.json

```json
[
  {
    "id": "F001",
    "category": "infrastructure",
    "description": "Install AI SDK dependencies: ai, @ai-sdk/react",
    "steps": ["pnpm add ai @ai-sdk/react", "Verify import resolution"],
    "passes": false
  },
  {
    "id": "F002",
    "category": "infrastructure",
    "description": "Add chat models to Prisma schema",
    "steps": ["Add models to schema.prisma", "Run pnpm db:generate"],
    "passes": false,
    "depends": ["F001"]
  }
]
```

Fields:

- `id` — Unique feature identifier (F001, F002, ...)
- `category` — Grouping label (infrastructure, core, ui, tools, etc.)
- `description` — What to build, concise but complete
- `steps` — Ordered implementation steps (human-readable)
- `passes` — `false` until implemented and verified, then `true`
- `depends` — Optional array of feature IDs that must be completed first

### progress.md

Append-only log. Each implementation session adds a dated entry:

```markdown
## Session YYYY-MM-DD-NN

- **Agent:** Claude Opus 4.6
- **Completed:** F001, F002 — installed deps, added schema
- **Blocked:** none
- **Next:** F004 — system prompt module
- **Commit:** abc1234 feat(ai): add chat models
```

The `NN` suffix handles multiple sessions on the same day (01, 02, etc.).

## How Onboarding Discovers Context

When an agent runs `onboard` at the start of a session, it should:

1. Read `CLAUDE.md` for project instructions
2. Explore the codebase structure
3. Check `docs/` for initiative directories
4. Read `design.md` for architectural context
5. Read `features.json` to understand what's done (`passes: true`) and what's next
6. Read `progress.md` for recent session context and blockers

This gives the agent full context without requiring custom scripts or task-tracking infrastructure.

## What This Replaces

| Old                                  | New                                               |
| ------------------------------------ | ------------------------------------------------- |
| `harness/<project>/features.json`    | `docs/<project>/features.json`                    |
| `harness/<project>/init.sh`          | Not needed — use package.json scripts             |
| `harness/<project>/verify.sh`        | Not needed — use `pnpm check-types && pnpm build` |
| `harness/<project>/progress.txt`     | `docs/<project>/progress.md`                      |
| `.claude/tasks/<task>/onboarding.md` | Generated fresh each session by `onboard`         |
| `.claude/tasks/<task>/plan.md`       | `docs/<project>/design.md` + features.json        |
| `docs/TODO.md`                       | Consolidated into `progress.md`                   |

## Guidelines

- **One initiative directory per major effort.** Don't create one for every bug fix.
- **Design docs are living documents** during design sessions, then frozen during implementation. If the design needs to change significantly, start a new design session.
- **Features.json is the source of truth** for what's done. Agents should update `passes` immediately after verifying a feature works.
- **Progress.md is append-only.** Never edit previous entries. This creates a reliable audit trail.
- **Don't over-structure.** If a task is small enough to describe in a sentence, it doesn't need this convention. Just do it.
