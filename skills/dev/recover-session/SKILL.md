---
name: recover-session
description: Use when verify.sh fails repeatedly, a feature breaks unrelated code, or the project is in a bad state. Triggers when user says "tests are failing", "something broke", "revert", "recover", or "rollback". Provides a structured protocol for diagnosing failures, isolating regressions, and restoring the project to a known good state using git.
---

# Recover Session

## Overview

Structured error recovery for harness-based projects. When verify.sh fails and you can't immediately see why, **follow this protocol instead of flailing.** Git is your safety net — use it deliberately.

**Core principle:** Diagnose before you fix. Isolate before you revert. Never lose working code to fix broken code.

## When to Use

Use this skill when:
- verify.sh fails after implementing a feature
- A change broke unrelated features (regression)
- You inherit a project in a failing state (previous session left it broken)
- You need to revert to last known good state
- Tests pass locally but the feature doesn't actually work

Do NOT use for:
- Normal verify.sh failures during active implementation (just fix the code)
- Initial project setup issues (use initialize-project skill)
- Feature work (use coding-session skill)

## The Recovery Protocol

Follow this order. Do NOT skip to "just revert everything."

### 1. Stop and Assess

**Before touching ANY code**, gather information:

```bash
# What's actually failing?
./harness/verify.sh 2>&1 | tee /tmp/verify-output.txt

# What changed since last known good state?
git log --oneline -10
git diff --stat HEAD~1

# What does progress.txt say about last session?
cat harness/progress.txt | tail -30
```

**Write down (or note mentally):**
- Which specific tests/checks fail?
- What was the last successful commit?
- What changed between then and now?

**Red flag:** "I'll just revert everything and start over"
**Reality:** You'll lose working code. Diagnose first.

### 2. Identify the Blast Radius

Determine if the failure is **isolated** or **widespread**:

**Isolated failure** (one test, one check):
- Likely a bug in the new code
- Fix is usually straightforward
- Proceed to Step 3a

**Widespread failure** (multiple tests, build broken):
- Likely a structural issue or bad dependency
- May need rollback
- Proceed to Step 3b

**Regression** (previously passing features now fail):
- New code broke old code
- Need to isolate the breaking change
- Proceed to Step 3c

### 3a. Fix Isolated Failure

For a single failing test or check:

1. Read the error message carefully — what's the actual failure?
2. Check the specific file(s) changed in the last commit
3. Fix the issue
4. Run verify.sh
5. If fixed, continue with coding-session ritual (update progress, commit)

**Time limit:** If you can't fix it in 15 minutes of focused effort, escalate to 3b.

### 3b. Rollback to Last Known Good State

When the project is too broken to fix forward:

```bash
# Find last passing commit
git log --oneline -20

# Check verify.sh at a specific commit WITHOUT losing current work
git stash
git checkout <last-good-commit>
./harness/verify.sh  # Confirm it actually passes
git checkout -  # Return to current branch
git stash pop
```

**If last good commit passes:**

```bash
# Option A: Soft reset (keep changes as unstaged)
git reset --soft <last-good-commit>
# Now you can selectively re-apply changes

# Option B: Create a recovery branch (safest)
git branch recovery-backup  # Save current state
git reset --hard <last-good-commit>
# Cherry-pick or manually re-apply what worked
```

**Always document the rollback in progress.txt.**

### 3c. Isolate Regression with Git Bisect

When new code broke old code and you're not sure which change caused it:

```bash
# Find the breaking commit
git bisect start
git bisect bad HEAD
git bisect good <last-known-good-commit>

# At each step, run verify.sh
./harness/verify.sh
# If passes: git bisect good
# If fails: git bisect bad

# When found:
git bisect reset
```

**After identifying the breaking commit:**
1. Understand WHY it broke (not just WHAT)
2. Fix the root cause (don't just revert blindly)
3. If fix is non-obvious, revert the breaking commit and re-implement properly

## Progress Documentation

After any recovery, append to progress.txt:

```
--- Session 2026-02-22-recovery ---
Agent: Claude Opus 4.6
Worked on: Recovery - verify.sh failures after F007 implementation
Root cause: F007 database migration broke F003 config loader (shared env vars)
Recovery action: Reverted F007, re-implemented with isolated env namespace
Completed:
  - Diagnosed regression using git bisect (breaking commit: a3f8b21)
  - Rolled back to last good state (commit: 7c2e1f4)
  - Re-implemented F007 with proper env isolation
  - All tests passing via verify.sh
Blocked: none
Next: F008 - API rate limiting
Commit: fix(project): re-implement F007 with isolated env namespace
```

**Required fields for recovery sessions:**
- "Root cause" — what actually went wrong
- "Recovery action" — what you did to fix it
- Standard fields (Worked on, Completed, Blocked, Next, Commit)

## Common Mistakes & Rationalizations

| Excuse | Reality | Counter |
|--------|---------|---------|
| "I'll just revert everything" | Loses working code from multiple sessions | Diagnose first. Surgical revert > nuclear option. |
| "It worked before, I'll just re-run" | Flaky tests need fixing, not re-running | If verify.sh fails, something is wrong. Investigate. |
| "Let me add a quick fix on top" | Fixes on top of broken code compound problems | Understand root cause before applying fixes. |
| "I'll skip the failing test for now" | Skipped tests never get fixed. Quality decay starts here. | Fix the test or revert the code. No middle ground. |
| "This isn't related to my changes" | It probably is. Check git diff carefully. | If truly unrelated, document it and create a new feature for the fix. |

## Red Flags - STOP and Reconsider

If you're thinking any of these, you're about to make things worse:

- "Let me just try one more thing" (after 3+ failed attempts)
- "I'll comment out the failing test"
- "This test is flaky anyway"
- "I'll fix it in the next session"
- "Reverting is giving up"

**All of these mean: Step back. Follow the protocol from Step 1.**

## When to Escalate to User

Escalate if:
- You've followed the full protocol and can't identify root cause
- The last known good commit also fails (harness itself is broken)
- Recovery requires changes outside the project scope
- You've spent more than 30 minutes in recovery without progress

**How to escalate:**
1. Document everything you've tried in progress.txt
2. Provide the user with: failing output, git log, what you've tried
3. Ask specific questions (not "it's broken, what do I do?")
