1. `kubectl get pods -o wide` shows 6 pods on one worker; `--show-labels` shows they carry `app.kubernetes.io/name=catalog-api`.
2. The spread constraint selects `app=catalog`, which no pod has, so each node counts 0 matching pods and skew is always 0.
3. Point the selector at the real label (this edits the pod template, so a rollout recreates the pods and the scheduler now spreads them 3 / 3):
   `kubectl -n k8smissions patch deploy catalog-api --type=json -p '[{"op":"replace","path":"/spec/template/spec/topologySpreadConstraints/0/labelSelector/matchLabels","value":{"app.kubernetes.io/name":"catalog-api"}}]'`
