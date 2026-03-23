# Common Mistakes — Reverted Release

## Mistake 1: Running kubectl rollout restart

**Wrong approach:** kubectl rollout restart doesn't work on Argo Rollout objects — use argo rollouts commands

**Correct approach:** Use argo rollouts plugin or kubectl argo rollouts subcommands
