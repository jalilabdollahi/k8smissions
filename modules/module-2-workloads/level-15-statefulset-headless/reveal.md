1. `kubectl -n k8smissions get statefulset db -o jsonpath='{.spec.serviceName}'` prints `db-hs`, but `kubectl -n k8smissions get svc` only has `db`, a normal ClusterIP Service.
2. Per-pod DNS needs a headless Service named like `serviceName`. `serviceName` cannot be edited, and `clusterIP` of Service `db` cannot be changed (and clients need it as it is).
3. Create the missing Service: `kubectl -n k8smissions apply -f -` with `name: db-hs`, `clusterIP: None`, `selector: {app: db}` and port 8080.
4. `db-0.db-hs`, `db-1.db-hs` and `db-2.db-hs` now resolve, and `db-monitor` becomes Ready.
