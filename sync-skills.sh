#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

mkdir -p "$CLAUDE_DIR/skills"

rm -rf "$CLAUDE_DIR/skills/dev" "$CLAUDE_DIR/skills/marketing" "$CLAUDE_DIR/skills/social"
cp -r "$REPO_DIR/skills/dev" "$CLAUDE_DIR/skills/"
cp -r "$REPO_DIR/skills/marketing" "$CLAUDE_DIR/skills/"
cp -r "$REPO_DIR/skills/social" "$CLAUDE_DIR/skills/"

echo "✓ Skills synced to $CLAUDE_DIR/skills/"
