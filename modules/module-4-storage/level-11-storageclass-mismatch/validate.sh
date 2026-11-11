#!/bin/bash
# Level 11: the reader must serve last year's archive from the static volume.
. ../_fixtures/lib.sh

if ! kubectl get pv archive-2023 >/dev/null 2>&1; then
  bad "PersistentVolume archive-2023 is gone"
  exit 1
fi
if ! kubectl get deployment archive-reader -n "$NS" >/dev/null 2>&1; then
  bad "Deployment archive-reader does not exist"
  exit 1
fi
POD=$(kubectl get pods -n "$NS" -l app=archive-reader --field-selector=status.phase=Running \
  -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$POD" ] || \
   [ "$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  bad "archive-reader has no Ready pod"
  exit 1
fi
ok "$POD is Ready"

CLAIM=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[?(@.name=="archive")].persistentVolumeClaim.claimName}')
BOUND=$(kubectl get pvc "$CLAIM" -n "$NS" -o jsonpath='{.spec.volumeName}' 2>/dev/null)
if [ "$BOUND" != "archive-2023" ]; then
  bad "the pod's claim ${CLAIM:-none} is bound to '${BOUND:-nothing}', not to the volume that holds last year's files"
  exit 1
fi
ok "claim $CLAIM is bound to archive-2023"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
LAST=$(pcurl http://archive-reader/2023-summary.csv | tail -1 | tr -d '\r\n')
if [ "$LAST" != "total,5204925" ]; then
  bad "2023-summary.csv through Service archive-reader is missing or wrong (last line: '${LAST:-no answer}')"
  exit 1
fi
ok "2023-summary.csv is served from the archive"
exit 0
exit 1
