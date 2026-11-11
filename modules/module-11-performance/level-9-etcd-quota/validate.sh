#!/bin/bash
# Level 9: room for the bot again, exporter runs leave nothing behind, nothing live was deleted.
. ../_fixtures/lib.sh

if ! kubectl get resourcequota object-counts -n "$NS" >/dev/null 2>&1; then
  bad "ResourceQuota object-counts is gone (the quota stays, the objects go)"
  exit 1
fi
hard=$(kubectl get resourcequota object-counts -n "$NS" -o json | jq -r '.spec.hard["count/configmaps"] // "none"')
if [ "$hard" != 100 ]; then
  bad "the quota limit was changed (count/configmaps is $hard, it must stay 100)"
  exit 1
fi
if ! kubectl get configmap current-release -n "$NS" >/dev/null 2>&1; then
  bad "ConfigMap current-release is gone"
  exit 1
fi
if ! kubectl get cronjob exporter -n "$NS" >/dev/null 2>&1; then
  bad "CronJob exporter does not exist"
  exit 1
fi

# every ConfigMap a pod mounts or references must still exist
MISSING=""
for cm in $(kubectl get pods -n "$NS" -o json | jq -r '
    [.items[] | .spec.volumes[]? | (.configMap.name // empty), (.projected.sources[]?.configMap.name // empty)] | unique[]'); do
  kubectl get configmap "$cm" -n "$NS" >/dev/null 2>&1 || MISSING="$MISSING $cm"
done
if [ -n "$MISSING" ]; then
  bad "ConfigMaps still used by pods are gone:$MISSING"
  exit 1
fi
if ! wait_ready app=billing-web 1 30; then
  bad "billing-web is not Ready"
  exit 1
fi
ok "quota, current-release and everything billing-web mounts are intact"

# the bot can create a ConfigMap again
if ! kubectl create configmap release-validate -n "$NS" --from-literal=v=1 >/dev/null 2>/tmp/m11-l9.$$; then
  bad "creating a ConfigMap still fails: $(tr -d '\n' </tmp/m11-l9.$$ | cut -c1-120)"
  rm -f /tmp/m11-l9.$$
  exit 1
fi
rm -f /tmp/m11-l9.$$
kubectl delete configmap release-validate -n "$NS" >/dev/null 2>&1
ok "a new ConfigMap can be created in the namespace"

count() { kubectl get configmaps -n "$NS" -o name | wc -l | tr -d ' '; }
run_exporter() {
  local j="validate-exp-$1"
  kubectl delete job "$j" -n "$NS" --ignore-not-found >/dev/null 2>&1
  kubectl create job "$j" -n "$NS" --from=cronjob/exporter >/dev/null 2>&1 || return 1
  local end=$((SECONDS + 40)) s
  while [ $SECONDS -lt $end ]; do
    s=$(kubectl get job "$j" -n "$NS" -o jsonpath='{.status.succeeded}/{.status.failed}' 2>/dev/null)
    [ "${s%/*}" = 1 ] && return 0
    [ -n "${s#*/}" ] && [ "${s#*/}" != 0 ] && return 1
    sleep 2
  done
  return 1
}
cleanup() { kubectl delete job validate-exp-1 validate-exp-2 -n "$NS" --ignore-not-found --wait=false >/dev/null 2>&1; }
trap cleanup EXIT

if ! run_exporter 1; then
  bad "an exporter run (Job from CronJob exporter) did not complete"
  exit 1
fi
C1=$(count)
if ! run_exporter 2; then
  bad "the second exporter run did not complete"
  exit 1
fi
C2=$(count)
if [ "$C2" -gt "$C1" ]; then
  bad "each exporter run leaves one more ConfigMap behind ($C1 -> $C2)"
  exit 1
fi
if [ "$C2" -ge 100 ]; then
  bad "the namespace is still full: $C2 of 100 ConfigMaps"
  exit 1
fi
ok "exporter runs leave nothing behind ($C1 -> $C2 ConfigMaps, limit 100)"
exit 0
exit 1
