kubectl -n k8smissions describe pod cache-warm | tail -5
kubectl get nodes --show-labels
kubectl -n k8smissions get pod cache-warm -o yaml > /tmp/cache-warm.yaml
sed -i.bak 's/disktype: ssd/disk: ssd/' /tmp/cache-warm.yaml
kubectl -n k8smissions delete pod cache-warm
kubectl apply -f /tmp/cache-warm.yaml
kubectl -n k8smissions wait --for=condition=Ready pod/cache-warm --timeout=50s
