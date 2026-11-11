1. `describe pod` on the Pending replica shows both workers rejected for `didn't match pod anti-affinity rules` and the control plane for its taint.
2. The Deployment demands that no two `app=ledger-api` pods share a node (required anti-affinity on hostname). With two workers, only two replicas can ever run.
3. Make the rule a preference (or use a spread constraint with `maxSkew: 1`), so replicas spread when possible and may double up when not:
   `kubectl -n k8smissions patch deploy ledger-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/affinity/podAntiAffinity","value":{"preferredDuringSchedulingIgnoredDuringExecution":[{"weight":100,"podAffinityTerm":{"labelSelector":{"matchLabels":{"app":"ledger-api"}},"topologyKey":"kubernetes.io/hostname"}}]}}]'`
4. The rollout produces 3 Ready replicas split 2 / 1.
Tolerating the control-plane taint or scaling to 2 would be wrong: the first breaks "workers only", the second breaks the 3-replica commitment.
