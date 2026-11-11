kubectl -n k8smissions get pods -l app=quorum
kubectl -n k8smissions exec probe -- nslookup quorum
kubectl -n k8smissions get endpointslices -l kubernetes.io/service-name=quorum -o yaml
kubectl -n k8smissions patch svc quorum -p '{"spec":{"publishNotReadyAddresses":true}}'
kubectl -n k8smissions rollout status sts/quorum --timeout=100s
