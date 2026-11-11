#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
app() { kubectl -n argocd get app storefront -o jsonpath="$1" 2>/dev/null; }

tgt=$(k get hpa storefront -o jsonpath='{.spec.scaleTargetRef.kind}/{.spec.scaleTargetRef.name}' 2>/dev/null)
if [ "$tgt" != "Deployment/storefront" ]; then
  echo "❌ the HPA that scales Deployment storefront is gone (found '${tgt:-none}')"
  exit 1
fi
if [ "$(app '{.spec.syncPolicy.automated.selfHeal}')" != "true" ]; then
  echo "❌ Application storefront no longer has automated sync with self-heal"
  exit 1
fi
echo "✅ HPA still targets storefront and self-heal is on"

# ask Argo for one more sync, as any other change would; it must not reset the replica count
kubectl -n argocd patch app storefront --type merge -p '{"operation":{"sync":{}}}' >/dev/null 2>&1
for _ in $(seq 10); do
  [ "$(app '{.status.operationState.phase}')" = "Succeeded" ] && break
  sleep 1
done

for _ in $(seq 12); do
  r=$(k get deploy storefront -o jsonpath='{.spec.replicas}' 2>/dev/null)
  [ "${r:-0}" -ge 3 ] && break
  sleep 3
done
if [ "${r:-0}" -lt 3 ]; then
  echo "❌ Deployment storefront has ${r:-0} replicas, it should hold at least 3"
  exit 1
fi

for i in $(seq 6); do
  r=$(k get deploy storefront -o jsonpath='{.spec.replicas}' 2>/dev/null)
  if [ "${r:-0}" -lt 3 ]; then
    echo "❌ replicas dropped to ${r:-0} while watching (sample $i of 6)"
    exit 1
  fi
  sleep 4
done
echo "✅ Deployment storefront held 3 or more replicas for 20s"

ready=$(k get deploy storefront -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 3 ]; then
  echo "❌ only ${ready:-0} storefront pods are Ready"
  exit 1
fi
sync=$(app '{.status.sync.status}'); health=$(app '{.status.health.status}')
if [ "$sync" != "Synced" ] || [ "$health" != "Healthy" ]; then
  echo "❌ Application storefront: sync=${sync:-none} health=${health:-none}"
  exit 1
fi
echo "✅ Application storefront is Synced and Healthy with $ready Ready pods"
exit 0
exit 1
