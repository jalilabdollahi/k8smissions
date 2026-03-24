# Common Mistakes — The Drift

## Mistake 1: Disabling ArgoCD auto-sync entirely

**Wrong approach:** Setting automated: {} empty — disables both self-heal and prune, app never syncs automatically

**Correct approach:** Disable only selfHeal: false to allow manual overrides while keeping auto-sync for git changes

## Mistake 2: Fighting GitOps with kubectl

**Wrong approach:** Repeatedly kubectl-scaling in a race against ArgoCD self-heal

**Correct approach:** Work with GitOps: commit the change to git, or explicitly disable self-heal for the app
