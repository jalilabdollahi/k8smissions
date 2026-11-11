#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app grand-finale-app -o jsonpath="$1" 2>/dev/null; }

sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application grand-finale-app: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
echo "✅ Application grand-finale-app is Synced and Healthy"

ready=$(kubectl -n "$NS" get deploy grand-finale-app -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
tag=$(kubectl -n "$NS" get deploy grand-finale-app -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ Deployment grand-finale-app: ${ready:-0} of 2 pods Ready"
  exit 1
fi
if [ "${tag##*:}" != "1.0" ]; then
  echo "❌ Deployment grand-finale-app runs image ${tag:-none}, not the production tag"
  exit 1
fi
echo "✅ 2 pods Ready on image $tag"

ep=$(kubectl -n "$NS" get endpointslices -l kubernetes.io/service-name=grand-finale-app -o jsonpath='{.items[*].endpoints[*].addresses[0]}' 2>/dev/null | wc -w | tr -d ' ')
if [ "$ep" -lt 2 ]; then
  echo "❌ Service grand-finale-app has $ep endpoints"
  exit 1
fi
out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://grand-finale-app; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^grand-finale v2.3$')
if [ "$good" -ne 20 ]; then
  echo "❌ Service grand-finale-app: only $good of 20 requests returned the production page"
  exit 1
fi
echo "✅ Service grand-finale-app answers 20 of 20 requests"
exit 0
exit 1
