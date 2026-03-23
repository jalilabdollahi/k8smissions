# Common Mistakes — Unvalidated Resource

## Mistake 1: Using x-kubernetes-preserve-unknown-fields for all objects

**Wrong approach:** Disabling validation on the whole resource just to avoid writing schema — creates security and reliability risk

**Correct approach:** Write proper schemas; it takes time once but prevents operator bugs and security holes
