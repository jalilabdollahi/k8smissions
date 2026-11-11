kubectl -n k8smissions describe pod -l app=video-transcode | grep -A3 Events
kubectl get nodes -o custom-columns='NODE:.metadata.name,FPGAS:.status.allocatable.example\.com/fpgas'
kubectl -n k8smissions patch deploy video-transcode --type=json -p '[
 {"op":"remove","path":"/spec/template/spec/containers/0/resources/requests/example.com~1fpga"},
 {"op":"remove","path":"/spec/template/spec/containers/0/resources/limits/example.com~1fpga"},
 {"op":"add","path":"/spec/template/spec/containers/0/resources/requests/example.com~1fpgas","value":"1"},
 {"op":"add","path":"/spec/template/spec/containers/0/resources/limits/example.com~1fpgas","value":"1"}]'
sleep 10
kubectl -n k8smissions get pods -o wide
kubectl get pods -A -o custom-columns='NS:.metadata.namespace,POD:.metadata.name,FPGA:.spec.containers[*].resources.requests.example\.com/fpgas' | grep -v '<none>'
kubectl -n k8smissions delete pod fpga-smoketest
kubectl -n k8smissions rollout status deploy/video-transcode --timeout=120s
kubectl -n k8smissions get pods -o wide
