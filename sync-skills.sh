#!/usr/bin/env bash
set -e

# Re-register marketplace and reinstall custom skill plugins
claude plugin marketplace add 0xobat/claude-skills 2>/dev/null || true

for plugin in dev marketing social creative startup; do
  claude plugin install "$plugin@0xobat-skills" 2>/dev/null || true
done

echo "✓ Skill plugins synced"
