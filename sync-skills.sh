#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

# Remove all local skills, then copy fresh from repo
rm -rf "$CLAUDE_DIR/skills"
cp -r "$REPO_DIR/skills" "$CLAUDE_DIR/skills"

echo "✓ Skills synced to $CLAUDE_DIR/skills/"
