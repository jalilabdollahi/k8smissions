#!/bin/bash
# Level 10: uploads must survive replacing the pod; scratch space must stay disposable.
. ../_fixtures/lib.sh

if ! kubectl get deployment data-app -n "$NS" >/dev/null 2>&1; then
  bad "Deployment data-app does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=data-app --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "data-app has no Ready pod"
  exit 1
fi

# what backs /data and /scratch in the running pod
VOL=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/data")].name}')
CLAIM=$(kubectl get pod "$POD" -n "$NS" -o jsonpath="{.spec.volumes[?(@.name==\"$VOL\")].persistentVolumeClaim.claimName}")
if [ -z "$CLAIM" ]; then
  bad "/data is not backed by a PersistentVolumeClaim"
  exit 1
fi
if [ "$(kubectl get pvc "$CLAIM" -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Bound" ]; then
  bad "PVC $CLAIM is not Bound"
  exit 1
fi
ok "/data is on PVC $CLAIM (Bound)"

SVOL=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.containers[0].volumeMounts[?(@.mountPath=="/scratch")].name}')
SEMPTY=$(kubectl get pod "$POD" -n "$NS" -o jsonpath="{.spec.volumes[?(@.name==\"$SVOL\")].emptyDir}")
if [ -z "$SVOL" ] || [ -z "$SEMPTY" ]; then
  bad "/scratch must stay a throw-away emptyDir; it was moved to durable storage or removed"
  exit 1
fi
ok "/scratch is still an emptyDir"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
TOKEN="upload-$(date +%s)"
CODE=$(pcurl -o /dev/null -w '%{http_code}' -X POST --data-binary "$TOKEN" http://data-app/upload/validate.txt)
if [ "$CODE" != "201" ]; then
  bad "upload through Service data-app failed (HTTP ${CODE:-none})"
  exit 1
fi
ok "upload accepted"

kubectl delete pod "$POD" -n "$NS" --wait=false >/dev/null 2>&1
NEW=$(wait_replacement app=data-app "$POD" 70)
if [ -z "$NEW" ]; then
  bad "no replacement pod became Ready within 70s"
  exit 1
fi
sleep 2
if [ "$(pcurl http://data-app/files/validate.txt)" != "$TOKEN" ]; then
  bad "the file uploaded before the pod was replaced is gone"
  exit 1
fi
ok "the upload survived replacing the pod"
exit 0
exit 1
