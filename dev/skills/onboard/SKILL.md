---
name: onboard
description: Use when given a task or context that needs deep codebase understanding before implementation. Triggers when the user says "onboard", "understand this", "get up to speed", or provides task context that needs exploration first. Produces a comprehensive onboarding document in .claude/tasks/[TASK_ID]/.
argument-hint: <task description or context>
---

# Onboard

You are given the following context:
$ARGUMENTS

## Instructions

> "AI models are geniuses who start from scratch on every task." – Noam Brown

Your job is to **onboard** yourself to the current task.

Do this by:

- Using extended thinking
- Exploring the codebase
- Asking the user questions if needed

For docs-first initiatives, check `docs/<initiative>/` first — `design.md`, `features.json`, and `progress.md` are the standard onboarding artifacts and usually answer most of your context questions before you need to dig elsewhere. See `workflow-convention.md` at the repo root for the layout.

The goal is to get you fully prepared to start working on the task. Take as long as you need. Overdoing it is better than underdoing it.

Record everything in a `.claude/tasks/[TASK_ID]/onboarding.md` file. This file will be used to onboard you to the task in a new session if needed, so make it comprehensive.
