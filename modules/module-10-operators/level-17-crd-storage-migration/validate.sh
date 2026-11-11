#!/bin/bash
NS=${NS:-k8smissions}
CRD=configs.settings.acme.io

if ! kubectl get crd $CRD >/dev/null 2>&1; then
  echo "❌ the Config CRD is gone"
  exit 1
fi
versions=$(kubectl get crd $CRD -o jsonpath='{.spec.versions[*].name}')
stored=$(kubectl get crd $CRD -o jsonpath='{.status.storedVersions}')
if [ "$versions" != "v1" ]; then
  echo "❌ the CRD still serves versions: $versions (only v1 should remain)"
  exit 1
fi
if [ "$stored" != '["v1"]' ]; then
  echo "❌ status.storedVersions is $stored, expected [\"v1\"]"
  exit 1
fi
echo "✅ the CRD serves only v1 and stores only v1"

out=$(kubectl get $CRD -A -o jsonpath='{range .items[*]}{.metadata.name}={.spec.value}{"\n"}{end}' 2>&1)
rc=$?
if [ "$rc" != 0 ]; then
  echo "❌ listing the Config objects fails: $(echo "$out" | head -c 240)"
  exit 1
fi
total=$(echo "$out" | grep -c .)
good=$(echo "$out" | awk -F= '{n=$1; sub("config-","",n); if ($2=="setting-" n) c++} END {print c+0}')
if [ "$total" != 30 ]; then
  echo "❌ $total Config objects are listed, expected 30"
  exit 1
fi
if [ "$good" != 30 ]; then
  echo "❌ only $good of 30 Config objects still have their original spec.value"
  exit 1
fi
echo "✅ all 30 Config objects are readable with their data"

# each object individually (the API server reads and decodes every one)
bad=0
for i in $(seq -w 1 30); do
  kubectl -n "$NS" get $CRD config-$i -o name >/dev/null 2>&1 || bad=$((bad + 1))
done
if [ "$bad" != 0 ]; then
  echo "❌ $bad Config objects cannot be read individually"
  exit 1
fi

done_=$(kubectl -n "$NS" get job crd-sync -o jsonpath='{.status.succeeded}' 2>/dev/null)
if [ "$done_" != 1 ]; then
  echo "❌ the Job crd-sync has not completed yet (succeeded: ${done_:-0})"
  exit 1
fi
echo "✅ the Job crd-sync completed"
exit 0
exit 1
