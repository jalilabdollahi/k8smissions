#!/bin/bash
NS=${NS:-k8smissions}
can() { kubectl auth can-i "$@" --as=dashboard-user --as-group=support 2>/dev/null; }

if ! kubectl get clusterrole ticket-viewer >/dev/null 2>&1; then
  echo "❌ ClusterRole ticket-viewer does not exist"
  exit 1
fi

# 1. it is still an aggregated role, with no wildcard anywhere
sel=$(kubectl get clusterrole ticket-viewer -o jsonpath='{.aggregationRule.clusterRoleSelectors}')
if [ -z "$sel" ]; then
  echo "❌ ticket-viewer has lost its aggregationRule: its rules must come from other ClusterRoles"
  exit 1
fi
if kubectl get clusterrole ticket-viewer -o jsonpath='{.rules}' | grep -q '"\*"'; then
  echo "❌ ticket-viewer contains a wildcard rule"
  exit 1
fi
if kubectl get clusterrolebinding -o json | jq -e '.items[] | select(.roleRef.name=="cluster-admin") | .subjects[]? | select(.kind=="Group" and .name=="support")' >/dev/null; then
  echo "❌ group support is bound to cluster-admin"
  exit 1
fi
echo "✅ ticket-viewer is still an aggregated role without wildcards"

# 2. what support must be able to do
for want in "list jobs" "list cronjobs" "get events" "list events"; do
  r=${want%% *}; res=${want#* }
  if [ "$(can "$r" "$res" -n "$NS")" != "yes" ]; then
    echo "❌ group support cannot $want in $NS"
    exit 1
  fi
done
if [ "$(can get configmap/ticket-notes -n "$NS")" != "yes" ]; then
  echo "❌ the ticket-notes contribution no longer reaches support"
  exit 1
fi
echo "✅ support can list jobs and cronjobs and read events"

# 3. what must stay forbidden
for no in "delete jobs" "create jobs" "create cronjobs" "delete events" "get secrets" "list secrets" "delete pods" "list configmaps" "create clusterrolebindings"; do
  if [ "$(can $no -n "$NS")" = "yes" ]; then
    echo "❌ group support is too powerful: it can $no"
    exit 1
  fi
done
if [ "$(can '*' '*')" = "yes" ] || [ "$(can get secrets -n kube-system)" = "yes" ]; then
  echo "❌ group support has admin-like access"
  exit 1
fi
echo "✅ support still cannot modify anything, read secrets or act as admin"
exit 0
exit 1
