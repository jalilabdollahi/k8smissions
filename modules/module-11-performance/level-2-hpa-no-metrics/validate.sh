#!/bin/bash
# Level 2: the HPA must read CPU for thumbnailer and scale it under load.
. ../_fixtures/lib.sh

if ! kubectl get deployment thumbnailer -n "$NS" >/dev/null 2>&1 || \
   ! kubectl get hpa thumbnailer -n "$NS" >/dev/null 2>&1; then
  bad "Deployment thumbnailer and HorizontalPodAutoscaler thumbnailer must both exist"
  exit 1
fi
TARGET=$(kubectl get hpa thumbnailer -n "$NS" -o jsonpath='{.spec.scaleTargetRef.name}')
if [ "$TARGET" != thumbnailer ]; then
  bad "the HPA does not target Deployment thumbnailer"
  exit 1
fi
NAMES=$(kubectl get deployment thumbnailer -n "$NS" -o jsonpath='{.spec.template.spec.containers[*].name}')
for c in resizer log-shipper; do
  case " $NAMES " in
    *" $c "*) ;;
    *) bad "the pod needs both resizer and log-shipper (found: $NAMES)"; exit 1 ;;
  esac
done
ok "both containers are still in the pod template"

# 1. the HPA reads a number
util=""
for i in $(seq 1 12); do
  util=$(kubectl get hpa thumbnailer -n "$NS" -o json | jq -r '
    [.status.currentMetrics[]? | (.resource // .containerResource // empty) | .current.averageUtilization // empty] | first // empty')
  [ -n "$util" ] && break
  sleep 3
done
if [ -z "$util" ]; then
  bad "the HPA still has no CPU utilisation to work with (TARGETS is <unknown>)"
  exit 1
fi
ok "HPA reads CPU utilisation: ${util}%"

# 2. the autoscaler acts on it under load
start_load validate-load "http://thumbnailer/resize" 14 4 TIMEOUT=5
end=$((SECONDS + 45))
reps=1
while [ $SECONDS -lt $end ]; do
  reps=$(kubectl get deployment thumbnailer -n "$NS" -o jsonpath='{.status.replicas}')
  [ "${reps:-1}" -gt 1 ] && break
  sleep 3
done
if [ "${reps:-1}" -le 1 ]; then
  bad "thumbnailer is under load but still has $reps replica after 45s"
  exit 1
fi
ok "the HPA scaled thumbnailer to $reps replicas"
if ! kubectl get hpa thumbnailer -n "$NS" >/dev/null 2>&1; then
  bad "the HPA disappeared"
  exit 1
fi
exit 0
exit 1
