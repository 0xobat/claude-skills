---
name: team-lead
description: Use when multiple features need parallel implementation across a harness-based project. Triggers when user says "team session", "parallel features", "swarm this", "use agents", or "batch with worktrees". Orchestrates a team of agents in isolated git worktrees to implement features concurrently, then merges results back to main with verification.
---

# Team Lead

## Overview

Orchestrate parallel feature development using Claude Code teams and git worktrees. Instead of implementing features one-by-one via coding-session, this skill dispatches multiple agents — each in an isolated worktree — to work on independent features simultaneously.

**Core principle:** Parallelism without chaos. Every agent follows the coding-session ritual independently. The team lead's job is to plan waves, dispatch work, verify merges, and keep main green.

## When to Use

Use this skill when:
- 3+ independent features are ready to implement
- Features have no mutual dependencies (or can be grouped into dependency-ordered waves)
- User explicitly requests parallel/team/swarm execution
- Project is in a passing state (verify.sh exits 0 on main)

Do NOT use for:
- Single feature work (use coding-session skill)
- Features with tight interdependencies that can't be waved
- Projects where verify.sh is currently failing (use recover-session first)
- Initial project setup (use initialize-project skill)
- Fewer than 3 features — overhead of team coordination isn't worth it

## Prerequisites

Before starting a team session, confirm ALL of these:

- [ ] `harness/verify.sh` exits 0 on current main
- [ ] `harness/features.json` has 3+ features with `"passes": false`
- [ ] `harness/progress.txt` exists and is current
- [ ] Features have been reviewed for dependencies (you know what blocks what)

**If any prerequisite fails, STOP. Fix it first using the appropriate skill.**

## The Team Session Protocol

Follow these six phases in order. Each phase has a specific purpose.

### Phase 1: Orient

**Before anything else**, read the project state:

1. Read `harness/progress.txt` — understand what previous sessions accomplished
2. Run `git log --oneline -10` — see concrete recent changes
3. Read `harness/features.json` — identify all `"passes": false` features
4. Run `harness/init.sh` — ensure dev environment is running
5. Run `harness/verify.sh` — confirm main is green (baseline)

```bash
cd project-root
./harness/verify.sh
# MUST exit 0 or STOP HERE — use recover-session instead
```

**Record the baseline commit hash:**
```bash
git rev-parse HEAD
# This is your rollback point if anything goes wrong
```

### Phase 2: Analyze & Batch into Waves

Group the `"passes": false` features into **waves** — dependency-ordered batches that can run in parallel within each wave.

**Wave rules:**
- Features within a wave MUST be independent (no shared files, no dependency chains)
- Wave N+1 can depend on Wave N results (all of Wave N merges before Wave N+1 starts)
- Each wave has at most 5 agents (more causes diminishing returns and merge pain)
- Default to 3 agents per wave unless the user requests more

**Dependency analysis checklist:**
- Do any features modify the same files? → Different waves
- Does Feature B require Feature A's output? → B in later wave
- Do features share database schemas or API contracts? → Same wave only if touching different parts
- Are features in the same category with overlapping scope? → Different waves (risk of merge conflicts)

**Example wave plan:**
```
Wave 1 (3 agents):
  Agent 1: F008 - Redis connection pool (infrastructure)
  Agent 2: F009 - Health check endpoint (operations)
  Agent 3: F010 - Request logging middleware (infrastructure)

Wave 2 (2 agents, depends on Wave 1):
  Agent 1: F011 - Cache invalidation (needs F008 Redis)
  Agent 2: F012 - Request rate limiting (needs F010 logging)
```

### Phase 3: Present Plan & Confirm

**Never dispatch agents without user approval.**

Present to the user:
1. The wave plan (which features in which wave)
2. Agent count per wave
3. Dependency reasoning (why this ordering)
4. Estimated scope (feature count, wave count)
5. Any features you're deferring and why

Wait for explicit user confirmation before proceeding.

**If the user modifies the plan**, update your waves accordingly. The user knows their codebase better than you do.

### Phase 4: Create Team & Dispatch

#### 4a. Create the team

```
TeamCreate:
  team_name: "<project>-team-session"
  description: "Parallel feature implementation for <project>"
```

#### 4b. Create tasks for each feature

For each feature in the current wave, create a task:

```
TaskCreate:
  subject: "Implement <Feature ID> - <description>"
  description: <full agent briefing — see template below>
  activeForm: "Implementing <Feature ID>"
```

Set up wave dependencies using `addBlockedBy` — Wave 2 tasks are blocked by Wave 1 tasks.

#### 4c. Spawn agents with worktree isolation

For each agent in the current wave:

```
Task tool:
  subagent_type: "general-purpose"
  isolation: "worktree"
  team_name: "<project>-team-session"
  name: "agent-<N>"
  mode: "bypassPermissions"
  prompt: <agent briefing>
```

