kubectl -n k8smissions describe pod -l app=settlement-gateway | grep -A12 Events
kubectl -n k8smissions patch deploy settlement-gateway --type=json -p='[
 {"op":"replace","path":"/spec/template/spec/containers/0/livenessProbe","value":{"tcpSocket":{"port":7000},"initialDelaySeconds":5,"periodSeconds":5,"failureThreshold":3}},
 {"op":"replace","path":"/spec/template/spec/containers/0/readinessProbe","value":{"tcpSocket":{"port":7000},"periodSeconds":5}},
 {"op":"replace","path":"/spec/template/spec/containers/1/livenessProbe","value":{"exec":{"command":["sh","-c","test $(( $(date +%s) - $(cat /tmp/heartbeat) )) -lt 20"]},"initialDelaySeconds":8,"periodSeconds":5,"failureThreshold":3}},
 {"op":"replace","path":"/spec/template/spec/containers/1/readinessProbe","value":{"exec":{"command":["sh","-c","test $(( $(date +%s) - $(cat /tmp/heartbeat) )) -lt 20"]},"initialDelaySeconds":8,"periodSeconds":5}}
]'
kubectl -n k8smissions rollout status deploy/settlement-gateway --timeout=100s
