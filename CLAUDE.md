# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Purpose

Claude Code plugin marketplace (`0xobat-skills`). Each top-level directory is a plugin containing skills.

## Structure

- `.claude-plugin/marketplace.json` — Marketplace manifest
- `{dev,marketing,social,creative,startup}/` — Plugins, each with `.claude-plugin/plugin.json` and `skills/`
- `install.sh` — Registers marketplace and installs all plugins

## Conventions

- Skills follow the Claude Code skill format (YAML frontmatter with `name`, `description`, and `---` delimiters)
- Each plugin has a `.claude-plugin/plugin.json` with name, description, version, and author
