#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

# 1. history is short but keeps the deployed release and the one before it
n=$(kubectl -n "$NS" get secrets -l owner=release-deployer,app=shop --no-headers 2>/dev/null | wc -l | tr -d ' ')
dep=$(kubectl -n "$NS" get secrets -l owner=release-deployer,app=shop,status=deployed -o name 2>/dev/null | wc -l | tr -d ' ')
if [ "$n" -le 10 ]; then ok "the shop release history has $n Secrets"; else bad "the shop release history still has $n Secrets (limit 10)"; fail=1; fi
if kubectl -n "$NS" get secret sh.release.v1.shop.v24 >/dev/null 2>&1 && [ "$dep" = 1 ]; then
  ok "the deployed release (v24) is still there"
else
  bad "the deployed release record is missing"; fail=1
fi
if kubectl -n "$NS" get secret sh.release.v1.shop.v23 >/dev/null 2>&1; then ok "the previous release (v23) is still there"; else bad "the previous release (v23) was deleted"; fail=1; fi

# 2. the deploy tool prunes: a canary app with a long history, deployed through the real CronJob
max=$(kubectl -n "$NS" get cronjob release-deployer -o jsonpath='{.spec.jobTemplate.spec.template.spec.containers[0].env[?(@.name=="MAX_REVISIONS")].value}' 2>/dev/null)
if [ -n "$max" ] && [ "$max" -ge 2 ] 2>/dev/null && [ "$max" -le 8 ]; then
  kubectl -n "$NS" delete secret -l app=canary >/dev/null 2>&1
  for i in $(seq 1 $((max + 3))); do
    st=superseded; [ "$i" = $((max + 3)) ] && st=deployed
    kubectl -n "$NS" create secret generic "sh.release.v1.canary.v$i" --from-literal=release=x >/dev/null 2>&1
    kubectl -n "$NS" label secret "sh.release.v1.canary.v$i" owner=release-deployer app=canary status=$st revision=$i >/dev/null 2>&1
  done
  job="check-deploy-$RANDOM"
  kubectl -n "$NS" create job "$job" --from=cronjob/release-deployer --dry-run=client -o json 2>/dev/null \
    | jq '.spec.template.spec.containers[0].env += [{"name":"APP","value":"canary"}]' | kubectl -n "$NS" apply -f - >/dev/null 2>&1
  if kubectl -n "$NS" wait --for=condition=complete "job/$job" --timeout=40s >/dev/null 2>&1; then
    c=$(kubectl -n "$NS" get secrets -l app=canary --no-headers 2>/dev/null | wc -l | tr -d ' ')
    if [ "$c" -le "$max" ] && kubectl -n "$NS" get secret "sh.release.v1.canary.v$((max + 4))" >/dev/null 2>&1; then
      ok "a new release prunes its history to $max (history of $((max + 3)) became $c)"
    else
      bad "a new release left $c Secrets in a history limited to $max"; fail=1
    fi
  else
    bad "the deploy Job did not complete"; fail=1
  fi
  kubectl -n "$NS" delete job "$job" --wait=false >/dev/null 2>&1
  kubectl -n "$NS" delete secret -l app=canary >/dev/null 2>&1
else
  bad "the deploy tool keeps unlimited history (MAX_REVISIONS=${max:-unset})"; fail=1
fi

# 3. the syncer is running, polite and fast
if [ "$(ready_count app=config-syncer)" -ge 1 ]; then
  st=$(pcurl http://config-syncer/)
  iv=$(echo "$st" | jq -r '.interval_ms // 0' 2>/dev/null); ms=$(echo "$st" | jq -r '.last_list_ms // 99999' 2>/dev/null)
  if [ "${iv:-0}" -ge 3000 ]; then ok "config-syncer polls every ${iv} ms"; else bad "config-syncer polls every ${iv:-?} ms (need at least 3000)"; fail=1; fi
  if [ "${ms:-99999}" -lt 500 ]; then ok "config-syncer's last list took ${ms} ms"; else bad "config-syncer's last list took ${ms} ms (need under 500)"; fail=1; fi
else
  bad "config-syncer is not running"; fail=1
fi

[ "$fail" = 0 ] && exit 0
exit 1
