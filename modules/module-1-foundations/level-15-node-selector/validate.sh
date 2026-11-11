#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

phase=$(k get pod cache-warm -o jsonpath='{.status.phase}' 2>/dev/null)
if [ "$phase" != "Running" ]; then
  echo "❌ Pod cache-warm is ${phase:-missing}, not Running"
  exit 1
fi
if ! k wait --for=condition=Ready pod/cache-warm --timeout=15s >/dev/null 2>&1; then
  echo "❌ Pod cache-warm is not Ready"
  exit 1
fi
node=$(k get pod cache-warm -o jsonpath='{.spec.nodeName}')
disk=$(kubectl get node "$node" -o jsonpath='{.metadata.labels.disk}')
if [ "$disk" != "ssd" ]; then
  echo "❌ cache-warm runs on $node, which does not have the SSD"
  exit 1
fi
echo "✅ cache-warm is Running and Ready on $node (disk=ssd)"

restarts=$(k get pod cache-warm -o jsonpath='{.status.containerStatuses[0].restartCount}')
if [ "${restarts:-1}" != "0" ]; then
  echo "❌ cache-warm has restarted $restarts time(s)"
  exit 1
fi

if [ "$(k exec probe -- curl -s -o /dev/null -w '%{http_code}' --max-time 4 http://cache-warm 2>/dev/null)" != "200" ]; then
  echo "❌ Service cache-warm did not answer 200"
  exit 1
fi
echo "✅ Service cache-warm answers 200"
exit 0
exit 1
