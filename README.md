# Claude Code Config

Unified Claude Code config across Mac and Ubuntu workstations.

## Setup

```bash
git clone https://github.com/0xobat/claude.git
cd claude
./install.sh
```

## Structure

```
├── install.sh                 # Installs everything to ~/.claude/
├── settings.json              # Preferences, enabled plugins, env vars
├── statusline.sh              # Custom status line
└── skills/
    ├── coding-session/        # One-feature-per-session workflow
    ├── initialize-project/    # Harness bootstrapping
    ├── marketing/             # Marketing skill suite
    └── social/                # Social media skills
```
