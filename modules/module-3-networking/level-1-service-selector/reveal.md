The Service selector is only `app: cart`. Both the `cart` pods (`tier=web`) and the leftover `cart-loadtest` pod (`tier=load`) carry that label, so the Service balances across four pods and one of them answers "load-test OK".

1. `kubectl -n k8smissions get pods --show-labels` shows which pod has `tier=load`.
2. `kubectl -n k8smissions patch service cart -p '{"spec":{"selector":{"app":"cart","tier":"web"}}}'` narrows the selector to the storefront pods.
3. Deleting the `cart-loadtest` Deployment also works; the Service would then only see the three web pods.
