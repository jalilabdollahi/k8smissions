#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
SA="--as=system:serviceaccount:$NS:report-operator"
can() { kubectl auth can-i "$@" $SA -n "$NS" 2>/dev/null; }

ready=$(k get deploy report-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ report-operator has no Ready pod"
  exit 1
fi

# least privilege first: what it must and must not be able to do
bad=0
[ "$(can list pods)" = yes ] || { echo "❌ the operator cannot list pods"; bad=1; }
[ "$(can create configmaps)" = yes ] || { echo "❌ the operator cannot create configmaps"; bad=1; }
[ "$(can patch reports.audit.acme.io --subresource=status)" = yes ] || { echo "❌ the operator cannot patch the status of Reports"; bad=1; }
[ "$(can get secrets)" = no ] || { echo "❌ the operator can read secrets, which it has no business doing"; bad=1; }
[ "$(can delete nodes)" = no ] || { echo "❌ the operator can delete nodes"; bad=1; }
[ "$(can '*' '*')" = no ] || { echo "❌ the operator can do everything"; bad=1; }
[ "$bad" = 0 ] || exit 1
echo "✅ the operator's permissions are enough and not more"

for r in q3-capacity q3-access q3-cost; do
  phase=$(k get report "$r" -o jsonpath='{.status.phase}' 2>/dev/null)
  pc=$(k get cm "report-$r" -o jsonpath='{.data.podCount}' 2>/dev/null)
  if [ "$phase" != Done ] || [ -z "$pc" ]; then
    echo "❌ Report $r is '${phase:-empty}' and its summary ConfigMap is '${pc:-missing}'"
    bad=1
  fi
done
[ "$bad" = 0 ] || exit 1
echo "✅ all three Reports are Done with a summary"

k delete report probe-r --ignore-not-found >/dev/null 2>&1
k delete cm report-probe-r --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null <<'Y'
apiVersion: audit.acme.io/v1
kind: Report
metadata: {name: probe-r}
spec: {title: "probe"}
Y
ok=0
for i in $(seq 1 10); do
  if [ "$(k get report probe-r -o jsonpath='{.status.phase}' 2>/dev/null)" = Done ] && k get cm report-probe-r >/dev/null 2>&1; then ok=1; break; fi
  sleep 2
done
k delete report probe-r --ignore-not-found >/dev/null 2>&1
k delete cm report-probe-r --ignore-not-found >/dev/null 2>&1
if [ "$ok" != 1 ]; then
  echo "❌ a new Report is not processed within 20 seconds"
  exit 1
fi
echo "✅ a new Report is processed"
exit 0
exit 1
