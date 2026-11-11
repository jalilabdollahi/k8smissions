kubectl -n k8smissions logs job/crd-sync --tail=3
kubectl get crd configs.settings.acme.io -o jsonpath='{.status.storedVersions}{"\n"}'
# 1. make v1 the storage version, keeping both served
kubectl patch crd configs.settings.acme.io --type=json -p '[{"op":"replace","path":"/spec/versions/0/storage","value":false},{"op":"replace","path":"/spec/versions/1/storage","value":true}]'
# 2. rewrite every object so it is stored as v1
kubectl get configs.v1.settings.acme.io -A -o json | kubectl replace -f -
# 3. record that nothing is stored as v1alpha1 anymore
kubectl patch crd configs.settings.acme.io --subresource=status --type=merge -p '{"status":{"storedVersions":["v1"]}}'
# 4. the Job can now remove v1alpha1
kubectl -n k8smissions wait --for=condition=complete job/crd-sync --timeout=90s
kubectl get configs.settings.acme.io -A | head -5
