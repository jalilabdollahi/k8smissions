# Reveal

Two independent faults.

1. `shared-pvc` asks for `ReadWriteMany`. The local-path provisioner behind the `standard` class supports only `ReadWriteOnce` and `ReadWriteOncePod`, so it refuses to provision it. Access modes cannot be changed on a claim, so delete it and create a single-writer claim with the same name.
2. `ingest-data` is `ReadWriteOncePod`: one pod in the cluster at a time. The default `RollingUpdate` (maxUnavailable 25% of 1 pod = 0) starts the v2 pod while v1 still holds the volume, so v2 can never be scheduled and the rollout deadlocks. Use `strategy.type: Recreate` (stop v1, then start v2).

```bash
kubectl patch deployment ingest -n k8smissions --type=merge \
  -p '{"spec":{"strategy":{"type":"Recreate","rollingUpdate":null}}}'
kubectl delete pvc shared-pvc -n k8smissions
kubectl apply -f - <<'YAML'
apiVersion: v1
kind: PersistentVolumeClaim
metadata: {name: shared-pvc, namespace: k8smissions}
spec:
  accessModes: ["ReadWriteOncePod"]
  resources: {requests: {storage: 1Gi}}
YAML
```

`ingest-data` is never touched, so v2 still finds `first-batch.dat`.
