# Common Mistakes — Operator Missing

## Mistake 1: Creating the Subscription in the default namespace

**Wrong approach:** Subscriptions must be in the namespace where the operator should run, not default

**Correct approach:** Put OLM resources in the correct namespace — check operator docs for namespace requirements
