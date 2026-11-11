#!/bin/bash
# Level 2: uploads must land on the PVC and survive a pod replacement.
. ../_fixtures/lib.sh

if ! kubectl get deployment web-app -n "$NS" >/dev/null 2>&1; then
  bad "Deployment web-app does not exist"
  exit 1
fi
if [ "$(kubectl get pvc uploads -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Bound" ]; then
  bad "PVC uploads is missing or not Bound"
  exit 1
fi
ok "PVC uploads is Bound"

POD=$(kubectl get pods -n "$NS" -l app=web-app --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ]; then
  bad "web-app has no running pod"
  exit 1
fi
if ! kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}' | grep -qw uploads; then
  bad "the web-app pod does not use PVC uploads"
  exit 1
fi
ok "$POD uses PVC uploads"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
TOKEN="invoice-$(date +%s)"
CODE=$(pcurl -o /dev/null -w '%{http_code}' -X POST --data-binary "$TOKEN" http://web-app/upload/validate.txt)
if [ "$CODE" != "201" ]; then
  bad "upload through Service web-app failed (HTTP ${CODE:-none})"
  exit 1
fi
if [ "$(pcurl http://web-app/files/validate.txt)" != "$TOKEN" ]; then
  bad "an uploaded file cannot be downloaded right after upload"
  exit 1
fi
ok "upload and download work"

kubectl delete pod "$POD" -n "$NS" --wait=false >/dev/null 2>&1
NEW=$(wait_replacement app=web-app "$POD" 60)
if [ -z "$NEW" ]; then
  bad "no replacement pod became Ready within 60s"
  exit 1
fi
sleep 2
if [ "$(pcurl http://web-app/files/validate.txt)" != "$TOKEN" ]; then
  bad "the file uploaded before the restart is gone"
  exit 1
fi
ok "the upload survived replacing the pod"
exit 0
exit 1
