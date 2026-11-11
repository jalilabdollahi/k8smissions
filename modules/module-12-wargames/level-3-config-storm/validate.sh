#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
WANT='{"MAX_CONN": "200", "PRICING_URL": "http://pricing.k8smissions.svc:8080/v2"}'
ensure_probe || { bad "could not start the probe pod"; exit 1; }

web=$(live_pods app=shop-web); nweb=$(ready_count app=shop-web)
want_web=$(kubectl -n "$NS" get deploy shop-web -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${want_web:-0}" -ge 3 ] && [ "${nweb:-0}" -ge "$want_web" ]; then ok "shop-web: $nweb pods Ready"; else bad "shop-web: ${nweb:-0} of ${want_web:-?} pods Ready (need 3)"; fail=1; fi
wk=$(live_pods app=shop-worker); nwk=$(ready_count app=shop-worker)
if [ "${nwk:-0}" -ge 2 ]; then ok "shop-worker: $nwk pods Ready"; else bad "shop-worker: fewer than 2 pods Ready"; fail=1; fi

for p in $web $wk; do
  ip=$(kubectl -n "$NS" get pod "$p" -o jsonpath='{.status.podIP}')
  got=$(pcurl "http://$ip:8080/config" | tr -d '\n')
  if [ "$got" = "$WANT" ]; then
    ok "$p serves the v41 values"
  else
    bad "$p serves ${got:-nothing}"; fail=1
  fi
done

job="check-report-$RANDOM"
if kubectl -n "$NS" create job "$job" --from=cronjob/shop-report >/dev/null 2>&1; then
  if kubectl -n "$NS" wait --for=condition=complete "job/$job" --timeout=40s >/dev/null 2>&1; then
    ok "a Job from shop-report completes"
  else
    bad "a Job from shop-report did not complete"; fail=1
  fi
  kubectl -n "$NS" delete job "$job" --wait=false >/dev/null 2>&1
else
  bad "CronJob shop-report is missing"; fail=1
fi

[ "$fail" = 0 ] && exit 0
exit 1
