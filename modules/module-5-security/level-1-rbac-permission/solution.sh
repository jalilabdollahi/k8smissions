kubectl -n k8smissions logs deploy/log-shipper
kubectl auth can-i get pods/log --as=system:serviceaccount:k8smissions:log-shipper -n k8smissions
kubectl -n k8smissions patch role log-reader --type=json -p '[{"op":"add","path":"/rules/-","value":{"apiGroups":[""],"resources":["pods/log"],"verbs":["get"]}}]'
kubectl -n k8smissions rollout restart deploy/log-shipper
kubectl -n k8smissions rollout status deploy/log-shipper --timeout=90s
