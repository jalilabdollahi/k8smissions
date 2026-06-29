## What went wrong

Nothing is broken — the pod works. The issue is a common misconception: base64 is NOT encryption. The Secret value `c2VjcmV0cGFzczEyMw==` decodes instantly to `secretpass123`. Anyone with `kubectl get secret` access can read every Secret in the namespace.

## The safer way to write Secrets

Use `stringData` so you do not manually base64-encode values:

```yaml
apiVersion: v1
kind: Secret
type: Opaque
metadata:
  name: db-credentials
  namespace: k8smissions
stringData:
  username: admin
  password: secretpass123
```

Kubernetes base64-encodes it for storage. The values are still readable by anyone with access.

## Real security requires

- RBAC that restricts which ServiceAccounts can `get` Secrets
- Encryption at rest (enabled at the cluster level via EncryptionConfiguration)
- External secrets managers (HashiCorp Vault, AWS Secrets Manager via External Secrets Operator)