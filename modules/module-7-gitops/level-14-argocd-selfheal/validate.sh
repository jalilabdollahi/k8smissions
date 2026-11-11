#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app payments-api -o jsonpath="$1" 2>/dev/null; }
git_in_pod() { kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/payments-api.git "$@" 2>/dev/null; }

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 10); do curl -s --max-time 4 http://payments-api/ping; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c 'upstream ok')
if [ "$good" -ne 10 ]; then
  echo "❌ payments-api /ping: only $good of 10 requests succeeded ($(echo "$out" | head -1))"
  exit 1
fi
echo "✅ payments-api /ping succeeds on 10 of 10 requests"

head=$(git_in_pod rev-parse main); count=$(git_in_pod rev-list --count main)
rev=$(app '{.status.sync.revision}'); sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application payments-api: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
if [ "${count:-0}" -lt 2 ] || [ -z "$head" ] || [ "$rev" != "$head" ]; then
  echo "❌ the Application is not synced to a new commit in the repository (revision ${rev:-none}, commits ${count:-0})"
  exit 1
fi
echo "✅ Application payments-api is Synced and Healthy at commit ${rev:0:7}"

want=$(kubectl -n "$NS" get deploy payments-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
kubectl -n "$NS" scale deploy payments-api --replicas=$((want + 1)) >/dev/null 2>&1
for _ in $(seq 10); do
  now=$(kubectl -n "$NS" get deploy payments-api -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [ "$now" = "$want" ] && break
  sleep 3
done
if [ "$now" != "$want" ]; then
  kubectl -n "$NS" scale deploy payments-api --replicas="$want" >/dev/null 2>&1
  echo "❌ a manual scale was not reverted within 30s: self-heal is not working"
  exit 1
fi
echo "✅ self-heal still reverts manual changes"
exit 0
exit 1
