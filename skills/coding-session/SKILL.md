---
name: coding-session
description: Use when starting work on features in a harness-based project. Triggers when user says "work on feature", "implement", "let's start coding", or references a feature ID (F001, F002). Enforces the session ritual (read progress, one feature, verify before/after, update progress, commit) and prevents batching multiple features.
---

# Coding Session

## Overview

Follow the Anthropic long-running agent ritual for feature work. **One feature per session** - this is non-negotiable for maintaining quality and clear handoffs.

**Core principle:** Each session picks ONE feature, implements it completely, verifies it works, and leaves clear handoff notes. No shortcuts, no batching.

## When to Use

Use this skill when:
- Starting work on a feature (user says "implement F003", "work on...")
- User references a feature ID from features.json
- Beginning a coding session on a harness-based project

Do NOT use for:
- Initial project setup (use initialize-project skill)
- Exploratory research without a specific feature target
- Emergency hotfixes (though ritual still recommended)

## The Session Ritual

Follow this order exactly. Each step has a purpose.

### 1. Orient: Read progress.txt (Required)

**Before touching ANY code**, read `harness/progress.txt`.

Why this matters:
- Understand what previous sessions accomplished
- Learn from past decisions and blockers
- Avoid duplicating work or breaking patterns
- Get context on dependencies between features

**Red flag:** "I'll just start coding, progress.txt is optional"
**Reality:** Skipping context causes rework and breaks existing patterns

### 2. Select: Pick ONE Feature (The Iron Law)

Open `harness/features.json` and find the next `"passes": false` feature.

**The Rule: ONE feature per session. No exceptions.**

Why?
- Clear scope prevents feature creep
- Verification is meaningful (not testing 5 things at once)
- Handoff notes are specific (not vague summaries of bulk work)
- Failures are traceable (know exactly what broke)
- Sustainable pace (marathon, not sprint)

**Common rationalizations:**

| Excuse | Reality |
|--------|---------|
| "These 3 features are related, batching is efficient" | Related features share bugs. Implement one, verify, then build on solid foundation. |
| "I can do F001-F005 quickly" | "Quickly" = untested. One feature done right > five features done poorly. |
| "User wants multiple features" | User wants working features. One passing feature > three broken ones. |
| "I'm on a roll, let's keep going" | Momentum without verification = accumulating technical debt. |

### 3. Establish Baseline: Run verify.sh BEFORE Coding

**Before writing ANY implementation code**, run `harness/verify.sh`.

```bash
cd project-root
./harness/verify.sh
# Note the exit code and output
```

Why?
- Confirms project starts in passing state
- Establishes blame boundary (if tests fail after your work, you know you broke it)
- Reveals existing issues before you add new code

**Red flag:** "Tests pass, I don't need to run them"
**Reality:** You THINK tests pass. Verify it. Takes 30 seconds.

### 4. Implement: Write Code for ONE Feature

Read the feature description in `features.json` carefully:
- What does "done" look like for this specific feature?
- What are the explicit steps listed?
- Are there dependencies on other features?

Write:
- Implementation code
- Tests (if feature requires new tests)
- Documentation (if feature adds public API)

**Scope control:** If you realize the feature is too large during implementation, STOP. Split it into smaller features in `features.json`, then implement just the first piece.

### 5. Verify: Run verify.sh AFTER Implementation

```bash
./harness/verify.sh
# MUST exit 0 or feature is NOT done
```

**Feature is NOT done until verify.sh exits 0.**

If verify.sh fails:
- Fix the implementation
- Re-run verify.sh
- Repeat until exit 0

**Do NOT:**
- Mark feature as passing when tests fail
- Skip verify.sh "just this once"
- Commit broken code with TODO comments

### 6. Update State: Mark Feature as Passing

Only after verify.sh exits 0:

Edit `harness/features.json`:
```json
{
  "id": "F003",
  "description": "Risk management and position sizing",
  "passes": true  // Change from false to true
}
```

### 7. Document: Update progress.txt

Append to `harness/progress.txt` (do NOT edit previous entries):