**Critical: `isolation: "worktree"`** — this gives each agent its own copy of the repo. Without it, agents will clobber each other's files.

#### Agent Briefing Template

Each agent receives this briefing:

```
You are implementing a single feature in a harness-based project.

## Your Assignment
- Feature: <ID> - <description>
- Steps: <steps from features.json>

## Your Workflow
0. Run pwd — confirm you know where you are (you're in an isolated worktree)
1. Read harness/progress.txt for context
2. Run git log --oneline -10 — see what recently changed
3. Read harness/features.json to understand your feature
4. Run harness/init.sh — ensure the dev environment is running
5. Run harness/verify.sh — confirm baseline passes
   If baseline FAILS: fix it before doing any feature work. Do not build on a broken foundation.
6. Implement the feature completely
7. Test your work as a human user would — run the app, hit the endpoint, verify the UI, exercise the feature end-to-end. Do not rely solely on verify.sh.
8. Run harness/verify.sh — MUST exit 0
9. Only after careful testing: update harness/features.json — set your feature's "passes" field to true
10. Commit with message:
    feat(<project>): implement <description> (<ID>)

## Rules
- Implement ONLY your assigned feature — do not touch other features
- Do NOT modify files outside your feature's scope unless necessary
- If verify.sh fails after your changes, fix it before reporting done
- If you're blocked, report back immediately — do not guess or improvise
- Feature list immutability: in features.json, you may ONLY change the `passes` field for your assigned feature — no other edits permitted
- Test immutability: do NOT remove or edit existing tests — only add new ones
- Always run init.sh before verify.sh — environment setup failures are not code bugs

## Anti-Patterns — Do Not Fall Into These
- **Premature victory declaration**: Claiming a feature works after only verify.sh passes, without manually testing the actual behavior. verify.sh checks structure; you must check function.
- **Marking complete without testing**: Setting "passes": true before running verify.sh and doing end-to-end testing. The passes field is a claim about reality — verify the reality first.
- **Half-implementation**: Implementing the happy path but skipping edge cases, error handling, or steps listed in the feature spec. Every step in the feature's steps array must be done.
- **Test modification**: Editing or removing existing tests to make your feature pass. Tests are the spec. If your code doesn't pass them, your code is wrong — not the tests.

## When Done
Before reporting, confirm clean state:
- No uncommitted changes (git status is clean)
- No debug code, console.logs, or TODO comments left behind
- All feature steps from features.json are implemented

Mark your task as completed using TaskUpdate.
Send a message to the team lead confirming:
- Feature ID implemented
- verify.sh exit code
- Commit hash
- Files changed (list them — helps the team lead optimize merge order)
- Any issues encountered
```

### Phase 5: Monitor & Merge

This is where the team lead earns their keep. As agents complete work:

#### 5a. Receive completion reports

Agents send messages when done. For each completed agent:

1. Note the worktree branch name (returned by the Task tool)
2. Verify the agent's claim: check that their worktree branch has the commit

#### 5b. Merge worktree branches

For each completed agent's branch, merge into main:

```bash
# On main branch
git merge <worktree-branch> --no-ff -m "merge: <Feature ID> from team session"

# Verify main is still green after merge
./harness/verify.sh
# MUST exit 0 — if not, the merge introduced a conflict
```

**If merge conflicts occur:**
1. Resolve conflicts manually (prefer the feature branch's changes for the feature's own files)
2. Run verify.sh after resolution
3. If verify.sh fails post-resolution, revert the merge and defer the feature

**If verify.sh fails after a clean merge:**
1. Revert the merge: `git revert -m 1 HEAD`
2. Investigate: what did the feature break?
3. Either fix and re-merge, or defer the feature to a later wave

#### 5c. Wave transitions

**All features in Wave N must be merged and verified before Wave N+1 starts.**

Wave transition checklist:
- [ ] All Wave N agents have completed or been deferred
- [ ] All successful features merged into main
- [ ] verify.sh passes on main after all merges
- [ ] Deferred features documented with reasons

