# 0xobat-skills

Claude Code plugin marketplace with custom skills.

## Install

> **Note:** Plugin marketplace is a Claude Code feature.

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

## Plugins

| Plugin      | Skills                                                                                                                                                         |
| ----------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `dev`       | coding-session, design-session, manage-features, onboard, recover-session, team-lead                                                                           |
| `marketing` | brand-voice, content-atomizer, direct-response-copy, email-sequences, keyword-research, lead-magnet, newsletter, orchestrator, positioning-angles, seo-content |
| `social`    | x-algorithm-optimizer                                                                                                                                          |
| `creative`  | ai-creative-strategist, ai-image-generation, ai-product-photo, ai-product-video, ai-social-graphics, ai-talking-head                                           |
| `startup`   | startup-secrets-cvp                                                                                                                                            |

## Dev Workflow

Adopts the docs-first convention (see `workflow-convention.md` at the repo root): each initiative lives in `docs/<initiative>/` with a `design.md`, `features.json`, and `progress.md`.

Recommended flow for the `dev` skills:

1. `/design-session` — interactive Q&A + research; produces `docs/<initiative>/design.md` + `features.json`
2. `/manage-features` — split, add, deprecate, or audit features mid-project
3. `/coding-session` — implement features one at a time; updates `progress.md`
4. `/team-lead` — parallelize with agents when 3+ independent features are ready
5. `/recover-session` — diagnose and fix when the verify command breaks

### Recommended Companion Plugins

Install [superpowers](https://github.com/obra/superpowers) for skills that pair well with `dev`:

- `/security-review` — audit code for vulnerabilities before merging
- `/code-review` — review PRs against plan and coding standards
- `/verification-before-completion` — prevent premature "done" claims
