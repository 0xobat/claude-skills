# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Portable Claude Code configuration repository. Stores skills, workflows, and settings to maintain a uniform Claude Code setup across Mac and Ubuntu workstations. Deployed via `./install.sh`.

## Structure

- `install.sh` — Deploys config to `~/.claude/`, registers marketplaces, installs plugins
- `settings.json` — Preferences, enabled plugins, env vars (uses `__HOME__` placeholder)
- `statusline.sh` — Custom status line (requires `jq`)
- `skills/` — Custom Claude Code skill definitions (YAML frontmatter + markdown)

## Conventions

- All configuration must be cross-platform compatible (macOS and Ubuntu/Linux)
- Shell scripts use `#!/usr/bin/env bash`
- Never commit secrets, credentials, or machine-specific absolute paths — use `__HOME__` placeholder where paths are needed
- Skills follow the Claude Code skill format (YAML frontmatter with `name`, `description`, and `---` delimiters)
