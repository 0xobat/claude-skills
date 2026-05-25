---
name: team-lead
description: Use when 3+ independent features from a docs-first initiative are ready to implement in parallel. Triggers when the user says "team session", "parallel features", "swarm this", "use agents", or "batch with worktrees". Dispatches agents in isolated git worktrees to implement features concurrently, then merges results back to main with verification.
---

# Team Lead

## Overview

Orchestrate parallel feature work across agents in isolated git worktrees. Each agent picks up one feature from `docs/<initiative>/features.json`, works in its own worktree, and reports back. The team lead's job is to batch the work into dependency-ordered waves, dispatch, merge as agents complete, and keep main green.

See `workflow-convention.md` at the repo root for the docs-first artifact layout this skill assumes.

## When to Use

- 3+ independent features in `docs/<initiative>/features.json` with `"passes": false`
- Main is in a passing state (build + type-check green)
- Features can be grouped into dependency-ordered waves
- User explicitly asks for parallel/team/swarm execution

## When Not to Use

- Single feature work — use the implementation skill instead
- Features with tight interdependencies that can't be waved
- Main is currently broken — fix it first (use recover-session)
- Fewer than 3 features — overhead of team coordination isn't worth it

## Prerequisites

Before dispatching anything, confirm:

- [ ] Project build + type-check pass on current main (e.g. `pnpm check-types && pnpm build`)
- [ ] `docs/<initiative>/features.json` has 3+ features with `"passes": false`
- [ ] `docs/<initiative>/progress.md` exists and reflects current state
- [ ] You've read enough of the features to know what blocks what

If any prerequisite fails, stop and fix it with the appropriate skill.

## The Workflow

### Phase 1: Orient

```bash
# Read state
cat docs/<initiative>/progress.md | tail -40
cat docs/<initiative>/features.json
git log --oneline -10

# Confirm baseline (use the project's actual verify command)
pnpm check-types && pnpm build   # or equivalent
```

Record the baseline commit hash — it's your rollback anchor if a merge corrupts main:

```bash
git rev-parse HEAD
```

If the baseline doesn't pass, stop here.

### Phase 2: Batch into Waves

Group the `"passes": false` features into **waves** — dependency-ordered batches that can run in parallel within each wave.

**Wave rules:**
- Features within a wave must be independent: no shared files, no chain dependencies
- Wave N+1 may depend on Wave N — all of Wave N must merge before Wave N+1 starts
- Default to 3 agents per wave; cap at 5 (more = merge pain, diminishing returns)

**Quick dependency check:** any two features that modify the same file, share a schema, or one consumes the other's output → put them in different waves.

Example wave plan:
```
Wave 1 (3 agents): F008 Redis pool · F009 health check · F010 request logging
Wave 2 (2 agents, depends on Wave 1): F011 cache invalidation · F012 rate limiting
```

### Phase 3: Present Plan & Confirm

Show the user:
- The wave plan (features per wave)
- Why this ordering (dependency reasoning, one sentence)
- Any features you're deferring and why

**Wait for explicit confirmation before dispatching.** If the user modifies the plan, update accordingly — they know the codebase better than you do.

### Phase 4: Dispatch

#### Create the team

```
TeamCreate:
  team_name: "<initiative>-team-session"
  description: "Parallel feature implementation for <initiative>"
```

#### Spawn one agent per feature in the current wave

```
Task tool:
  subagent_type: "general-purpose"
  isolation: "worktree"
  team_name: "<initiative>-team-session"
  name: "agent-<N>"
  mode: "bypassPermissions"
  prompt: <agent briefing below>
```

**`isolation: "worktree"` is non-negotiable** — each agent needs its own copy of the repo or they will clobber each other.

#### Agent briefing template

```
You are implementing one feature in a docs-first initiative.

Your assignment:
- Initiative: <initiative-name>
- Feature: <ID> — <description from features.json>
- Steps: <steps from features.json>

Workflow:
1. `pwd` — confirm you're in an isolated worktree
2. Read docs/<initiative>/design.md and docs/<initiative>/progress.md for context
3. Read your feature in docs/<initiative>/features.json
4. Run the project's verify command (e.g. `pnpm check-types && pnpm build`) to confirm baseline passes
5. Implement the feature completely
6. Manually exercise the feature end-to-end — don't rely solely on the verify command
7. Run the verify command again — must pass
8. Update docs/<initiative>/features.json — set only YOUR feature's "passes" to true
9. Commit: `feat(<initiative>): <description> (<ID>)`

Rules:
- Implement ONLY your assigned feature
- You may only modify the `passes` field for your feature in features.json — nothing else
- Do not edit or remove existing tests — only add new ones
- If verify fails after your changes, fix it before reporting done
- If blocked, report back immediately — do not guess

When done, send a message to the team lead with:
- Feature ID
- Verify command exit code
- Commit hash
- Files changed (helps merge order)
- Any issues encountered
```

