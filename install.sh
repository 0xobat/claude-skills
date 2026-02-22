#!/usr/bin/env bash
set -e

echo "Installing 0xobat-skills plugins..."

if ! command -v claude >/dev/null 2>&1; then
  echo "Error: 'claude' CLI not found. Install Claude Code first."
  exit 1
fi

claude plugin marketplace add 0xobat/claude-skills 2>/dev/null || echo "  marketplace already added"

for plugin in dev marketing social creative startup; do
  claude plugin install "$plugin@0xobat-skills" 2>/dev/null || echo "  $plugin already installed"
done

echo "Done! Restart Claude Code to apply changes."
