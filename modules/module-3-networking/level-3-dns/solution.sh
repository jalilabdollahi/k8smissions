kubectl -n k8smissions exec deploy/reporter -- cat /etc/resolv.conf
kubectl -n k8smissions patch deployment reporter --type=json -p '[{"op":"remove","path":"/spec/template/spec/dnsConfig"},{"op":"replace","path":"/spec/template/spec/dnsPolicy","value":"ClusterFirst"}]'
kubectl -n k8smissions rollout status deployment/reporter --timeout=120s
