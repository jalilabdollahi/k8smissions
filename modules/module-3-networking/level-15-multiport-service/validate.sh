#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CTRL=http://ingress-nginx-controller.ingress-nginx.svc

ready=$(k get deploy gateway -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ] || ! k get ingress gateway >/dev/null 2>&1; then
  echo "❌ Deployment gateway (2 Ready pods) or Ingress gateway is missing"
  exit 1
fi
echo "✅ gateway pods and Ingress exist"

names=$(k get svc gateway -o jsonpath='{range .spec.ports[*]}{.name}{" "}{end}' 2>/dev/null)
if echo "$names" | grep -qw http && echo "$names" | grep -qw metrics; then
  echo "✅ Service gateway still has ports http and metrics"
else
  echo "❌ Service gateway ports are [${names}], expected both http and metrics"
  exit 1
fi

body=$(k exec probe -- curl -s --max-time 5 -H 'Host: gateway.k8sm.local' "$CTRL/" 2>/dev/null)
if [ "$body" != "gateway: ok" ]; then
  echo "❌ through the Ingress, / returned '${body:-no answer}'"
  exit 1
fi
echo "✅ the Ingress serves the gateway page"

m=$(k exec probe -- curl -s --max-time 4 http://gateway:9090/metrics 2>/dev/null)
case "$m" in
  requests_total*) echo "✅ gateway:9090/metrics returns metrics" ;;
  *) echo "❌ gateway:9090/metrics returned '${m:-no answer}'"; exit 1 ;;
esac
exit 0
exit 1