```
--- Session 2026-02-16-02 ---
Agent: Claude Sonnet 4.5
Worked on: F003 - Risk management and position sizing
Completed:
  - Implemented position size calculator based on account balance
  - Added stop-loss and take-profit validation
  - Created test suite covering edge cases (zero balance, negative positions)
  - All tests passing via verify.sh
Blocked: none
Next: F004 - Backtesting framework (depends on F003 risk calculations)
Commit: feat(ai-bot-alchemy): implement risk management (F003)
```

**Required fields:**
- Session header with date
- "Worked on" - what feature(s)
- "Completed" - specific accomplishments
- "Blocked" - anything preventing progress
- "Next" - what should happen in next session
- "Commit" - the commit message used (or pending)

### 8. Commit: Save Work with Conventional Message

```bash
git add .
git commit -m "feat(project): implement feature description (F00X)

- Specific changes made
- Tests added/updated
- Any notable decisions

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>"
```

**Commit message format:**
- Type: `feat` (new), `fix` (bug), `refactor`, `test`, `docs`
- Scope: `(project-name)` matching directory
- Description: concise summary with feature ID
- Body: bullet points for details
- Co-Authored-By: attribute AI contribution

## When Feature is "Done"

A feature is complete when ALL of these are true:

- [ ] verify.sh exits 0
- [ ] features.json updated (`"passes": true`)
- [ ] progress.txt appended with session summary
- [ ] Code committed with conventional message
- [ ] No TODO comments or stub implementations
- [ ] Tests cover the feature (if tests required)

**If ANY checkbox is unchecked, the feature is NOT done.**

## Common Mistakes & Rationalizations

| Excuse | Reality | Counter |
|--------|---------|---------|
| "I'll update progress.txt later" | "Later" = never. Next session has no context. | Takes 2 minutes now. Do it before ending session. |
| "These features are tiny, I can batch them" | Tiny features accumulate. One broken feature contaminates batch. | Even tiny features deserve individual verification and commits. |
| "verify.sh passed before, no need to re-run" | Code changed. Tests might fail now. | Re-run takes 30 seconds. Skipping risks broken code. |
| "Feature mostly works, I'll mark it passing" | "Mostly" = failing. Partial features create false progress. | Finish the feature or leave `"passes": false`. Be honest. |
| "I'll commit all my changes together later" | Bulk commits lose history. Hard to debug/revert. | Commit per feature. Clear history, easy rollback. |

## Red Flags - STOP and Reconsider

If you're thinking any of these, you're cutting corners:

- "Let me just knock out a few features"
- "I'll update progress.txt in the next session"
- "verify.sh can wait until I'm done with all features"
- "These features are related, batching makes sense"
- "The user wants fast progress"
- "I'm on a roll, let's keep coding"

**All of these mean: Slow down. Follow the ritual.**

## Edge Cases

### Feature Turns Out Too Large

If during implementation you realize the feature is too big:

1. STOP implementation
2. Update features.json - split the feature into smaller pieces
3. Implement ONLY the first piece
4. Document in progress.txt: "Split F003 into F003a/F003b due to scope"
5. Next session picks up F003b

### Feature is Blocked

If you discover a blocker (missing dependency, unclear requirements):

1. STOP implementation
2. Document in progress.txt under "Blocked:"
3. Leave `"passes": false` in features.json
4. Commit any exploratory work with message: `chore(project): investigate F003 blocker`
5. Communicate blocker to user

### User Insists on Multiple Features

Push back respectfully:

"I understand you want F003, F004, and F005. The one-feature-per-session rule exists to maintain quality. Let me complete F003 properly with full verification, then we can tackle F004 in the next turn. Batching risks introducing bugs we won't catch until later."

If user overrides: document in progress.txt that you deviated from convention and why.

## Why This Ritual Matters

The ritual prevents three failure modes:

1. **Context loss** - progress.txt enables clean handoffs between sessions
2. **Quality decay** - verify.sh before/after catches regressions immediately
3. **Scope creep** - one feature per session maintains sustainable pace

Skip any step and you risk introducing bugs, losing context, or burning out.

## Real-World Impact

**Without this discipline:** Agents attempt to "finish" projects in one massive session, skip testing, forget to document, and leave the next session with no idea what happened or why tests fail.

**With this discipline:** Each session makes measurable progress on one feature, leaves passing tests, provides clear handoff notes. Project progresses steadily over weeks instead of chaotic sprints that collapse.
