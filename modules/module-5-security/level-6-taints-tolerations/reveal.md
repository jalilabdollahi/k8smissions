**Fix**

1. `kubectl -n k8smissions describe pod -l app=etl-runner` shows `FailedScheduling ... untolerated taint {dedicated: etl}`.
2. The node has two taints: `dedicated=etl:NoSchedule` and `team=data:NoSchedule`. The event message names only one of them.
3. Add both tolerations to the pod template:
   `kubectl -n k8smissions patch deployment etl-runner -p '{"spec":{"template":{"spec":{"tolerations":[{"key":"dedicated","operator":"Equal","value":"etl","effect":"NoSchedule"},{"key":"team","operator":"Equal","value":"data","effect":"NoSchedule"}]}}}}'`
4. The pods schedule onto the pool. `web-frontend` has no tolerations, so it stays on the other worker.
