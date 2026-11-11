kubectl -n k8smissions get endpointslices -l kubernetes.io/service-name=cart
kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions patch service cart -p '{"spec":{"selector":{"app":"cart","tier":"web"}}}'
