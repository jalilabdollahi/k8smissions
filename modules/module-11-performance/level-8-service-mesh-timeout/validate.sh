#!/bin/bash
# Level 8: slow requests pass through Envoy, Envoy's own counters agree, and a hung backend is still cut off.
. ../_fixtures/lib.sh
SEL=app=invoice-render

if ! kubectl get deployment invoice-render -n "$NS" >/dev/null 2>&1; then
  bad "Deployment invoice-render does not exist"
  exit 1
fi
if ! wait_ready "$SEL" 1 60; then
  bad "invoice-render has no Ready pod (it needs both the app and the envoy container)"
  exit 1
fi
POD=$(live_pods "$SEL" | head -1)

# read one Envoy admin stat from inside the pod (the Envoy image has no curl)
stat() {
  kubectl exec -n "$NS" "$POD" -c app -- python -c \
    "import urllib.request as u;print(u.urlopen('http://127.0.0.1:9901/stats?filter=$1',timeout=4).read().decode())" 2>/dev/null |
    awk -F': ' -v k="cluster.app.$1" '$1==k{print $2}'
}
T0=$(stat upstream_rq_timeout); N0=$(stat upstream_rq_total)
if [ -z "$T0" ] || [ -z "$N0" ]; then
  bad "cannot read the Envoy admin stats from the pod (is the app container still there?)"
  exit 1
fi

OUT=$(run_probe "http://invoice-render/render" 3 6 15 TIMEOUT=30)
cnt=$(echo "$OUT" | jq -r '.count // 0'); errs=$(echo "$OUT" | jq -r '.errors // 999'); p50=$(echo "$OUT" | jq -r '.p50_ms // 0')
T1=$(stat upstream_rq_timeout); N1=$(stat upstream_rq_total)
if [ "$cnt" -lt 5 ]; then
  bad "only $cnt invoice requests completed in the test window"
  exit 1
fi
if [ "$errs" -ne 0 ]; then
  bad "$errs of $cnt invoice requests through Service invoice-render failed ($(echo "$OUT" | jq -c '.codes'))"
  exit 1
fi
if [ "$p50" -lt 5000 ]; then
  bad "requests are not slow (p50 ${p50}ms): the test did not hit the PDF renderer"
  exit 1
fi
ok "$cnt invoice requests (p50 ${p50}ms) all returned 200 through the proxy"
if [ $((N1 - N0)) -lt "$cnt" ]; then
  bad "the requests did not go through Envoy's upstream cluster"
  exit 1
fi
if [ "$T1" != "$T0" ]; then
  bad "Envoy counted $((T1 - T0)) upstream timeouts during the test"
  exit 1
fi
ok "Envoy counted no upstream timeouts"

# a backend that never answers must still be cut off by the proxy
RES=$(kubectl exec -n "$NS" "$POD" -c app -- python -c "
import time, urllib.request, urllib.error
t = time.time()
try:
    code = urllib.request.urlopen('http://127.0.0.1:8080/hang', timeout=30).status
except urllib.error.HTTPError as e:
    code = e.code
except Exception:
    code = 0
print(code, int(time.time() - t))" 2>/dev/null)
code=${RES% *}; secs=${RES#* }
if [ "$code" != 504 ] || [ "${secs:-99}" -gt 26 ]; then
  bad "a request to a hung backend was not cut off with a 504 within 26s (got ${code:-none} after ${secs:-?}s)"
  exit 1
fi
ok "a hung backend is still cut off with a 504 after ${secs}s"
exit 0
exit 1
