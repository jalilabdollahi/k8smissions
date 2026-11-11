#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

dead=$(kubectl -n "$NS" get deploy storefront -o json 2>/dev/null | jq -r '[.spec.template.spec | (.initContainers // []) + .containers | .[].image | select(test("corp-mirror"))] | length')
if [ "${dead:-1}" = 0 ]; then ok "no image refers to the retired mirror"; else bad "${dead:-?} image(s) still point at registry.corp-mirror.invalid"; fail=1; fi

names=$(kubectl -n "$NS" get deploy storefront -o jsonpath='{.spec.template.spec.containers[*].name}' 2>/dev/null)
case " $names " in *" metrics-sidecar "*) ok "the metrics-sidecar container is still part of the pod" ;; *) bad "the metrics-sidecar container is gone"; fail=1 ;; esac

if rollout_done storefront 2; then
  ok "storefront: rollout complete, 2 of 2 Ready"
else
  bad "storefront: rollout not complete ($(kubectl -n "$NS" get pods -l app=storefront --no-headers 2>/dev/null | awk '{printf "%s ", $3}'))"; fail=1
fi

# every container of every pod has run: init finished, both containers running
notrun=$(kubectl -n "$NS" get pods -l app=storefront -o json 2>/dev/null | jq '[.items[] | select(.metadata.deletionTimestamp==null)
  | select((([.status.initContainerStatuses[]? | select(.state.terminated.exitCode==0)] | length) < 1) or (([.status.containerStatuses[]? | select(.state.running)] | length) < 2))] | length')
if [ "${notrun:-1}" = 0 ]; then ok "init container finished and both containers are running in every pod"; else bad "$notrun pod(s) do not have every container running"; fail=1; fi

n=0
for i in 1 2 3 4 5 6; do
  b=$(pcurl http://storefront/ | tr -d '\n')
  [ "$b" = "storefront 3.2 - spring catalogue" ] && n=$((n + 1))
done
if [ "$n" = 6 ]; then ok "storefront serves the 3.2 page (6 of 6)"; else bad "only $n of 6 requests returned the 3.2 page"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
