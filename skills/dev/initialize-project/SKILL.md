---
name: initialize-project
description: Use when bootstrapping a new project in the monorepo that needs harness structure (init.sh, verify.sh, features.json, progress.txt). Triggers when user says "set up new project", "create project", "initialize", or "bootstrap". Prevents skipping harness components, inadequate feature granularity, and non-idempotent setup scripts.
---

# Initialize Project

## Overview

Bootstrap a new project's harness structure following the Anthropic long-running agent pattern. **Every harness component is mandatory** - no optional files, no "add later" promises.

**Core principle:** The harness IS the product at initialization. Code can be minimal stubs, but harness files must be complete and correct.

## When to Use

Use this skill when:
- User asks to "set up", "create", "initialize", or "bootstrap" a new project
- Adding a new project to the monorepo
- Creating harness structure for existing code

Do NOT use for:
- Updating existing project harness (use coding-session skill)
- Non-harness project setup
- One-off scripts or utilities

## The Non-Negotiable Four

Every harness requires exactly four files. No shortcuts, no "later":

```
<project>/harness/
├── init.sh         # Idempotent environment setup
├── verify.sh       # Exit 0 = pass, non-zero = fail
├── features.json   # Sufficient granular features (see guidelines)
└── progress.txt    # Session handoff log
```

**Missing any file = incomplete harness = blocked from feature work.**

## Creation Order & Checklist

Follow this order exactly:

### 1. features.json (Most Important, Do First)

Create **sufficiently granular features** to prevent "one-shot" attempts.

**Feature count guidelines:**
- **Small projects/utilities**: 20-40 features (e.g., CLI tool, simple bot)
- **Medium projects**: 60-120 features (e.g., API service, data pipeline)
- **Large projects**: 200+ features (e.g., full DeFi bot, multi-chain system)

**The key principle:** Features should be granular enough that agents cannot "one-shot" the entire project in a single session. If you can see yourself completing all features in one marathon session, add more granularity.

**Feature structure:**
```json
[
  {
    "id": "F001",
    "category": "infrastructure",
    "description": "UV package manager installs dependencies",
    "steps": ["Install UV", "Run uv sync", "Verify lockfile"],
    "passes": false
  }
]
```

**Categories to cover:**
- Infrastructure (30-40): Setup, config, logging, health checks
- Core functionality (40-60): Main features split atomically
- Integration (30-50): External APIs, databases, services
- Risk/Safety (20-30): Validation, limits, circuit breakers
- Testing (20-30): Test infrastructure, coverage, fixtures
- Operations (20-30): Monitoring, alerts, deployment

**Granularity test:** Each feature should be completable in 1-2 hours. If it takes a day, split it.

### 2. init.sh (Idempotent Setup)

**Must be idempotent** - safe to run multiple times.

```bash
#!/bin/bash
set -e

# Check preconditions
command -v uv >/dev/null 2>&1 || { echo "UV not found"; exit 1; }

# Idempotent install
if [ ! -f "uv.lock" ]; then
  uv sync
else
  echo "✓ Dependencies already installed"
fi

# Idempotent env file
if [ ! -f ".env" ]; then
  cp .env.example .env 2>/dev/null || echo "API_KEY=" > .env
else
  echo "✓ .env exists"
fi

echo "✓ <project> initialized"
```

**Requirements:**
- Executable (`chmod +x init.sh`)
- Exit codes: 0 = success, non-zero = failure
- Check before action (if/then, not blind execution)
- Meaningful success message

### 3. verify.sh (Real Checks From Day One)

**No "permissive stubs"** - this must have actual verification logic.

```bash
#!/bin/bash
set -e

echo "Running verification..."

# Real checks, not stubs
if [ -f "pyproject.toml" ]; then
  uv run pytest tests/ || exit 1
  uv run ruff check . || exit 1
else
  npm test || exit 1
  npm run lint || exit 1
fi

# Build check if applicable
if [ -f "tsconfig.json" ]; then
  npm run build || exit 1
fi

echo "✓ All checks passed"
exit 0
```

**Requirements:**
- Must exit 0 on pass, non-zero on failure
- At minimum: Run tests, run linter
- If no tests exist yet, create a trivial passing test first

### 4. progress.txt (Session Log)

Initialize with session zero entry:

```
--- Session 2026-02-16-01 ---
Agent: Claude Sonnet 4.5
Worked on: Harness initialization
Completed: Created all 4 harness files (237 features defined)
Blocked: none
Next: F001 - Infrastructure setup
Commit: init(project): harness initialization
```

**Format requirements:**
- Session header with date
- "Worked on", "Completed", "Blocked", "Next", "Commit" sections
- Append-only - never edit previous sessions
- Each session creates a new entry

## Common Mistakes & Rationalizations

| Excuse | Reality | Counter |
|--------|---------|---------|
| "Let's start with 10-20 features, expand later" | "Later" never comes. Match features to project scope. | Use feature count guidelines: small=20-40, medium=60-120, large=200+. If you can "one-shot" all features in one session, add more granularity. |
| "verify.sh can be a stub - we'll add tests later" | Stub verify.sh never gets real checks. | Create trivial passing test NOW. verify.sh must have real logic from day one. |
| "Init script works, don't need idempotency yet" | "Yet" = never. First run is easiest time to do it right. | Add `if [ ! -f ]` checks. Takes 2 minutes, prevents hours of debugging. |
| "Code stubs can be garbage at bootstrap" | Garbage foundation = garbage codebase. | Minimal ≠ garbage. Write 10 lines correctly instead of 100 lines poorly. |
| "We can add progress.txt when we start features" | Session 1 ends, Session 2 has no context. Lost work. | progress.txt is the handoff. Create it now or lose all context. |

## Red Flags - STOP and Reconsider

If you're thinking any of these, you're cutting corners:

- "Start permissive, tighten later"
- "Just get something working"
- "Don't overthink it" = skip critical thinking
- "We can always add X later"
- "The user is in a hurry"
- "I've done this before, I know the pattern"

**All of these mean: Slow down. Follow the checklist.**

## Validation Before Proceeding

Run this mental checklist before claiming "initialization complete":

- [ ] features.json exists with sufficient features for project scope (use guidelines: small=20-40, medium=60-120, large=200+)
- [ ] init.sh is executable and idempotent
- [ ] verify.sh has real checks (tests + linter minimum)
- [ ] progress.txt has session zero entry
- [ ] Ran init.sh successfully
- [ ] Ran verify.sh successfully (exit code 0)
- [ ] Committed with message: `init(project): harness initialization`

**If any checkbox is unchecked, initialization is NOT complete.**

## Why This Matters

The harness convention prevents three failure modes:

1. **Context loss** - progress.txt enables session handoffs
2. **Scope creep** - Granular features prevent "one-shot" attempts
3. **Quality decay** - verify.sh catches regressions immediately

Skip any component and you lose these guarantees.

## Real-World Impact

**Without this discipline:** Agents lose context between sessions, attempt to complete entire projects in one turn, ship broken code.

**With this discipline:** Each session picks one feature, makes incremental progress, leaves project in passing state. Sustainable velocity over months.
