**Fix**

1. `kubectl -n k8smissions get networkpolicy` shows three policies; two of them select `payments-db`.
2. `payments-db-from-api` admits only `payments-api`, but `allow-ns-ingress` admits `podSelector: {}`, i.e. every pod in the namespace. Allow rules union, so the loose one wins.
3. `kubectl -n k8smissions delete networkpolicy allow-ns-ingress`.
4. `default-deny-ingress` and `payments-db-from-api` stay: `payments-api` keeps its access, everyone else is dropped.
