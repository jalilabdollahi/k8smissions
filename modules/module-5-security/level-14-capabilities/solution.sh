kubectl -n k8smissions logs deploy/edge-nginx
kubectl -n k8smissions patch deploy edge-nginx --type=json -p '[{"op":"add","path":"/spec/template/spec/containers/0/securityContext/capabilities/add","value":["CHOWN","SETUID","SETGID","NET_BIND_SERVICE"]}]'
kubectl -n k8smissions rollout status deploy/edge-nginx --timeout=100s
kubectl -n k8smissions exec deploy/edge-nginx -- grep Cap /proc/1/status