### Phase 5: Merge & Wrap

#### As each agent completes

1. Note the worktree branch name (returned by the Task tool)
2. Verify the agent's claim — check the worktree branch has the commit
3. Merge into main:

```bash
git merge <worktree-branch> --no-ff -m "merge: <Feature ID> from team session"

# Verify main after each merge — non-negotiable
pnpm check-types && pnpm build
```

**Merge as agents complete, not all at the end.** Catches conflicts early.

#### Handling failures

| Situation | Action |
|---|---|
| Merge conflict | Resolve manually; prefer the feature branch for its own files. If verify breaks post-resolve, revert and defer. |
| Verify fails after a clean merge | `git revert -m 1 HEAD`, investigate what the feature broke, fix or defer. |
| Agent reports blocked | Help unblock, or defer the feature. |
| Agent unresponsive | Send a check-in message; if no reply, defer. |
| Feature too large | Tell agent to stop; split it (see manage-features). |

#### Wave transition checklist

Before dispatching wave N+1:
- [ ] All wave N agents completed or deferred
- [ ] All successful features merged into main
- [ ] Verify passes on main after all merges
- [ ] Deferred features documented

#### Final verification + wrap

```bash
# Final gate
pnpm check-types && pnpm build
```

Append a session entry to `docs/<initiative>/progress.md`:

```markdown
## Team Session YYYY-MM-DD-NN

- **Lead:** <model>
- **Agents:** N (agent-1, agent-2, agent-3)
- **Waves:** 2

### Wave 1
- agent-1: F008 — MERGED (commit abc1234)
- agent-2: F009 — MERGED (commit def5678)
- agent-3: F010 — MERGED (commit 9ab0123)

### Wave 2
- agent-1: F011 — MERGED (commit 456cdef)
- agent-2: F012 — DEFERRED (merge conflict with F011)

**Summary:** 4/5 features completed, 1 deferred
**Baseline commit:** <hash before session>
**Final commit:** <hash after merges>
**Verify:** PASS
**Next:** F012 (deferred), F013, F014
```

Shut down agents:

```
SendMessage:
  type: "shutdown_request"
  recipient: "agent-1"
  content: "Team session complete. Shutting down."
```

After confirmations: `TeamDelete`.

Report a summary to the user: features merged, features deferred (with reasons), final verify status, recommended next steps.

## Git & Merge Strategy

**Merge order:** as agents complete. When two finish simultaneously, merge the one with fewer file changes first (lower conflict risk).

**Conflict resolution priority:**
1. Feature-specific files → prefer the feature branch
2. Shared files (config, package.json) → merge both changes deliberately
3. `features.json` → take the feature branch's change for its feature ID; keep main's state for all others
4. `progress.md` → not merged from agents; the team lead writes the session entry

**Rollback (last resort):**
```bash
git reset --hard <baseline-commit-from-phase-1>
```
Loses all merged features. Document in `progress.md` if used.

## Don't

- **Don't dispatch without a wave plan.** "Throw everything at agents and see what sticks" produces a merge swamp. Three agents in a planned wave beats five agents in a free-for-all.
- **Don't skip verify after each merge.** Agent verified in isolation. Main after merge is a different state. Run it every time.
- **Don't run more than 5 agents per wave.** Coordination cost beats parallelism gain past 5. Default to 3.
- **Don't merge everything at the end.** Catches conflicts when they're cheap to resolve — early, in isolation, one at a time.
- **Don't dispatch agents without `isolation: "worktree"`.** Without it, agents will overwrite each other's files in the shared working tree.
- **Don't defer the hard features just to ship the easy ones.** Defer when genuinely blocked, not because it's hard. Cherry-picking corrupts the feature backlog.
- **Don't trust the agent's "done" claim blindly.** Check the worktree branch, confirm the commit exists, run verify yourself after merging.
