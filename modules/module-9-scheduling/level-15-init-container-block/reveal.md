1. `describe pod` says `Insufficient memory`; each worker has about 1000Mi unreserved. The app container asks 100Mi, so something else is large: the init container `db-migrate` requests 1500Mi.
2. Effective pod request = max(largest init request, sum of app requests) = 1500Mi, which fits nowhere.
3. The migration needs about 600Mi. Lower the init request below the free memory and keep its limit above 600Mi:
   `kubectl -n k8smissions patch deploy payments-migrator --type=json -p '[{"op":"replace","path":"/spec/template/spec/initContainers/0/resources/requests/memory","value":"700Mi"}]'`
