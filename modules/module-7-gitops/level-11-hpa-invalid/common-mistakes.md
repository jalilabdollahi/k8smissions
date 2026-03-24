# Common Mistakes — Autoscaler Paradox

## Mistake 1: Assuming YAML validation catches this

**Wrong approach:** The API server accepts min > max in some k8s versions without immediate error

**Correct approach:** Always verify HPA status with kubectl describe hpa after applying

## Mistake 2: Forgetting metrics-server

**Wrong approach:** HPA shows <unknown> for CPU targets even with correct config

**Correct approach:** Install metrics-server first; HPA requires it for resource-based scaling
