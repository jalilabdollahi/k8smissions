#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

want=$(kubectl -n "$NS" get deploy ledger-sync -o jsonpath='{.spec.replicas}' 2>/dev/null)
n=$(ready_count app=ledger-sync)
if [ "${want:-0}" = 2 ] && [ "${n:-0}" = 2 ]; then ok "ledger-sync: 2 of 2 pods Ready"; else bad "ledger-sync: ${n:-0} of ${want:-?} pods Ready (need 2)"; exit 1; fi

for p in $(live_pods app=ledger-sync); do
  ip=$(kubectl -n "$NS" get pod "$p" -o jsonpath='{.status.podIP}')
  st=$(pcurl "http://$ip:8080/status")
  pods=$(echo "$st" | jq -r '.pods_listed // empty' 2>/dev/null)
  rate=$(echo "$st" | jq -r '.settings.rate_limit // empty' 2>/dev/null)
  if [ -n "$pods" ] && [ "$pods" -ge 1 ] && [ "$rate" = 250 ]; then
    ok "$p listed $pods pods and read ledger-settings (rate_limit $rate)"
  else
    bad "$p: pods error '$(echo "$st" | jq -r '.pods_error // "none"' 2>/dev/null)', settings error '$(echo "$st" | jq -r '.settings_error // "none"' 2>/dev/null)'"; fail=1
  fi
done

sa=$(kubectl -n "$NS" get deploy ledger-sync -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
sa=${sa:-default}
who="system:serviceaccount:$NS:$sa"
can() { kubectl auth can-i "$@" --as="$who" 2>/dev/null; }
leak=""
[ "$(can list secrets -n "$NS")" = no ] || leak="$leak list-secrets"
[ "$(can get secrets -n platform-config)" = no ] || leak="$leak platform-secrets"
[ "$(can list nodes)" = no ] || leak="$leak nodes"
[ "$(can list pods --all-namespaces)" = no ] || leak="$leak cluster-wide-pods"
[ "$(can delete pods -n "$NS")" = no ] || leak="$leak delete-pods"
[ "$(can '*' '*' -n "$NS")" = no ] || leak="$leak wildcard"
if [ -z "$leak" ]; then ok "$sa is still least-privilege"; else bad "$sa is over-privileged:$leak"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
