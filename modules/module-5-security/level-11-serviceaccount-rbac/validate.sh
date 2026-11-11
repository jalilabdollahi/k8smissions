#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
can() { kubectl auth can-i "$@" 2>/dev/null; }
FR="--as=system:serviceaccount:$NS:flags-reader"
DEF="--as=system:serviceaccount:$NS:default"

# 1. identity: the workload runs as flags-reader
sa=$(k get deploy feature-flags -o jsonpath='{.spec.template.spec.serviceAccountName}' 2>/dev/null)
if [ "$sa" != "flags-reader" ]; then
  echo "❌ feature-flags runs as ServiceAccount '${sa:-default}', not flags-reader"
  exit 1
fi
echo "✅ feature-flags is configured to run as flags-reader"

# 2. permissions: allowed
if [ "$(can get configmap/flags -n "$NS" $FR)" != "yes" ]; then
  echo "❌ flags-reader cannot read ConfigMap flags"
  exit 1
fi
# 3. permissions: forbidden
for no in "get secrets" "list secrets" "create pods" "delete configmaps" "update configmaps"; do
  if [ "$(can $no -n "$NS" $FR)" = "yes" ]; then
    echo "❌ flags-reader is too powerful: it can $no"
    exit 1
  fi
done
if [ "$(can get secrets -n kube-system $FR)" = "yes" ] || [ "$(can get configmaps -n kube-system $FR)" = "yes" ]; then
  echo "❌ flags-reader reaches other namespaces"
  exit 1
fi
for what in "get configmap/flags" "list configmaps" "get secrets"; do
  if [ "$(can $what -n "$NS" $DEF)" = "yes" ]; then
    echo "❌ the default ServiceAccount can $what; access must belong to flags-reader only"
    exit 1
  fi
done
echo "✅ flags-reader reads the flags and nothing sensitive; default has no access"

# 4. behaviour: token mounted, running, no restarts, values come from the API
if ! k wait --for=condition=Available deploy/feature-flags --timeout=45s >/dev/null 2>&1; then
  echo "❌ feature-flags is not Available"
  k logs deploy/feature-flags --tail=2 2>&1 | sed 's/^/   /'
  exit 1
fi
pod=$(k get pods -l app=feature-flags --field-selector=status.phase=Running -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
[ -n "$pod" ] || { echo "❌ no running feature-flags pod"; exit 1; }
r1=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
sleep 7
r2=$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].restartCount}')
if [ "$r1" != "$r2" ] || [ "$(k get pod "$pod" -o jsonpath='{.status.containerStatuses[0].ready}')" != "true" ]; then
  echo "❌ feature-flags is restarting or not Ready"
  exit 1
fi
if [ "$(k get pod "$pod" -o jsonpath='{.spec.serviceAccountName}')" != "flags-reader" ]; then
  echo "❌ the running pod is not using flags-reader yet"
  exit 1
fi
if ! k logs "$pod" --tail=3 2>/dev/null | grep -q "flags: .*checkout_v2=on"; then
  echo "❌ feature-flags is not logging the flag values it reads"
  exit 1
fi
echo "✅ feature-flags is Running as flags-reader and logs the flags read via the API"
exit 0
exit 1
