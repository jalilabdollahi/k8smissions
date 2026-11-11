kubectl -n k8smissions describe pod -l app=ledger-batch | tail -8
kubectl -n k8smissions get pod -l app=ledger-batch -o jsonpath='{.items[0].spec.overhead}{"\n"}'
kubectl get runtimeclass sandboxed -o jsonpath='{.overhead}{"\n"}'
kubectl -n k8smissions get configmap ledger-batch-sizing -o jsonpath='{.data}{"\n"}'
kubectl -n k8smissions set resources deploy/ledger-batch --requests=memory=400Mi
kubectl -n k8smissions rollout status deploy/ledger-batch --timeout=120s
kubectl -n k8smissions get pod -l app=ledger-batch -o wide
