#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app ledger-api -o jsonpath="$1" 2>/dev/null; }

sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
head=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/ledger.git rev-parse main 2>/dev/null)
rev=$(app '{.status.sync.revision}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application ledger-api: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
if [ -z "$head" ] || [ "$rev" != "$head" ]; then
  echo "❌ Application ledger-api is synced to ${rev:-nothing}, repository head is ${head:-unknown}"
  exit 1
fi
echo "✅ Application ledger-api is Synced and Healthy at the repository head"

ready=$(kubectl -n ledger-prod get deploy ledger-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ ledger-prod/ledger-api: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ ledger-prod/ledger-api has 2 Ready pods"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://ledger-api.ledger-prod; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^ledger-api v2.4$')
if [ "$good" -ne 20 ]; then
  echo "❌ ledger-api.ledger-prod: only $good of 20 requests returned v2.4"
  exit 1
fi
echo "✅ ledger-api.ledger-prod answers 20 of 20 requests"
exit 0
exit 1
