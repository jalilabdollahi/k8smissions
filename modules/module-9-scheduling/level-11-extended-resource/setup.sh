#!/bin/bash
# Advertise example.com/fpgas on the workers the way a device plugin does: 2 on the first, 1 on the second.
. ../_fixtures/lib.sh
a=$(worker_n 1); b=$(worker_n 2)
kubectl patch node "$a" --subresource=status --type=json \
  -p '[{"op":"add","path":"/status/capacity/example.com~1fpgas","value":"2"}]' || exit 1
kubectl patch node "$b" --subresource=status --type=json \
  -p '[{"op":"add","path":"/status/capacity/example.com~1fpgas","value":"1"}]' || exit 1
for i in $(seq 1 20); do
  [ "$(kubectl get node "$a" -o jsonpath='{.status.allocatable.example\.com/fpgas}')" = "2" ] && break
  sleep 1
done
kubectl -n "$NS" create configmap fpga-inventory \
  --from-literal=resource=example.com/fpgas \
  --from-literal="$a"=2 --from-literal="$b"=1 || exit 1
