---
name: recover-session
description: Use when the project's verify command fails after a feature lands, a change broke unrelated code, or you inherited a project in a failing state. Triggers on "tests are failing", "something broke", "revert", "recover", "rollback". Provides a structured diagnose-isolate-fix protocol that uses git deliberately rather than nuking work.
---

# Recover Session

## Overview

When the verify command fails and you can't immediately see why, follow this protocol instead of flailing. Git is your safety net — use it deliberately.

**Diagnose before you fix. Isolate before you revert. Never lose working code to fix broken code.**

See `workflow-convention.md` for the docs-first layout this skill assumes.

## When to Use

- The verify command fails after implementing a feature
- A change broke unrelated features (regression)
- You inherited a project where the previous session left things broken
- You need to roll back to a known good state
- Tests pass locally but the feature doesn't actually work

## When Not to Use

- Normal verify failures during active implementation — just fix the code
- Initial project setup issues (use design-session)
- Feature work (use coding-session)

## The Protocol

### 1. Stop and assess

Before touching any code, gather information:

```bash
# What's actually failing?
pnpm check-types && pnpm build 2>&1 | tee /tmp/verify-output.txt  # or the project's verify command

# What changed since last known good state?
git log --oneline -10
git diff --stat HEAD~1

# What does progress.md say?
cat docs/<initiative>/progress.md | tail -30
```

Note (mentally or in scratch):
- Which specific checks fail?
- What was the last successful commit?
- What changed between then and now?

### 2. Identify the blast radius

| Pattern | Likely cause | Next step |
|---|---|---|
| One test or check fails | Bug in the new code | Step 3a |
| Multiple tests fail, build broken | Structural issue or bad dep | Step 3b |
| Previously-passing features now fail | Regression from new code | Step 3c |

### 3a. Fix an isolated failure

1. Read the error carefully — what's the actual failure?
2. Check the file(s) changed in the last commit
3. Fix
4. Re-run the verify command
5. Continue the coding-session ritual (update `progress.md`, commit)

**Time limit:** if you can't fix it in 15 minutes of focused effort, escalate to 3b.

### 3b. Roll back to last known good state

When forward progress isn't working:

```bash
# Find last passing commit
git log --oneline -20

# Check verify at a candidate commit WITHOUT losing current work
git stash
git checkout <candidate-commit>
pnpm check-types && pnpm build   # confirm it actually passes
git checkout -                   # back to current branch
git stash pop
```

Once you've identified a known good commit:

```bash
# Safest: create a recovery branch first
git branch recovery-backup
git reset --hard <last-good-commit>
# Re-apply only what worked, deliberately
```

Document the rollback in `progress.md`.

### 3c. Isolate a regression with git bisect

When new code broke old code and you're not sure which commit:

```bash
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-commit>

# At each step:
pnpm check-types && pnpm build
# If it passes: git bisect good
# If it fails:  git bisect bad

git bisect reset
```

Once you've found the breaking commit:
1. Understand WHY it broke (not just what)
2. Fix the root cause — don't just blindly revert
3. If the fix is non-obvious, revert the breaking commit and re-implement properly

## Documenting Recovery

Append to `docs/<initiative>/progress.md`:

```markdown
## Session 2026-02-22-recovery

- **Agent:** <model>
- **Worked on:** Recovery — verify failures after F007
- **Root cause:** F007 migration broke F003 config loader (shared env vars)
- **Recovery action:** Reverted F007, re-implemented with isolated env namespace
- **Completed:**
  - Diagnosed regression with `git bisect` (breaking commit: a3f8b21)
  - Rolled back to last good state (7c2e1f4)
  - Re-implemented F007 with namespace isolation
  - Verify passing
- **Next:** F008 — API rate limiting
- **Commit:** fix(<initiative>): re-implement F007 with isolated env namespace
```

Required for recovery entries: **root cause** and **recovery action**, in addition to the usual fields.

## When to Escalate to the User

Escalate when:
- You followed the protocol and can't identify root cause
- The last known good commit also fails (the project itself is broken outside your scope)
- Recovery would require changes outside the initiative
- You've spent more than 30 minutes without progress

How to escalate: document everything you tried in `progress.md`, hand the user the failing output, the git log, and a specific question — not "it's broken, what do I do?".

## Don't

- **Don't "just revert everything".** You'll lose working code from multiple sessions. Diagnose first, then surgically revert.
- **Don't add a fix on top of broken state.** Fixes layered on a broken foundation compound problems. Get back to green first, then build.
- **Don't skip the failing test "for now".** Skipped tests never get fixed. Quality decay starts there. Either fix the test or revert the code that broke it.
- **Don't re-run hoping the failure is flaky.** If it failed once with no infrastructure cause, it's a real failure. Investigate.
- **Don't escalate without details.** "It's broken" isn't a question. Bring the failing output, the diff, what you tried, and a specific ask.
