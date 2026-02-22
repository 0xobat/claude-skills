#!/usr/bin/env bash
set -e

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "Installing Claude Code config from $REPO_DIR"

# --- Prereqs ---
mkdir -p "$CLAUDE_DIR/skills"

if ! command -v jq >/dev/null 2>&1; then
  echo "Warning: 'jq' not found. statusline.sh requires it."
fi

# --- Settings ---
# Replace __HOME__ placeholder with actual home directory
sed "s|__HOME__|$HOME|g" "$REPO_DIR/settings.json" > "$CLAUDE_DIR/settings.json"
echo "✓ settings.json"

# --- Statusline ---
cp "$REPO_DIR/statusline.sh" "$CLAUDE_DIR/statusline-command.sh"
echo "✓ statusline-command.sh"

# --- Skills ---
rm -rf "$CLAUDE_DIR/skills/coding-session" "$CLAUDE_DIR/skills/initialize-project"
rm -rf "$CLAUDE_DIR/skills/marketing" "$CLAUDE_DIR/skills/social"
cp -r "$REPO_DIR/skills/coding-session" "$CLAUDE_DIR/skills/"
cp -r "$REPO_DIR/skills/initialize-project" "$CLAUDE_DIR/skills/"
cp -r "$REPO_DIR/skills/marketing" "$CLAUDE_DIR/skills/"
cp -r "$REPO_DIR/skills/social" "$CLAUDE_DIR/skills/"
echo "✓ skills"

# --- Marketplaces & Plugins ---
if ! command -v claude >/dev/null 2>&1; then
  echo "Warning: 'claude' CLI not found. Skipping marketplace and plugin setup."
  echo "Install Claude Code first, then re-run this script."
  exit 0
fi

echo "Adding marketplaces..."
claude plugin marketplace add anthropics/skills 2>/dev/null || echo "  anthropic-agent-skills already added"
claude plugin marketplace add anthropics/claude-plugins-official 2>/dev/null || echo "  claude-plugins-official already added"
claude plugin marketplace add perplexityai/modelcontextprotocol 2>/dev/null || echo "  perplexity already added"
claude plugin marketplace add railwayapp/railway-skills 2>/dev/null || echo "  railway already added"
echo "✓ marketplaces"

echo "Installing plugins..."
plugins=(
  # Official plugins
  "frontend-design@claude-plugins-official"
  "feature-dev@claude-plugins-official"
  "agent-sdk-dev@claude-plugins-official"
  "learning-output-style@claude-plugins-official"
  "explanatory-output-style@claude-plugins-official"
  "context7@claude-plugins-official"
  "code-review@claude-plugins-official"
  "code-simplifier@claude-plugins-official"
  "ralph-loop@claude-plugins-official"
  "superpowers@claude-plugins-official"
  "typescript-lsp@claude-plugins-official"
  "playwright@claude-plugins-official"
  "security-guidance@claude-plugins-official"
  "commit-commands@claude-plugins-official"
  "pyright-lsp@claude-plugins-official"
  "supabase@claude-plugins-official"
  "claude-md-management@claude-plugins-official"
  "claude-code-setup@claude-plugins-official"
  "vercel@claude-plugins-official"
  "stripe@claude-plugins-official"
  "hookify@claude-plugins-official"
  "playground@claude-plugins-official"
  "posthog@claude-plugins-official"
  "firecrawl@claude-plugins-official"
  # Anthropic skills
  "document-skills@anthropic-agent-skills"
  "example-skills@anthropic-agent-skills"
  # Third-party
  "perplexity@perplexity-mcp-server"
)

for plugin in "${plugins[@]}"; do
  claude plugin install "$plugin" 2>/dev/null || echo "  $plugin already installed"
done
echo "✓ plugins"

echo ""
echo "Done! Restart Claude Code to apply changes."
