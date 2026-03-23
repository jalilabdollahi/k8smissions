# Common Mistakes — Injected to Failure

## Mistake 1: Disabling Istio globally for the namespace

**Wrong approach:** Labeling the namespace to disable injection — removes mesh benefits from all workloads

**Correct approach:** Use Task-level podTemplate labels to opt out of injection for just CI pods