Then dispatch Wave N+1 agents (they'll get the merged main as their worktree base).

#### 5d. Handle failures

When an agent reports a problem:

| Situation | Action |
|-----------|--------|
| Agent can't implement feature | Ask agent for details, help unblock, or defer feature |
| verify.sh fails in agent's worktree | Tell agent to fix; if they can't, defer feature |
| Merge conflict on main | Resolve manually, run verify.sh, revert if broken |
| Agent is stuck/unresponsive | Send a message checking status; if no response, defer feature |
| Feature turns out too large | Tell agent to stop; split feature using manage-features protocol |

### Phase 6: Wrap Up

After all waves complete (or all remaining features are deferred):

#### 6a. Final verification

```bash
./harness/verify.sh
# MUST exit 0 — this is the final gate
```

#### 6b. Update progress.txt

Append a team session entry:

```
--- Team Session 2026-02-22-01 ---
Lead: Claude Opus 4.6
Agents: 3 (agent-1, agent-2, agent-3)
Waves: 2

Wave 1:
  agent-1: F008 - Redis connection pool — MERGED (commit abc1234)
  agent-2: F009 - Health check endpoint — MERGED (commit def5678)
  agent-3: F010 - Request logging middleware — MERGED (commit 9ab0123)

Wave 2:
  agent-1: F011 - Cache invalidation — MERGED (commit 456cdef)
  agent-2: F012 - Request rate limiting — DEFERRED (merge conflict with F011)

Summary: 4/5 features completed, 1 deferred
Baseline commit: <hash before team session>
Final commit: <hash after all merges>
verify.sh: PASS
Next: F012 (deferred), F013, F014
Commit: chore(<project>): team session - implement F008-F011
```

#### 6c. Shut down agents

Send shutdown requests to all agents:

```
SendMessage:
  type: "shutdown_request"
  recipient: "agent-1"
  content: "Team session complete. Shutting down."
```

Wait for shutdown confirmations, then clean up:

```
TeamDelete
```

#### 6d. Report to user

Provide a summary:
- Features completed (merged and verified)
- Features deferred (with reasons)
- Final verify.sh status
- Total commits added to main
- Recommended next steps

## Git & Merge Strategy

### Branch naming
Worktree branches are auto-generated by the `isolation: "worktree"` parameter. You don't control the names — the Task tool returns them.

### Merge order
Merge agents in the order they complete. If two agents finish simultaneously, merge the one with fewer file changes first (lower conflict risk).

### Conflict resolution priority
1. Feature-specific files: prefer the feature branch
2. Shared files (e.g., config, package.json): merge both changes carefully
3. harness/features.json: always take the feature branch's change for their feature ID, keep main's state for all other features
4. harness/progress.txt: not merged from agents — team lead writes the session entry

### Rollback strategy
If main becomes unrecoverable:
```bash
git reset --hard <baseline-commit-from-phase-1>
```
This loses all merged features. Only use as a last resort. Document in progress.txt.

## Edge Cases

### Circular dependencies discovered mid-session
If Wave 2 features turn out to depend on each other:
1. STOP the affected agents
2. Re-analyze dependencies
3. Re-sequence into new waves or implement sequentially
4. Document the re-plan in progress.txt

### Agent modifies files outside its scope
If an agent's merge touches unexpected files:
1. Review the diff carefully before merging
2. If changes are necessary (e.g., shared utility), merge carefully
3. If changes are unnecessary, ask the agent to revert them
4. Consider deferring if the scope creep is significant

### Partial wave completion
If some agents succeed and others fail in a wave:
1. Merge the successful ones
2. Verify main is green
3. Defer failed features
4. Proceed to next wave (successful merges provide foundation)

### Too many merge conflicts
If 3+ features in a wave cause merge conflicts:
1. You over-parallelized — features weren't truly independent
2. Complete the current wave with manual conflict resolution
3. Reduce agent count in subsequent waves
4. Re-analyze remaining features for hidden dependencies

## Common Mistakes & Rationalizations

| Excuse | Reality | Counter |
|--------|---------|---------|
| "All features are independent, one big wave" | Hidden dependencies always exist. Smaller waves catch them early. | Start with 3 agents. Scale up only after Wave 1 succeeds cleanly. |
| "Merge conflicts are unlikely" | With parallel work, they're inevitable. Plan for them. | Analyze file overlap before dispatching. Same-file features go in different waves. |
| "Skip verification after merge, agents verified" | Agent verified in isolation. Main after merge is a different state. | Always run verify.sh after every merge. Non-negotiable. |
| "Defer the hard features, ship the easy ones" | Deferred features accumulate. Don't use team sessions to cherry-pick. | Defer only when genuinely blocked. Not because it's hard. |
| "5+ agents = 5x speed" | 5+ agents = 5x merge complexity. Diminishing returns hit fast. | 3 agents is the sweet spot. 5 is the max. More is chaos. |
| "I'll merge everything at the end" | Merge-at-end hides conflicts until it's too late. | Merge as agents complete. Catch conflicts early. |

## Red Flags - STOP and Reconsider

If you're thinking any of these, you're setting up for failure:

- "Let's just throw all features at agents and see what sticks"
- "Dependency analysis takes too long, features look independent enough"
- "Skip the wave plan, dispatch everyone at once"
- "verify.sh on main can wait until all agents are done"
- "Merge conflicts are a sign to just revert and try again"
- "Agents are smart, they'll figure out the dependencies"

**All of these mean: Slow down. Follow the protocol. Parallelism amplifies mistakes.**
