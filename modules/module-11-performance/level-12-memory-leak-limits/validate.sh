#!/bin/bash
# Level 12: memory.current of both services read from the cgroup, twice, plus restart counters.
. ../_fixtures/lib.sh

for d in profile-api render-svc; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
  lim=$(kubectl get deployment "$d" -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')
  if [ -z "$lim" ]; then
    bad "$d has no memory limit any more"
    exit 1
  fi
done
if ! wait_ready app=profile-api 1 60 || ! wait_ready app=render-svc 1 60; then
  bad "profile-api ready: $(ready_count app=profile-api)/1, render-svc ready: $(ready_count app=render-svc)/1"
  exit 1
fi
PP=$(live_pods app=profile-api | head -1); RP=$(live_pods app=render-svc | head -1)
R0=$(restart_sum app=profile-api); S0=$(restart_sum app=render-svc)

a=$(cgroup_mem_mi "$PP" api); r0=$(cgroup_mem_mi "$RP" render)
sleep 12
b=$(cgroup_mem_mi "$PP" api)
sleep 12
c=$(cgroup_mem_mi "$PP" api); r1=$(cgroup_mem_mi "$RP" render)
if [ -z "$a" ] || [ -z "$c" ] || [ -z "$r1" ]; then
  bad "could not read the memory of the pods (did a pod restart during the test?)"
  exit 1
fi

if [ "$(restart_sum app=profile-api)" != "$R0" ] || [ "$(restart_sum app=render-svc)" != "$S0" ]; then
  bad "a container restarted during the test"
  exit 1
fi
if [ $((c - b)) -gt 6 ]; then
  bad "profile-api memory is still climbing: ${a}Mi, ${b}Mi, ${c}Mi at 12 second steps"
  exit 1
fi
ok "profile-api memory is flat: ${a}Mi, ${b}Mi, ${c}Mi"

rlim=$(mem_to_mi "$(kubectl get deployment render-svc -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')")
plim=$(mem_to_mi "$(kubectl get deployment profile-api -n "$NS" -o jsonpath='{.spec.template.spec.containers[0].resources.limits.memory}')")
if [ "$r1" -gt 100 ] && [ $((rlim * 100)) -lt $((r1 * 110)) ]; then
  bad "render-svc uses ${r1}Mi under a ${rlim}Mi limit: not enough headroom"
  exit 1
fi
ok "render-svc uses ${r1}Mi under a ${rlim}Mi limit"
if [ $((c * 100)) -gt $((plim * 80)) ]; then
  bad "profile-api uses ${c}Mi of its ${plim}Mi limit"
  exit 1
fi

code=$(kubectl exec -n "$NS" "$RP" -c render -- python -c "
import urllib.request,urllib.error
try: print(urllib.request.urlopen('http://127.0.0.1:8080/render',timeout=4).status)
except urllib.error.HTTPError as e: print(e.code)
except Exception: print(0)" 2>/dev/null)
if [ "$code" != 200 ]; then
  bad "render-svc answers /render with ${code:-no answer}: its output must stay complete"
  exit 1
fi
ok "render-svc answers /render with 200"
if [ "$r1" -lt 150 ]; then
  bad "render-svc only holds ${r1}Mi: its template set is no longer fully loaded"
  exit 1
fi
exit 0
exit 1
