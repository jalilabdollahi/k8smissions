kubectl -n k8smissions get networkpolicy
kubectl -n k8smissions get networkpolicy -o yaml | grep -B3 -A12 "podSelector: {}"
kubectl -n k8smissions delete networkpolicy allow-ns-ingress
