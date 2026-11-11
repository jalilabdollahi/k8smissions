#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy edge-nginx >/dev/null 2>&1; then
  echo "❌ Deployment edge-nginx does not exist"
  exit 1
fi

# 1. policy: drop ALL kept, never privileged
drop=$(k get deploy edge-nginx -o jsonpath='{.spec.template.spec.containers[0].securityContext.capabilities.drop}')
priv=$(k get deploy edge-nginx -o jsonpath='{.spec.template.spec.containers[0].securityContext.privileged}')
if ! echo "$drop" | grep -q '"ALL"'; then
  echo "❌ the container no longer drops ALL capabilities"
  exit 1
fi
if [ "$priv" = "true" ]; then
  echo "❌ the container is privileged"
  exit 1
fi
echo "✅ drop: ALL is still in place and the container is not privileged"

# 2. behaviour
if ! k rollout status deploy/edge-nginx --timeout=50s >/dev/null 2>&1; then
  echo "❌ edge-nginx is not Ready"
  k logs deploy/edge-nginx --tail=2 2>&1 | sed 's/^/   /'
  exit 1
fi
pod=$(k get pods -l app=edge-nginx --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}')
r1=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
sleep 6
r2=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
if [ "$r1" != "$r2" ] || [ "$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  echo "❌ edge-nginx keeps restarting"
  exit 1
fi
code=$(k exec probe -- curl -s -o /dev/null -w '%{http_code}' --max-time 5 http://edge-nginx/ 2>/dev/null)
if [ "$code" != "200" ]; then
  echo "❌ Service edge-nginx answered HTTP '${code:-none}' instead of 200"
  exit 1
fi
echo "✅ Service edge-nginx answers 200 and the pod is stable"

# 3. the capabilities nginx really holds
eff=$(k exec "$pod" -- sh -c 'grep CapEff /proc/1/status' 2>/dev/null | awk '{print $2}')
if [ -z "$eff" ]; then
  echo "❌ could not read the capability set of the nginx process"
  exit 1
fi
mask=$((16#$eff))
if [ "$mask" -eq 0 ]; then
  echo "❌ the nginx process holds no capabilities at all; yet it works only if it has some?"
  exit 1
fi
# DAC_OVERRIDE 1, SYS_MODULE 16, SYS_RAWIO 17, SYS_PTRACE 19, SYS_ADMIN 21, NET_ADMIN 12, NET_RAW 13
for bit in 1 12 13 16 17 19 21; do
  if [ $(( (mask >> bit) & 1 )) -eq 1 ]; then
    echo "❌ nginx holds a dangerous capability (bit $bit, CapEff=$eff)"
    exit 1
  fi
done
echo "✅ nginx holds a small capability set (CapEff=$eff) without the dangerous ones"
exit 0
exit 1
