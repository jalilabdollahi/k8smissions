POD=$(kubectl -n k8smissions get pod -l app=quote-api -o jsonpath='{.items[0].metadata.name}')
kubectl -n k8smissions debug "$POD" -i --image=busybox:1.36 --target=echo --container=dbg -- \
  sh -c 'cat /proc/1/cmdline | tr "\0" " "; echo; netstat -ltn; wget -qO- http://localhost:5678; echo'
kubectl -n k8smissions patch deploy quote-api --type=json \
  -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args/0","value":"-listen=:5678"}]'
kubectl -n k8smissions rollout status deploy/quote-api --timeout=90s
