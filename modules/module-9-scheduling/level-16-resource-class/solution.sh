kubectl -n k8smissions describe pod -l app=lab-notebook | tail -5
kubectl get resourceslice -o yaml | grep -E 'driver|nodeName|name:|string'
kubectl apply -f - <<'YAML'
apiVersion: resource.k8s.io/v1
kind: DeviceClass
metadata:
  name: gpu.example.com
spec:
  selectors:
  - cel:
      expression: 'device.driver == "gpu.lab.example.net"'
YAML
sleep 5
kubectl -n k8smissions describe pod -l app=lab-notebook | tail -4
kubectl -n k8smissions get resourceclaimtemplate notebook-gpu -o json \
  | sed 's/gpu.lab.example.com/gpu.lab.example.net/' \
  | jq 'del(.metadata.resourceVersion,.metadata.uid,.metadata.creationTimestamp,.metadata.generation)' \
  | kubectl replace --force -f -
kubectl -n k8smissions delete pod -l app=lab-notebook
sleep 10
kubectl -n k8smissions get pod -l app=lab-notebook -o wide
kubectl -n k8smissions get resourceclaim
