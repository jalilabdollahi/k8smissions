1. `kubectl describe node <nvme node>` shows `maintenance=nightly:NoExecute`; `kubectl get events` shows `TaintManagerEviction` for the session-cache pods about 20s after each start.
2. The Deployment already tolerates the taint, but with `tolerationSeconds: 20`, so the taint manager evicts the pods 20 seconds after they land.
3. Remove that field so the toleration holds for as long as the taint exists (or set it to 1800 or more):
   `kubectl -n k8smissions patch deploy session-cache --type=json -p '[{"op":"remove","path":"/spec/template/spec/tolerations/0/tolerationSeconds"}]'`
4. The rollout creates new pods on the NVMe node that outlast the window. The taint stays on the node.
