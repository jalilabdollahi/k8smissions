kubectl -n k8smissions get rs,pods --show-labels
kubectl -n k8smissions get rs -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].kind
rs=$(kubectl -n k8smissions get rs --no-headers -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].kind | awk '$2=="<none>"{print $1}')
kubectl -n k8smissions delete rs $rs
