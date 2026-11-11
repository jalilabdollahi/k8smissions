#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get sts quorum -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ StatefulSet quorum: ${ready:-0} of 3 pods Ready"
  exit 1
fi
echo "✅ quorum has 3 Ready pods"

probe=$(k get sts quorum -o jsonpath='{.spec.template.spec.containers[0].readinessProbe}' 2>/dev/null)
if [ -z "$probe" ]; then
  echo "❌ the readiness probe was removed from quorum; peers must be found for real"
  exit 1
fi
echo "✅ the readiness probe is still in place"

ips=$(k get pods -l app=quorum -o jsonpath='{.items[*].status.podIP}' 2>/dev/null)
n=$(echo $ips | wc -w | tr -d ' ')
if [ "$n" -ne 3 ]; then
  echo "❌ expected 3 quorum pod IPs, found $n"
  exit 1
fi

dns=$(k exec probe -- nslookup quorum 2>/dev/null)
for ip in $ips; do
  if ! echo "$dns" | grep -q "$ip"; then
    echo "❌ nslookup quorum does not return $ip"
    exit 1
  fi
done
echo "✅ nslookup quorum returns all 3 pod IPs"

for ip in $ips; do
  body=$(k exec probe -- curl -s --max-time 4 "http://$ip:8080/peers" 2>/dev/null)
  if [ "$body" != "peers: 3" ]; then
    echo "❌ $ip /peers says '${body:-no answer}', expected 'peers: 3'"
    exit 1
  fi
done
echo "✅ every pod sees 3 members"

sleep 8
restarts=$(k get pods -l app=quorum -o jsonpath='{range .items[*]}{.status.containerStatuses[0].restartCount}{"\n"}{end}' | awk '{s+=$1} END{print s+0}')
ready=$(k get sts quorum -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "$restarts" -ne 0 ] || [ "${ready:-0}" -ne 3 ]; then
  echo "❌ quorum is not stable: $restarts restarts, ${ready:-0} of 3 Ready"
  exit 1
fi
echo "✅ stable: no restarts, still 3 Ready"
exit 0
exit 1
