# Operator Missing

## What Was Broken
The Subscription referenced 'non-existent-catalog' as the CatalogSource. OLM couldn't find the catalog to resolve the operator package manifest. No InstallPlan was created, so no CSV/operator was installed.

## The Fix
Fix the source field to reference a valid CatalogSource name.

## Why It Matters
OLM approval flow: CatalogSource (catalog of operators) → Subscription (request to install from catalog) → InstallPlan (approval gate) → CSV (operator code) → operator Deployment. A broken link anywhere stalls the chain.

## Pro Tip
Check Subscription status: kubectl describe subscription my-operator-sub -n operators. OLM shows exactly which step failed and why. InstallPlan: kubectl get installplan -n operators.

## Concepts
OLM, Subscription, CatalogSource, InstallPlan, CSV, operator install
