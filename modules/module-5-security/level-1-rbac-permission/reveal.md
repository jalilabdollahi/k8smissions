**Fix**

1. `kubectl -n k8smissions logs deploy/log-shipper` shows `cannot get resource "pods/log"`.
2. The Role `log-reader` only grants `get`/`list` on `pods`. Add the subresource:
   `kubectl -n k8smissions patch role log-reader --type=json -p '[{"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["pods/log"],"verbs":["get"]}}]'`
3. `kubectl -n k8smissions rollout restart deploy/log-shipper` so the pod does not wait out its crash-loop back-off.

Do not use `resources: ["*"]` or a ClusterRoleBinding: the shipper would then read Secrets too.
