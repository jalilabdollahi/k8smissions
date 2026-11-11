#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app ledger-api -o jsonpath="$1" 2>/dev/null; }

sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
rev=$(app '{.status.sync.revision}')
head=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/ledger.git rev-parse main 2>/dev/null)
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application ledger-api: sync=${sync:-none} health=${health:-none} ($(app '{.status.operationState.phase}'))"
  exit 1
fi
if [ -z "$head" ] || [ "$rev" != "$head" ]; then
  echo "❌ Application ledger-api is synced to ${rev:-nothing}, repository head is ${head:-unknown}"
  exit 1
fi
echo "✅ Application ledger-api is Synced and Healthy at the repository head"

status=$(kubectl -n "$NS" exec probe -- curl -s --max-time 3 http://schema-db/status 2>/dev/null)
case "$status" in
  *'"version": 3'*) ;;
  *) echo "❌ schema-db is not at version 3 (${status:-no answer})"; exit 1 ;;
esac
if ! echo "$status" | grep -q '"applied": \[3\]'; then
  echo "❌ the migration to version 3 was not applied exactly once: $status"
  exit 1
fi
echo "✅ schema-db is at version 3, migration applied exactly once"

ready=$(kubectl -n "$NS" get deploy ledger-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment ledger-api: ${ready:-0} of 2 pods Ready"
  exit 1
fi
out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 15); do curl -s --max-time 2 http://ledger-api; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^ledger-api v3 schema=3$')
if [ "$good" -ne 15 ]; then
  echo "❌ Service ledger-api: only $good of 15 requests reported schema 3"
  exit 1
fi
echo "✅ Service ledger-api answers 15 of 15 requests on schema 3"
exit 0
exit 1
