#!/bin/bash
PNS=pay-restricted
k() { kubectl -n "$PNS" "$@"; }

enf=$(kubectl get ns "$PNS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce}' 2>/dev/null)
if [ "$enf" != "restricted" ]; then
  echo "❌ namespace $PNS must keep pod-security.kubernetes.io/enforce=restricted (found: ${enf:-none})"
  exit 1
fi
ver=$(kubectl get ns "$PNS" -o jsonpath='{.metadata.labels.pod-security\.kubernetes\.io/enforce-version}')
case "${ver:-latest}" in latest|v1.*) ;; *) echo "❌ the enforce-version of $PNS must not be pinned back"; exit 1;; esac
echo "✅ namespace $PNS still enforces restricted"

if [ "$(k get deploy report-ui -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ]; then
  echo "❌ Deployment report-ui must exist with 2 replicas"
  exit 1
fi
if ! k rollout status deploy/report-ui --timeout=60s >/dev/null 2>&1; then
  echo "❌ report-ui: $(k get deploy report-ui -o jsonpath='{.status.readyReplicas}')/2 pods Ready"
  exit 1
fi
echo "✅ report-ui: 2 of 2 pods Ready"

pod=$(k get pods -l app=report-ui -o jsonpath='{.items[0].metadata.name}')
if ! k exec "$pod" -c web -- wget -q -O /dev/null -T 4 http://127.0.0.1:8080/ 2>/dev/null; then
  echo "❌ report-ui does not answer HTTP on 8080"
  exit 1
fi
echo "✅ report-ui answers HTTP"

# admission still rejects a privileged pod
out=$(k run priv-check --image=busybox:1.36 --privileged --dry-run=server -o name --command -- sleep 1 2>&1)
if ! echo "$out" | grep -q 'violates PodSecurity'; then
  echo "❌ a privileged pod is not rejected in $PNS any more"
  exit 1
fi
echo "✅ admission still rejects privileged pods"
exit 0
exit 1
