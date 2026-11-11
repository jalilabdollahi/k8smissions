#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# the nodes themselves must still be healthy: the cause is not node pressure
bad=$(kubectl get nodes -o jsonpath='{range .items[*].status.conditions[?(@.status=="True")]}{.type}{"\n"}{end}' | grep -E 'MemoryPressure|DiskPressure|PIDPressure')
if [ -n "$bad" ]; then
  echo "❌ a node reports pressure ($bad); this level must be fixed without stressing nodes"
  exit 1
fi

limit=$(k get deploy audit-spooler -o jsonpath='{.spec.template.spec.volumes[?(@.name=="spool")].emptyDir.sizeLimit}' 2>/dev/null)
limit_ki=$(python3 - "$limit" <<'PY'
import re, sys
m = re.fullmatch(r"(\d+)(Ki|Mi|Gi)", sys.argv[1])
print(int(m.group(1)) * {"Ki": 1, "Mi": 1024, "Gi": 1048576}[m.group(2)] if m else 0)
PY
)
if [ "${limit_ki:-0}" -le 0 ] || [ "$limit_ki" -gt 102400 ]; then
  echo "❌ the spool volume must keep a size limit of at most 100Mi (found: ${limit:-none})"
  exit 1
fi
echo "✅ the spool volume still has a size limit ($limit)"

replicas=$(k get deploy audit-spooler -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "$replicas" != "2" ]; then
  echo "❌ audit-spooler must keep 2 replicas"
  exit 1
fi

age=$(../_fixtures/min-age.sh app=audit-spooler)
if [ "${age:-0}" -lt 45 ]; then
  wait=$(( 45 - ${age:-0} ))
  echo "… pods are ${age:-0}s old, watching them for another ${wait}s"
  sleep "$wait"
fi

running=""
for p in $(../_fixtures/live-pods.sh app=audit-spooler); do
  running="$running$p=$(k get pod "$p" -o jsonpath='{.status.containerStatuses[0].ready}/{.status.containerStatuses[0].restartCount}')"$'\n'
done
running=$(echo "$running" | sed '/^$/d')
if [ "$(echo "$running" | grep -c '=true/0$')" -ne 2 ] || [ "$(echo "$running" | grep -c .)" -ne 2 ]; then
  echo "❌ audit-spooler needs exactly 2 Running pods with no restarts:"
  echo "$running"
  exit 1
fi
echo "✅ 2 pods are Running and stable"

oldest=$(k get pods -l app=audit-spooler --field-selector=status.phase=Running -o jsonpath='{range .items[*]}{.metadata.creationTimestamp}{"\n"}{end}' | sort | head -1)
fresh=$(k get pods -l app=audit-spooler --field-selector=status.phase=Failed -o jsonpath='{range .items[?(@.status.reason=="Evicted")]}{.metadata.creationTimestamp}{"\n"}{end}' | awk -v o="$oldest" '$0 > o' | wc -l | tr -d ' ')
if [ "$fresh" -ne 0 ]; then
  echo "❌ pods were evicted after the current ones started ($fresh)"
  exit 1
fi
echo "✅ no new evictions"

for p in $(echo "$running" | cut -d= -f1); do
  used=$(k exec "$p" -- du -sk /spool 2>/dev/null | cut -f1)
  if [ -z "$used" ] || [ "$used" -ge "$limit_ki" ]; then
    echo "❌ $p: the spool holds ${used:-?} KiB, at or over the ${limit_ki} KiB limit"
    exit 1
  fi
done
echo "✅ the spool directory stays under the volume limit"
exit 0
exit 1
