#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

for d in image-cache session-store; do
  gen=$(k get deploy "$d" -o jsonpath='{.metadata.generation}' 2>/dev/null)
  rdy=$(k get deploy "$d" -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
  if [ "$gen" != "1" ] || [ "${rdy:-0}" != "1" ]; then
    echo "❌ Deployment $d was changed or is not Ready; it should be left alone"
    exit 1
  fi
done
echo "✅ the other Deployments are untouched"

ready=$(k get deploy thumbnailer -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
restarts=$(k get pods -l app=thumbnailer -o jsonpath='{range .items[*].status.containerStatuses[*]}{.restartCount}{"\n"}{end}' 2>/dev/null | sort -n | tail -1)
if [ "${ready:-0}" -ne 2 ] || [ "${restarts:-0}" -ne 0 ]; then
  echo "❌ thumbnailer: ${ready:-0} of 2 pods Ready, highest restart count ${restarts:-?}"
  exit 1
fi
echo "✅ thumbnailer has 2 Ready pods with no restarts"

pods=$(../_fixtures/live-pods.sh app=thumbnailer)
if [ "$(echo "$pods" | grep -c .)" -ne 2 ]; then
  echo "❌ expected 2 live thumbnailer pods, found $(echo "$pods" | grep -c .)"
  exit 1
fi
for p in $pods; do
  cap=$(k exec "$p" -c exporter -- sh -c 'cat /sys/fs/cgroup/cpu.max 2>/dev/null || echo "$(cat /sys/fs/cgroup/cpu/cpu.cfs_quota_us) $(cat /sys/fs/cgroup/cpu/cpu.cfs_period_us)"' 2>/dev/null)
  quota=${cap%% *}
  period=${cap##* }
  if [ -z "$quota" ] || [ "$quota" = "max" ] || [ "$quota" = "-1" ]; then
    echo "❌ $p: the exporter container still has no CPU limit in effect"
    exit 1
  fi
  pct=$(( quota * 100 / period ))
  if [ "$pct" -lt 5 ] || [ "$pct" -gt 80 ]; then
    echo "❌ $p: exporter is limited to ${pct}% of a CPU; it needs a cap between 5% and 80%"
    exit 1
  fi
done
echo "✅ every exporter container is capped by a CPU limit that is enforced"

for p in $pods; do
  if ! k exec "$p" -c app -- wget -q -T 3 -O- http://127.0.0.1/ 2>/dev/null | grep -qi 'welcome to nginx'; then
    echo "❌ $p: the thumbnail service container no longer answers"
    exit 1
  fi
done
echo "✅ the thumbnail service container still answers"
exit 0
exit 1
