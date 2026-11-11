#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
ensure_probe || { bad "could not start the probe pod"; exit 1; }

# mem_bytes <quantity>: Mi/Gi/M/G/plain bytes
mem_bytes() {
  echo "$1" | awk '/Ki$/{print $1*1024;next} /Mi$/{print $1*1048576;next} /Gi$/{print $1*1073741824;next} /M$/{print $1*1000000;next} /G$/{print $1*1000000000;next} {print $1+0}'
}

before=""
for s in alpha beta gamma; do
  lim=$(kubectl -n "$NS" get deploy "svc-$s" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}' 2>/dev/null)
  b=$(mem_bytes "${lim:-0}")
  if [ "${b:-0}" -gt 0 ] && [ "$b" -le 536870912 ]; then
    ok "svc-$s has a memory limit ($lim)"
  else
    bad "svc-$s must keep a memory limit of at most 512Mi (found: ${lim:-none})"; fail=1
  fi
  n=$(ready_count "app=svc-$s")
  if [ "${n:-0}" -ge 1 ]; then ok "svc-$s: $n pod Ready"; else bad "svc-$s: no Ready pod"; fail=1; fi
  before="$before $(restart_sum "app=svc-$s")"
done
[ "$fail" = 0 ] || exit 1

sleep 20
i=0
for s in alpha beta gamma; do
  i=$((i+1)); b=$(echo $before | cut -d' ' -f$i)
  a=$(restart_sum "app=svc-$s"); n=$(ready_count "app=svc-$s")
  if [ "$a" = "$b" ] && [ "${n:-0}" -ge 1 ]; then ok "svc-$s: no restarts in 20s"; else bad "svc-$s restarted or lost its pod during the 20s window"; fail=1; fi
  w=$(pcurl "http://svc-$s/work")
  cache=$(echo "$w" | jq -r '.cache_mb // 0' 2>/dev/null)
  spool=$(echo "$w" | jq -r '.spool_mb // 0' 2>/dev/null)
  if [ "${cache:-0}" -ge 16 ]; then ok "svc-$s /work: cache ${cache} MB warm"; else bad "svc-$s /work: cache '${cache:-?}' MB (need 16 or more) or no answer"; fail=1; fi
  if [ "$s" = gamma ]; then
    if [ "${spool:-0}" -ge 40 ]; then ok "svc-gamma /work: export spool of ${spool} MB on its volume"; else bad "svc-gamma has no 40 MB spool (found ${spool:-0} MB)"; fail=1; fi
  fi
done
[ "$fail" = 0 ] && exit 0
exit 1
