---
name: design-session
description: Use when starting a new initiative or major feature that needs upfront design before any coding. Triggers when the user says "design session", "new initiative", "let's design", "plan a feature", "set up <project>", or describes a feature/system that doesn't exist yet. Drives an interactive Q&A + research session that produces docs/<initiative>/design.md and docs/<initiative>/features.json — the artifacts an implementation session will consume. Replaces the older initialize-project skill.
---

# Design Session

## Overview

An **interactive design intake**. You ask, you research, you propose, the user decides. The output is two files that a future implementation session can pick up cold:

- `docs/<initiative>/design.md` — the "what and why"
- `docs/<initiative>/features.json` — the ordered, granular feature list

This skill is the opposite of a template-filling exercise. Most of the value is in the questions you ask and the research you do between them. The doc is synthesis, not boilerplate.

## When to Use

- Starting a new initiative or major feature
- User describes a system that doesn't exist yet
- Before any implementation session can begin on greenfield work
- User says "design session", "let's design", "plan this out", "new project"

## When Not to Use

- Bug fixes — just fix them
- In-progress feature work — use the implementation skill
- Tiny one-off scripts — overhead isn't worth it
- Pure exploration with no intent to ship

## The Session — 4 Phases

Run the phases in order. Don't skip Phase 1 to get to the questions faster. Don't skip Phase 3 because the approach feels obvious.

### Phase 1: Context Gathering (research first)

Before asking the user anything, read what's already there.

Do at minimum:
- Read `CLAUDE.md` and `README.md` if present
- Check `docs/` for existing initiative directories — does this overlap with one?
- Glob/Grep for related code: if the user said "auth", search for existing auth code; if "billing", check for payment integrations
- Read `package.json` / `pyproject.toml` / equivalent to learn the stack and existing dependencies
- If the user named a specific file or area, read it

Report what you found in **2-3 sentences** before moving to Phase 2. Example:

> Found an existing `docs/billing/` initiative with Stripe integration features (8 of 12 passing). Codebase uses Next.js 15 + Prisma + Postgres. No existing webhook handlers. Ready to ask discovery questions.

If you find a duplicate or overlapping initiative, stop and ask the user whether to extend the existing one instead of creating a new one.

### Phase 2: Forcing Questions (Q&A)

Ask these five questions, in order, using `AskUserQuestion`. Each question is a single tool call, not a wall of text. **Do brief research between questions** when the previous answer opens a new question — e.g. user mentions a library you've never seen, look it up before Q3.

**Q1 — Problem & scope.** What specifically are we solving? What is explicitly out of scope? (Use 2-4 options that bracket different scope sizes — narrowest wedge vs. full vision.)

**Q2 — Constraints.** Tech stack, deadlines, performance budget, team size, dependencies that must hold. (Offer options when there's a real choice — e.g. SSR vs. SPA vs. static — otherwise ask open-ended.)

**Q3 — Integration points.** What existing systems does this touch? What contracts must hold? What can break? (Research the codebase first to surface the actual integration surface, then ask the user to confirm or correct.)

**Q4 — Acceptance criteria.** How will we know it works? What's the smoke test that proves it ships? (Concrete user-visible outcomes, not "tests pass".)

**Q5 — Risk & unknowns.** What could go wrong? What do we genuinely not know yet? What needs prototyping before committing? (Use this to surface things that should become research spikes vs. features.)

After each answer, note the response in a working scratchpad (memory or a temp file in `.claude/tasks/` — don't pollute `docs/` yet). The scratchpad becomes the raw material for Phase 4.

### Phase 3: Alternatives (mandatory)

Generate **2-3 viable approaches** based on what you learned. Even if one approach feels obvious, name the rejected ones — that's what makes the chosen one defensible later.

Present via `AskUserQuestion` with concise pros/cons per option. Examples of axes to vary:
- Build-vs-buy (write our own X vs. use library Y vs. SaaS Z)
- Architecture (monolith vs. service-per-domain vs. event-driven)
- Phasing (ship the wedge first vs. build the full thing)
- Data model (normalized schema vs. denormalized for read perf vs. event-sourced)

Let the user pick. If they pick something you didn't list, that's a fine outcome too — note their reasoning.

### Phase 4: Write Artifacts

Create the two files. Both must exist before this phase is complete.

#### `docs/<initiative>/design.md`

Free-form Markdown. Include at least these sections:

```markdown
# <Initiative Name>

## Problem & Scope
{from Q1 — what we're solving, what we're explicitly not}

## Constraints
{from Q2 — stack, deadlines, budgets}

## Integration Points
{from Q3 — what this touches, contracts that must hold}

## Approaches Considered
{from Phase 3 — the 2-3 alternatives with pros/cons}

## Chosen Approach
{the option the user picked, with reasoning}

## Acceptance Criteria
{from Q4 — concrete signals that this ships}

## Risks & Open Questions
{from Q5 — what could break, what needs spiking}

## Data Models / Key Interfaces
{schemas, type signatures, endpoint shapes if applicable}
```

#### `docs/<initiative>/features.json`

Ordered, machine-parseable. Each feature should be completable in one implementation session (1-2 hours).

```json
[
  {
    "id": "F001",
    "category": "infrastructure",
    "description": "Install dependencies (ai, @ai-sdk/react)",
    "steps": ["pnpm add ai @ai-sdk/react", "Verify import resolution"],
    "passes": false
  },
  {
    "id": "F002",
    "category": "core",
    "description": "Chat models in Prisma schema",
    "steps": ["Add Conversation + Message models", "Run pnpm db:generate", "Run migration"],
    "passes": false,
    "depends": ["F001"]
  }
]
```

**Feature granularity guidelines** (calibrate to scope from Q1):

| Initiative size | Feature count |
|---|---|
| Small (CLI utility, single feature) | 15-30 |
| Medium (API service, integration) | 40-100 |
| Large (full app, multi-system) | 150+ |

If your feature count is below the guideline for the scope, you're under-granular — agents will try to one-shot the project. Split until each feature fits in one session.

**Required categories to cover** (skip those that genuinely don't apply):
- infrastructure (deps, config, env, scaffolding)
- core (the actual feature work)
- integration (external APIs, DB, services)
- ui (if user-facing)
- testing (test setup, fixtures, coverage)
- operations (logging, monitoring, deployment)

#### Commit

```bash
git add docs/<initiative>/
git commit -m "design(<initiative>): initial design session

Approach: <one-line summary of chosen approach>
Features: <count> defined across <N> categories
"
```

## Don't

- **Don't write design.md before asking the forcing questions.** The doc is synthesis, not a template you fill in. If you start writing before Phase 2 ends, you're guessing.
- **Don't generate features.json with too few features.** If the scope is genuinely tiny (under 15 features), ask the user whether a design session is the right tool — maybe just implement it directly.
- **Don't skip the alternatives phase.** Even when there's an obvious approach, naming the rejected ones surfaces hidden tradeoffs and makes the chosen path defensible to future-you.
- **Don't ask everything in one giant question.** Five focused `AskUserQuestion` calls with research between them beats one wall-of-text every time.
- **Don't fabricate constraints.** If you don't know the deadline, ask. If you don't know the stack, read `package.json` first, then ask if it's ambiguous.
- **Don't pollute `docs/<initiative>/` with scratch notes during the session.** Use a temp file in `.claude/tasks/` for working state. Only the final `design.md` and `features.json` should land in `docs/`.
- **Don't start coding in the same session.** Once the artifacts are committed, the next session uses the implementation skill. Keep the seam clean — design sessions design, implementation sessions implement.
