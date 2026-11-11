1. `describe pod`: one node "didn't match Pod's node affinity/selector" (the on-demand node, label `lifecycle=on-demand`) and the spot node has an untolerated taint `spot-reclaimed`.
2. Remove the `nodeSelector: lifecycle=spot` that pins the pods to the dead node, and add a toleration for the on-demand node's taint:
   `kubectl -n k8smissions patch deploy render-farm --type=json -p '[{"op":"remove","path":"/spec/template/spec/nodeSelector"},{"op":"add","path":"/spec/template/spec/tolerations","value":[{"key":"lifecycle","operator":"Equal","value":"on-demand","effect":"NoSchedule"}]}]'`
3. The four pods start on the on-demand node. Do not tolerate `spot-reclaimed`: the node is gone, and the pods would be stranded on it again.
