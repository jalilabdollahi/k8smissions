#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

if rollout_done billing-api 3; then
  ok "billing-api: rollout complete, 3 of 3 Ready"
else
  st=$(kubectl -n "$NS" get deploy billing-api -o jsonpath='{.status.updatedReplicas}/{.status.readyReplicas}/{.spec.replicas}' 2>/dev/null)
  bad "billing-api: rollout not complete (updated/ready/wanted: $st)"; fail=1
fi
if [ "$(ready_count app=billing-db)" -ge 1 ]; then ok "billing-db is Ready"; else bad "billing-db is not Ready"; fail=1; fi

n=0
for i in 1 2 3 4 5 6; do
  id="inv-$RANDOM$i"
  code=$(pcurl -o /dev/null -w '%{http_code}' -X POST -d "amount=$i" "http://billing-api/invoices/$id")
  back=$(pcurl "http://billing-api/invoices/$id")
  [ "$code" = "201" ] && [ "$back" = "amount=$i" ] && n=$((n + 1))
done
if [ "$n" = 6 ]; then ok "invoices written and read back through billing-api (6 of 6)"; else bad "only $n of 6 invoices were stored by the database"; fail=1; fi

job="check-export-$RANDOM"
if kubectl -n "$NS" create job "$job" --from=cronjob/invoice-export >/dev/null 2>&1; then
  if kubectl -n "$NS" wait --for=condition=complete "job/$job" --timeout=40s >/dev/null 2>&1; then
    ok "a Job from invoice-export completes"
  else
    bad "a Job from invoice-export did not complete"; fail=1
  fi
  kubectl -n "$NS" delete job "$job" --wait=false >/dev/null 2>&1
else
  bad "CronJob invoice-export is missing"; fail=1
fi

[ "$fail" = 0 ] && exit 0
exit 1
