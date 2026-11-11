kubectl -n k8smissions get pdb
kubectl -n k8smissions get pdb consul-pdb -o jsonpath='{.spec.selector}'
kubectl -n k8smissions get pods --show-labels
kubectl -n k8smissions patch pdb consul-pdb --type=merge -p '{"spec":{"selector":{"matchLabels":{"app.kubernetes.io/name":"consul"}}}}'
kubectl -n k8smissions get pdb
