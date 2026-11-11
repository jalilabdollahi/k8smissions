kubectl -n settle describe rs -l app=settlement | grep -i -A3 FailedCreate
kubectl -n settle patch deploy settlement -p '{"spec":{"template":{"spec":{"securityContext":{"runAsNonRoot":true,"seccompProfile":{"type":"RuntimeDefault"}},"containers":[{"name":"app","securityContext":{"allowPrivilegeEscalation":false,"capabilities":{"drop":["ALL"]}}}]}}}}'
sleep 5
kubectl -n settle describe rs -l app=settlement | grep -i -A3 FailedCreate
kubectl -n settle describe quota settle-quota
kubectl -n settle set resources deploy/settlement --limits=cpu=200m,memory=128Mi
kubectl -n settle rollout status deploy/settlement --timeout=60s || true
kubectl -n settle logs deploy/settlement
kubectl -n settle patch role settle-config-reader --type=json -p '[{"op":"replace","path":"/rules/0/verbs","value":["get","list","watch"]}]'
kubectl -n settle rollout restart deploy/settlement
kubectl -n settle get netpol -o yaml
kubectl -n settle apply -f - <<'YAML'
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: db-clients
spec:
  podSelector:
    matchLabels: {app: settle-db}
  policyTypes: ["Ingress"]
  ingress:
  - from:
    - podSelector:
        matchLabels: {app: settlement}
    ports:
    - {port: 5432, protocol: TCP}
YAML
kubectl -n settle rollout status deploy/settlement --timeout=100s
