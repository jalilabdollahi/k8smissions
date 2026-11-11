kubectl -n cart get pods
for d in cart-cache cart-worker cart-reporter; do
  kubectl -n cart get pod -l app=$d -o jsonpath='{.items[0].metadata.name}{"  "}{.items[0].status.containerStatuses[0].lastState}{"\n"}'
done
kubectl -n cart logs deploy/cart-worker --previous | tail -3
kubectl -n cart get events --field-selector type=Warning
kubectl -n cart patch configmap cart-cache-config --type=merge -p '{"data":{"CACHE_MB":"64"}}'
kubectl -n cart rollout restart deploy/cart-cache
kubectl -n cart set env deploy/cart-worker QUEUE_ADDR=cart-queue:6379
kubectl -n cart patch deploy cart-reporter --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe/tcpSocket/port","value":9090}]'
for d in cart-cache cart-worker cart-reporter; do kubectl -n cart rollout status deploy/$d --timeout=100s; done
