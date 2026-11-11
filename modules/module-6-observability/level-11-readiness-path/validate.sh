#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

st=$(k get deploy docs-site -o jsonpath='{.spec.replicas}/{.status.replicas}/{.status.updatedReplicas}/{.status.readyReplicas}/{.metadata.generation}/{.status.observedGeneration}' 2>/dev/null)
IFS=/ read -r want have upd ready gen obs <<<"$st"
if [ "$want" != "3" ] || [ "${have:-0}" != "3" ] || [ "${upd:-0}" != "3" ] || [ "${ready:-0}" != "3" ] || [ "$gen" != "$obs" ]; then
  echo "❌ rollout not complete: replicas ${have:-0}, updated ${upd:-0}, ready ${ready:-0} of 3"
  exit 1
fi
echo "✅ the rollout is complete: 3 updated pods, all Ready"

pods=$(../_fixtures/live-pods.sh app=docs-site)
path=$(k get deploy docs-site -o jsonpath='{.spec.template.spec.containers[0].readinessProbe.httpGet.path}' 2>/dev/null)
if [ -z "$path" ]; then
  echo "❌ the readiness probe must stay an HTTP check"
  exit 1
fi
../_fixtures/ensure-probe.sh
for p in $pods; do
  ip=$(k get pod "$p" -o jsonpath='{.status.podIP}')
  code=$(k exec probe -- curl -s -o /dev/null -w '%{http_code}' --max-time 4 "http://$ip:8080$path" 2>/dev/null)
  if [ "$code" != "200" ]; then
    echo "❌ the readiness probe path $path answers $code on $p, not 200"
    exit 1
  fi
done
echo "✅ the readiness probe hits a real 200 on every pod"

n=0
for i in $(seq 1 9); do
  out=$(k exec probe -- curl -s --max-time 4 http://docs-site/ 2>/dev/null)
  case "$out" in "docs-site 2.0"*) n=$((n + 1)) ;; esac
done
if [ "$n" -ne 9 ]; then
  echo "❌ only $n of 9 requests through Service docs-site returned the 2.0 content"
  exit 1
fi
echo "✅ Service docs-site serves the 2.0 content from every endpoint"
exit 0
exit 1
