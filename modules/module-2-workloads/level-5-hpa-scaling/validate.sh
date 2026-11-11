#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get deploy web-backend >/dev/null 2>&1; then
  echo "❌ Deployment web-backend does not exist"
  exit 1
fi
if ! k get hpa web-backend >/dev/null 2>&1; then
  echo "❌ HPA web-backend does not exist"
  exit 1
fi
tgt=$(k get hpa web-backend -o jsonpath='{.spec.scaleTargetRef.kind}/{.spec.scaleTargetRef.name}')
if [ "$tgt" != "Deployment/web-backend" ]; then
  echo "❌ the HPA targets $tgt instead of Deployment/web-backend"
  exit 1
fi

if ! kubectl -n kube-system get deploy metrics-server >/dev/null 2>&1; then
  echo "❌ metrics-server is gone from kube-system"
  exit 1
fi

util=$(k get hpa web-backend -o jsonpath='{.status.currentMetrics[0].resource.current.averageUtilization}')
if [ -z "$util" ]; then
  echo "❌ HPA web-backend still cannot read a CPU utilisation (<unknown>)"
  exit 1
fi
echo "✅ HPA reads a CPU utilisation of ${util}%"

active=$(k get hpa web-backend -o jsonpath='{.status.conditions[?(@.type=="ScalingActive")].status}')
if [ "$active" != "True" ]; then
  echo "❌ HPA web-backend is not able to scale (ScalingActive=$active)"
  exit 1
fi
echo "✅ HPA is able to scale"

desired=$(k get hpa web-backend -o jsonpath='{.status.desiredReplicas}')
if [ "${desired:-0}" -lt 2 ]; then
  echo "❌ HPA wants ${desired:-0} replica(s) although the pod is busy"
  exit 1
fi
echo "✅ HPA scales web-backend to $desired replicas"
exit 0
exit 1
