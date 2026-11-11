#!/bin/bash
# Level 15: ingest v2 is rolled out on single-writer volumes and still sees v1's data.
. ../_fixtures/lib.sh

if ! kubectl get deployment ingest -n "$NS" >/dev/null 2>&1; then
  bad "Deployment ingest does not exist"
  exit 1
fi
if [ "$(kubectl get pvc ingest-data -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)" != "Bound" ]; then
  bad "PVC ingest-data (v1's data) is missing or not Bound"
  exit 1
fi

PHASE=$(kubectl get pvc shared-pvc -n "$NS" -o jsonpath='{.status.phase}' 2>/dev/null)
MODES=$(kubectl get pvc shared-pvc -n "$NS" -o jsonpath='{.spec.accessModes[*]}' 2>/dev/null)
if [ "$PHASE" != "Bound" ]; then
  bad "PVC shared-pvc is ${PHASE:-missing}, not Bound"
  exit 1
fi
case " $MODES " in
  *ReadWriteMany*|*ReadOnlyMany*) bad "PVC shared-pvc still asks for $MODES, which this cluster cannot provide"; exit 1 ;;
esac
ok "PVC shared-pvc is Bound ($MODES)"

read -r DESIRED UPDATED READY TOTAL <<EOT
$(kubectl get deployment ingest -n "$NS" -o jsonpath='{.spec.replicas} {.status.updatedReplicas} {.status.readyReplicas} {.status.replicas}')
EOT
if [ "$DESIRED" != "1" ] || [ "${UPDATED:-0}" != "1" ] || [ "${READY:-0}" != "1" ] || [ "${TOTAL:-0}" != "1" ]; then
  bad "ingest rollout is not complete (desired ${DESIRED:-?}, updated ${UPDATED:-0}, ready ${READY:-0}, total ${TOTAL:-0})"
  exit 1
fi
ok "ingest is rolled out: 1/1 updated and Ready"

ensure_probe || { bad "could not start the test client pod"; exit 1; }
S=$(pcurl http://ingest/ | tr -d '\r\n')
if [ "$S" != "version=2 data=ok spool=ok" ]; then
  bad "ingest answers '${S:-nothing}', expected version 2 with v1's data and a working spool"
  exit 1
fi
ok "ingest v2 answers: $S"

POD=$(kubectl get pods -n "$NS" -l app=ingest --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
USED=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.spec.volumes[*].persistentVolumeClaim.claimName}')
case " $USED " in
  *" shared-pvc "*) ok "the pod uses shared-pvc and ingest-data" ;;
  *) bad "the ingest pod does not mount shared-pvc"; exit 1 ;;
esac
exit 0
exit 1
