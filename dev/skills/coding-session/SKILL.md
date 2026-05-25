---
name: coding-session
description: Use when starting work on a feature from a docs-first initiative. Triggers when the user says "work on feature", "implement", "let's start coding", or references a feature ID (F001, F002). Enforces the one-feature-per-session ritual — read context, verify baseline, implement, verify again, update progress, commit.
---

# Coding Session

## Overview

One feature per session. Read context, verify baseline, implement, verify again, document, commit. The discipline is what keeps the project shippable across sessions — without it, work compounds into untested mush.

Assumes the docs-first layout: `docs/<initiative>/{design.md, features.json, progress.md}`. See `workflow-convention.md` at the repo root.

## When to Use

- Implementing a feature from `docs/<initiative>/features.json`
- User says "implement F003", "work on the next feature", etc.
- Beginning a coding session on an existing initiative

## When Not to Use

- Initial design (use design-session)
- Exploratory research without a specific feature target
- Cross-cutting refactors (split into features first via manage-features)

## The Ritual

### 1. Orient — read context

Before touching any code:

```bash
cat docs/<initiative>/progress.md | tail -40
cat docs/<initiative>/design.md
cat docs/<initiative>/features.json
git log --oneline -10
```

You want to know: what was done last, what's coming next, what constraints the design fixed.

### 2. Pick ONE feature

Open `features.json`, find the next `"passes": false` feature whose `depends` are all satisfied. That's your feature.

**One feature per session. No exceptions.**

Why: clear scope, meaningful verification, traceable failures, sustainable pace. "These three features are related, I'll batch them" produces three half-tested features and one shared bug.

### 3. Verify baseline

Run the project's verify command before writing any implementation code:

```bash
pnpm check-types && pnpm build   # or pnpm test, cargo test, pytest — whatever the project uses
```

This is the blame boundary — if it passes now and fails after your work, you broke it. If it fails now, stop and recover (see recover-session) before adding more code on top of broken state.

### 4. Implement

Read your feature's `description` and `steps` carefully. What does "done" look like for this specific feature?

Write the code, tests, docs if needed.

**Scope control:** if the feature turns out too big during implementation, stop. Split it (see manage-features), then implement only the first piece.

### 5. Verify after

Run the same command. **Must pass.**

```bash
pnpm check-types && pnpm build
```

If it fails: fix and re-run until it passes. Don't mark the feature done with failing checks.

### 6. Update features.json

Set your feature's `passes` to `true`:

```json
{ "id": "F003", "description": "...", "passes": true }
```

**Only change the `passes` field for your one feature.** Don't touch anything else in `features.json`.

### 7. Append to progress.md

Add a session entry. **Do not edit previous entries** — this is an append-only log.

```markdown
## Session YYYY-MM-DD-NN

- **Agent:** <model>
- **Completed:** F003 — risk management & position sizing
  - Position sizer based on account balance
  - Stop-loss / take-profit validation
  - Test suite covering edge cases
- **Blocked:** none
- **Next:** F004 — backtesting framework (depends on F003)
- **Commit:** feat(<initiative>): implement risk management (F003)
```

### 8. Commit

```bash
git add .
git commit -m "feat(<initiative>): <description> (<ID>)"
```

Conventional message format: `feat` / `fix` / `refactor` / `test` / `docs` + scope + description with feature ID.

## A Feature Is Done When

All of these are true:

- [ ] Verify command passes
- [ ] `features.json` has `"passes": true` for this feature
- [ ] `progress.md` has a session entry
- [ ] Code is committed with a conventional message
- [ ] No TODO comments or stub implementations left behind
- [ ] Manually exercised the feature end-to-end — not just relying on the verify command

If any box is unchecked, the feature is not done.

## Edge Cases

**Feature too large.** Stop. Split it via manage-features. Implement only the first piece. Document the split in `progress.md`.

**Feature blocked.** Stop. Set `"blocked_by": "..."` in `features.json`. Document in `progress.md` under "Blocked:". Commit any exploratory work as `chore(<initiative>): investigate F003 blocker`. Tell the user.

**User insists on multiple features in one session.** Push back: batching risks bugs we won't catch until later. If overridden, document the deviation in `progress.md`.

## Don't

- **Don't skip the orient step.** "Progress.md is optional" leads to duplicating work and breaking patterns the previous session established.
- **Don't batch features.** Even tiny features deserve individual verification and a clean commit. Five batched features = five untested features.
- **Don't skip verify before coding.** Takes 30 seconds; reveals existing issues and sets your blame boundary.
- **Don't mark a feature passing when the verify command fails.** "Mostly works" = failing. Be honest in `features.json` or you create false progress.
- **Don't commit everything in one bulk commit at the end.** Per-feature commits give you clean history and easy rollback.
- **Don't edit previous entries in `progress.md`.** It's append-only on purpose — the audit trail breaks otherwise.
- **Don't trust the verify command alone.** It checks structure; you still need to exercise the feature like a user would.
