# Common Mistakes — Stuck Reconciliation

## Mistake 1: Creating the CR in the operator's namespace

**Wrong approach:** Moving the workload to the 'operators' namespace breaks tenant isolation

**Correct approach:** Fix the operator's namespace scope; don't move workloads into system namespaces
