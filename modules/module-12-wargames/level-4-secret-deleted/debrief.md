# Credential Void

## What Happened
The db-credentials Secret was accidentally deleted (or expired and cleaned up). Kubernetes immediately fails pod creation for any pod that references a missing secret via secretKeyRef — the pod shows CreateContainerConfigError.

## The Fix
```bash
kubectl create secret generic db-credentials \
  --from-literal=username=appuser \
  --from-literal=password=securepass123 \
  -n k8smissions
```

## Key Lessons
- **Secrets as hard dependencies** — pods with secretKeyRef literally cannot start without the secret
- **Optional secrets** — `optional: true` on a secretKeyRef allows the pod to start even if the secret is missing (but the env var will be empty)
- **Secret rotation** — always create the new secret before deleting the old one to avoid this scenario
- **External Secrets Operator** — keeps secrets in sync from Vault/AWS Secrets Manager, preventing this class of incident
