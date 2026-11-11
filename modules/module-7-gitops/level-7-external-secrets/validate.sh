#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
app() { kubectl -n argocd get app ledger-api -o jsonpath="$1" 2>/dev/null; }

policy=$(app '{.spec.syncPolicy.automated.prune}/{.spec.syncPolicy.automated.selfHeal}')
if [ "$policy" != "true/true" ]; then
  echo "❌ Application ledger-api no longer has automated sync with prune and self-heal (got '$policy')"
  exit 1
fi

leak=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- sh -c '
  rm -rf /tmp/v && git clone -q /srv/git/ledger.git /tmp/v && cd /tmp/v &&
  grep -rEl "kind: *Secret|summer-2023|r0tated" . --exclude-dir=.git' 2>/dev/null)
if [ -n "$leak" ]; then
  echo "❌ the repository head still holds a Secret or a password in: $(echo $leak)"
  exit 1
fi
echo "✅ repository head has no Secret manifest and no password"

sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application ledger-api: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
echo "✅ Application ledger-api is Synced and Healthy"

ready=$(k get deploy ledger-api -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ Deployment ledger-api has no Ready pod"
  exit 1
fi

secname=$(k get deploy ledger-api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")].valueFrom.secretKeyRef.name}' 2>/dev/null)
seckey=$(k get deploy ledger-api -o jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="DB_PASSWORD")].valueFrom.secretKeyRef.key}' 2>/dev/null)
live=$(k get secret "${secname:-none}" -o jsonpath="{.data.${seckey:-password}}" 2>/dev/null | base64 -d 2>/dev/null)
want=$(k get secret ledger-db-rotated -o jsonpath='{.data.password}' | base64 -d)
if [ -z "$live" ] || [ "$live" != "$want" ]; then
  echo "❌ the Secret the Deployment reads (${secname:-none}) does not hold the rotated password"
  exit 1
fi
echo "✅ Secret ${secname} holds the rotated password"

out=$(k exec probe -- sh -c 'for i in $(seq 10); do curl -s -o /dev/null -w "%{http_code}\n" --max-time 3 http://ledger-api/health; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^200$')
if [ "$good" -ne 10 ]; then
  echo "❌ ledger-api /health returned 200 on only $good of 10 requests"
  exit 1
fi
echo "✅ ledger-api /health returns 200 through the database gateway"
exit 0
exit 1
