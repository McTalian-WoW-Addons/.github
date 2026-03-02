# .github

Organization-level configuration and tooling for **McTalian-WoW-Addons**.

## Contents

| Path | Purpose |
|------|---------|
| `profile/README.md` | Org profile displayed on the GitHub org page |
| `rulesets/default.json` | Canonical branch protection ruleset applied to all repos |
| `scripts/apply-ruleset.sh` | CLI tool to apply the standard ruleset to repos |

## Repo Rulesets

All repos in the org share a standardized branch protection ruleset. The source of truth is [`rulesets/default.json`](rulesets/default.json).

### What It Protects

- **Branches**: `~DEFAULT_BRANCH`, `v*`, `alpha`, `beta`, `main`
- **Protections**: No deletion, no force push, no direct push (update), no new protected-pattern branches (creation)
- **PRs required**: 1 approval, squash + rebase allowed
- **Status checks**: "Passing PR Checks" (skipped on newly created branches)
- **Copilot code review**: Enabled
- **Bypass**: Organization admins can always bypass

### Applying the Ruleset

```bash
# Apply to a single repo
./scripts/apply-ruleset.sh RPGLootFeed

# Apply to all non-archived, non-fork repos in the org
./scripts/apply-ruleset.sh --all

# Preview changes without applying
./scripts/apply-ruleset.sh --all --dry-run
```

### Changing the Standard

1. Edit `rulesets/default.json`
2. Run `./scripts/apply-ruleset.sh --all` to propagate
3. Commit both the JSON change and note the reason

> **Note**: Org-level rulesets (managed from org settings, applied automatically to all repos) require a GitHub Team plan. Until then, we use this script to keep repo-level rulesets in sync.