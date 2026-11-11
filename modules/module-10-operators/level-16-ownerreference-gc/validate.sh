#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
S=sites.web.acme.io

ready=$(k get deploy site-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ site-operator has no ready pod"
  exit 1
fi
if k get svc site-legacy >/dev/null 2>&1; then
  echo "❌ the orphaned Service site-legacy is still there"
  exit 1
fi
echo "✅ site-operator is running and the orphan site-legacy is gone"

uids() { # uids <site>: UIDs of the three children, 'none' for a missing one
  local n=site-$1 d s c
  d=$(k get deploy $n -o jsonpath='{.metadata.uid}' 2>/dev/null)
  s=$(k get svc $n -o jsonpath='{.metadata.uid}' 2>/dev/null)
  c=$(k get cm $n -o jsonpath='{.metadata.uid}' 2>/dev/null)
  echo "${d:-none} ${s:-none} ${c:-none}"
}
complete() { ! echo "$1" | grep -q none; }
wait_children() { # wait_children <site> <seconds>
  local i r
  for i in $(seq 1 "$2"); do
    r=$(uids "$1")
    complete "$r" && { echo "$r"; return 0; }
    sleep 1
  done
  echo "$r"; return 1
}
owners_ok() { # owners_ok <site>: deployment, configmap and service all point at the live Site
  local su n=site-$1 res=0 kind
  su=$(k get $S "$1" -o jsonpath='{.metadata.uid}' 2>/dev/null)
  [ -n "$su" ] || return 1
  for kind in deploy svc cm; do
    [ "$(k get $kind $n -o jsonpath='{.metadata.ownerReferences[0].uid}' 2>/dev/null)" = "$su" ] || res=1
  done
  return $res
}

# the live Sites
for s in storefront blog; do
  ok=0
  for i in $(seq 1 25); do
    r=$(uids $s)
    if complete "$r" && [ "$(k get deploy site-$s -o jsonpath='{.metadata.ownerReferences[0].uid}' 2>/dev/null)" = "$(k get $S $s -o jsonpath='{.metadata.uid}')" ] \
       && [ "$(k get cm site-$s -o jsonpath='{.metadata.ownerReferences[0].uid}' 2>/dev/null)" = "$(k get $S $s -o jsonpath='{.metadata.uid}')" ]; then ok=1; break; fi
    sleep 1
  done
  if [ "$ok" != 1 ]; then
    echo "❌ live Site $s does not have a complete, correctly owned set of children (deploy/svc/cm uids: $r)"
    exit 1
  fi
done
echo "✅ the live Sites have their children, owned by the real Site"

k delete $S probe --ignore-not-found --wait=true >/dev/null 2>&1
mk() { k apply -f - >/dev/null 2>&1 <<'Y'
apiVersion: web.acme.io/v1
kind: Site
metadata: {name: probe}
spec: {host: probe.acme.io}
Y
}

mk
first=$(wait_children probe 20) || { echo "❌ a new Site did not get its Deployment, Service and ConfigMap (deploy/svc/cm: $first)"; k delete $S probe --ignore-not-found >/dev/null 2>&1; exit 1; }
sleep 8
again=$(uids probe)
if [ "$first" != "$again" ]; then
  echo "❌ the children of a new Site do not stay: uids were [$first] and 8 seconds later [$again] ('none' = deleted)"
  k delete $S probe --ignore-not-found >/dev/null 2>&1
  exit 1
fi
if ! owners_ok probe; then
  echo "❌ a child of the new Site does not name the Site (by its real uid) as its owner"
  k delete $S probe --ignore-not-found >/dev/null 2>&1
  exit 1
fi
echo "✅ a new Site's children stay and are owned by it"

k delete $S probe --wait=false >/dev/null 2>&1
gone=0
for i in $(seq 1 30); do
  if [ "$(uids probe)" = "none none none" ]; then gone=1; break; fi
  sleep 1
done
if [ "$gone" != 1 ]; then
  echo "❌ after deleting Site probe, its children are still there: [$(uids probe)]"
  exit 1
fi
echo "✅ deleting a Site removes all three children"

mk
first=$(wait_children probe 20) || { echo "❌ recreating Site probe did not bring its children back (deploy/svc/cm: $first)"; k delete $S probe --ignore-not-found >/dev/null 2>&1; exit 1; }
sleep 8
again=$(uids probe)
k delete $S probe --ignore-not-found --wait=false >/dev/null 2>&1
if [ "$first" != "$again" ]; then
  echo "❌ after recreating Site probe its children vanished or were replaced: [$first] then [$again]"
  exit 1
fi
echo "✅ recreating a Site of the same name keeps its children"
exit 0
exit 1
