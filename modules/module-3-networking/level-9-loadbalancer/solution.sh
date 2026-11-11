kubectl -n k8smissions get svc storefront-lb
kubectl -n k8smissions describe svc storefront-lb
kubectl -n k8smissions patch svc storefront-lb -p '{"spec":{"type":"NodePort","loadBalancerClass":null,"allocateLoadBalancerNodePorts":null}}'
kubectl -n k8smissions get svc storefront-lb
