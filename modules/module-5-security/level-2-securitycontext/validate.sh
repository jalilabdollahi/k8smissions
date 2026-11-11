#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get svc status-page >/dev/null 2>&1; then
  echo "❌ Service status-page is missing"
  exit 1
fi

# policy: every container keeps readOnlyRootFilesystem, privileged is not used
ro=$(k get deploy status-page -o jsonpath='{range .spec.template.spec.containers[*]}{.securityContext.readOnlyRootFilesystem}{" "}{end}' 2>/dev/null)
priv=$(k get deploy status-page -o jsonpath='{range .spec.template.spec.containers[*]}{.securityContext.privileged}{" "}{end}' 2>/dev/null)
ro=$(echo $ro)
n=$(k get deploy status-page -o jsonpath='{.spec.template.spec.containers[*].name}' | wc -w)
trues=$(echo "$ro" | grep -o true | wc -l)
if [ "$n" -eq 0 ] || [ "$trues" -ne "$n" ]; then
  echo "❌ every container must keep readOnlyRootFilesystem: true"
  exit 1
fi
if echo "$priv" | grep -q true; then
  echo "❌ privileged containers are not allowed"
  exit 1
fi
echo "✅ readOnlyRootFilesystem is still enforced in the spec"

if [ "$(k get deploy status-page -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "2" ]; then
  echo "❌ status-page must keep 2 replicas"
  exit 1
fi
if ! k rollout status deploy/status-page --timeout=45s >/dev/null 2>&1; then
  echo "❌ status-page: $(k get deploy status-page -o jsonpath='{.status.readyReplicas}')/2 pods Ready"
  exit 1
fi
echo "✅ 2 of 2 status-page pods Ready"

r1=$(k get pods -l app=status-page -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{" "}{end}')
sleep 12
r2=$(k get pods -l app=status-page -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{" "}{end}')
if [ "$r1" != "$r2" ]; then
  echo "❌ status-page pods are still restarting"
  exit 1
fi

bad=0
for i in 1 2 3 4 5 6; do
  code=$(k exec probe -- curl -s -o /dev/null -w '%{http_code}' --max-time 3 http://status-page 2>/dev/null)
  [ "$code" = 200 ] || bad=$((bad+1))
done
if [ "$bad" -ne 0 ]; then
  echo "❌ Service status-page: $bad of 6 requests did not return 200"
  exit 1
fi
echo "✅ Service status-page answers 200 on 6 of 6 requests"

# behaviour: the root filesystem is really read-only, the dedicated mounts are writable
pod=$(k get pods -l app=status-page -o jsonpath='{.items[0].metadata.name}')
if k exec "$pod" -c nginx -- touch /probe-root >/dev/null 2>&1; then
  k exec "$pod" -c nginx -- rm -f /probe-root >/dev/null 2>&1
  echo "❌ the root filesystem is writable in $pod"
  exit 1
fi
for d in /var/cache/nginx /var/run; do
  if ! k exec "$pod" -c nginx -- sh -c "touch $d/.w && rm $d/.w" >/dev/null 2>&1; then
    echo "❌ nginx cannot write to $d"
    exit 1
  fi
done
echo "✅ root filesystem is read-only; nginx writes only to its own mounts"
exit 0
exit 1
