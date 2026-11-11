kubectl -n k8smissions logs deploy/datastore-operator --tail=5
kubectl -n k8smissions get cm datastore-operator-code -o jsonpath='{.data.controller\.py}' > controller.py
# clean up first, release the finalizer last
sed -e '/release(ds) /{h;d;}' -e '/cleanup(name) /{G;}' controller.py > fixed.py
kubectl -n k8smissions create configmap datastore-operator-code --from-file=controller.py=fixed.py --dry-run=client -o yaml | kubectl apply -f -
kubectl -n k8smissions rollout restart deployment/datastore-operator
kubectl -n k8smissions rollout status deployment/datastore-operator --timeout=90s
# the earlier leak is not repaired by the code fix
kubectl -n k8smissions delete pod/ds-legacy-orders configmap/ds-legacy-orders
