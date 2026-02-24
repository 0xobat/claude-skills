# 0xobat-skills

Claude Code plugin marketplace with custom skills.

## Install

```bash
./install.sh
```

### Claude Code (via Plugin Marketplace)

Register the marketplace first:

```
/plugin marketplace add 0xobat/claude-skills
```

Then install plugins:

```
/plugin install dev@0xobat-skills
/plugin install marketing@0xobat-skills
/plugin install social@0xobat-skills
/plugin install creative@0xobat-skills
/plugin install startup@0xobat-skills
```

> **Note:** Plugin marketplace is a Claude Code feature.

## Plugins

| Plugin | Skills |
|--------|--------|
| `dev` | coding-session, initialize-project, manage-features, onboard, recover-session, team-lead |
| `marketing` | brand-voice, content-atomizer, direct-response-copy, email-sequences, keyword-research, lead-magnet, newsletter, orchestrator, positioning-angles, seo-content |
| `social` | x-algorithm-optimizer |
| `creative` | ai-creative-strategist, ai-image-generation, ai-product-photo, ai-product-video, ai-social-graphics, ai-talking-head |
| `startup` | startup-secrets-cvp |

## Dev Workflow

Recommended flow for the `dev` skills:

1. `/initialize-project` — bootstrap harness structure
2. `/manage-features` — define and organize the feature list
3. `/coding-session` — implement features one at a time
4. `/team-lead` — parallelize with agents when 3+ independent features are ready
5. `/recover-session` — fix things when verify.sh breaks

### Recommended Companion Plugins

Install [superpowers](https://github.com/obra/superpowers) for skills that pair well with `dev`:

- `/security-review` — audit code for vulnerabilities before merging
- `/code-review` — review PRs against plan and coding standards
- `/verification-before-completion` — prevent premature "done" claims
