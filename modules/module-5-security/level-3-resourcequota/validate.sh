#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# the guardrail must stay exactly as the team set it
cpu=$(k get resourcequota team-quota -o jsonpath='{.spec.hard.limits\.cpu}' 2>/dev/null)
mem=$(k get resourcequota team-quota -o jsonpath='{.spec.hard.limits\.memory}' 2>/dev/null)
if [ "$cpu" != "2" ] || [ "$mem" != "2Gi" ]; then
  echo "❌ ResourceQuota team-quota must keep limits.cpu=2 and limits.memory=2Gi (found: ${cpu:-missing} / ${mem:-missing})"
  exit 1
fi
echo "✅ team-quota is unchanged"

if [ "$(k get deploy invoice-api -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "3" ]; then
  echo "❌ Deployment invoice-api must exist with 3 replicas"
  exit 1
fi
if ! k rollout status deploy/invoice-api --timeout=45s >/dev/null 2>&1; then
  ready=$(k get deploy invoice-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  echo "❌ invoice-api: ${ready:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ invoice-api has 3 Ready pods"

used=$(k get resourcequota team-quota -o jsonpath='{.status.used.limits\.cpu}' 2>/dev/null)
case "${used:-0}" in 0|"") echo "❌ the quota shows no limits.cpu in use: the pods do not run under it"; exit 1;; esac
echo "✅ the quota accounts for the pods (limits.cpu used: $used of $cpu)"

pod=$(k get pods -l app=invoice-api -o jsonpath='{.items[0].metadata.name}')
if ! k exec "$pod" -- wget -q -O /dev/null -T 4 http://127.0.0.1/ 2>/dev/null; then
  echo "❌ $pod does not answer HTTP"
  exit 1
fi
echo "✅ invoice-api answers HTTP"
exit 0
exit 1
