#!/bin/bash
NS=${NS:-k8smissions}
app() { kubectl -n argocd get app reports -o jsonpath="$1" 2>/dev/null; }
hpa() { kubectl -n "$NS" get hpa reports -o jsonpath="$1" 2>/dev/null; }

sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
rev=$(app '{.status.sync.revision}')
head=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/reports.git rev-parse main 2>/dev/null)
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application reports: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
if [ -z "$head" ] || [ "$rev" != "$head" ]; then
  echo "❌ Application reports is synced to ${rev:-nothing}, repository head is ${head:-unknown}"
  exit 1
fi
echo "✅ Application reports is Synced and Healthy at the repository head"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 10); do curl -s --max-time 2 http://reports; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^reports v2$')
if [ "$good" -ne 10 ]; then
  echo "❌ Service reports: only $good of 10 requests returned v2"
  exit 1
fi
echo "✅ Service reports answers 10 of 10 requests as v2"

target=$(hpa '{.spec.scaleTargetRef.kind}/{.spec.scaleTargetRef.name}')
min=$(hpa '{.spec.minReplicas}'); max=$(hpa '{.spec.maxReplicas}')
if [ "$target" != "Deployment/reports" ]; then
  echo "❌ HPA reports targets '${target:-nothing}'"
  exit 1
fi
if [ -z "$min" ] || [ -z "$max" ] || [ "$min" -gt "$max" ]; then
  echo "❌ HPA reports has an impossible replica range (${min:-?} to ${max:-?})"
  exit 1
fi
active=$(hpa '{.status.conditions[?(@.type=="ScalingActive")].status}')
cur=$(hpa '{.status.currentMetrics[0].resource.current.averageUtilization}')
if [ "$active" != "True" ] || [ -z "$cur" ]; then
  echo "❌ HPA reports is not scaling yet (ScalingActive=${active:-unknown}, current metric ${cur:-none})"
  exit 1
fi
echo "✅ HPA reports is active at ${cur}% CPU, range $min to $max"
exit 0
exit 1
