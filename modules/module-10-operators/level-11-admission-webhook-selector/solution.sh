kubectl -n labeler-system describe rs | grep -i -A2 webhook | head
kubectl get mutatingwebhookconfiguration pod-labeler -o jsonpath='{.webhooks[0].namespaceSelector}{"\n"}'
kubectl patch mutatingwebhookconfiguration pod-labeler --type=json -p '[{"op":"add","path":"/webhooks/0/namespaceSelector/matchExpressions","value":[{"key":"kubernetes.io/metadata.name","operator":"NotIn","values":["labeler-system"]}]}]'
kubectl -n labeler-system rollout restart deploy/pod-labeler
kubectl -n labeler-system rollout status deploy/pod-labeler --timeout=90s
kubectl -n shop rollout restart deploy/storefront
