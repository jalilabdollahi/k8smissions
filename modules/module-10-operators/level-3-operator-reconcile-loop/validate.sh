#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy webapp-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ webapp-operator has no Ready pod"
  exit 1
fi
echo "✅ webapp-operator is running"

owned() {  # owned <kind> <name> <webapp>: is <kind>/<name> owned by the live WebApp <webapp>?
  local uid ouid
  uid=$(k get webapp "$3" -o jsonpath='{.metadata.uid}' 2>/dev/null)
  ouid=$(k get "$1" "$2" -o jsonpath='{.metadata.ownerReferences[?(@.kind=="WebApp")].uid}' 2>/dev/null)
  [ -n "$uid" ] && [ "$uid" = "$ouid" ]
}

bad=0
for site in site-a site-b; do
  phase=$(k get webapp "$site" -o jsonpath='{.status.phase}' 2>/dev/null)
  if [ "$phase" != "Ready" ]; then
    echo "❌ WebApp $site is '${phase:-missing}', not Ready"
    bad=1
    continue
  fi
  if ! owned deployment "$site" "$site" || ! owned service "$site" "$site"; then
    echo "❌ WebApp $site is Ready but its Deployment or Service is missing or not owned by it"
    bad=1
  fi
done
[ "$bad" = 0 ] || exit 1
echo "✅ site-a and site-b are Ready with owned Deployments and Services"

# a new WebApp must be picked up too
k delete webapp probe-web --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null <<'Y'
apiVersion: apps.acme.io/v1
kind: WebApp
metadata: {name: probe-web}
spec: {image: "nginx:1.27-alpine", replicas: 1}
Y
seen=0
for i in $(seq 1 10); do
  if k get deploy probe-web >/dev/null 2>&1 && k get svc probe-web >/dev/null 2>&1; then seen=1; break; fi
  sleep 2
done
phase=""
if [ "$seen" = 1 ]; then
  for i in $(seq 1 20); do
    phase=$(k get webapp probe-web -o jsonpath='{.status.phase}' 2>/dev/null)
    [ "$phase" = Ready ] && break
    sleep 2
  done
fi
k delete webapp probe-web --ignore-not-found --wait=false >/dev/null 2>&1
if [ "$seen" != 1 ]; then
  echo "❌ a new WebApp got no Deployment and Service within 20 seconds"
  exit 1
fi
if [ "$phase" != "Ready" ]; then
  echo "❌ a new WebApp got its objects but never reached Ready (phase '${phase:-empty}')"
  exit 1
fi
echo "✅ a new WebApp is reconciled and Ready"
exit 0
exit 1
