# Common Mistakes — Controller Crash Loop

## Mistake 1: Installing the operator before the CRD always

**Wrong approach:** Manual ordering is fragile — automation, CI/CD, DR scenarios can break the order

**Correct approach:** Use init containers or framework-level CRD waiting for robust startup ordering
