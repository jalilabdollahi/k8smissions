The mutating webhook `pod-labeler` matches pods in every lab namespace, `labeler-system` included. Its own server pod is in that namespace, so creating it calls the webhook, which has no endpoints because the server is not running: `failed calling webhook ... no endpoints available`. `failurePolicy: Fail` turns that into a refusal, so the server can never start. The same refusal blocks `shop`.

Exclude the server's namespace from the webhook, keeping the lab label match:

```bash
kubectl patch mutatingwebhookconfiguration pod-labeler --type=json -p '[{"op":"add","path":"/webhooks/0/namespaceSelector/matchExpressions","value":[{"key":"kubernetes.io/metadata.name","operator":"NotIn","values":["labeler-system"]}]}]'
```

Then restart the Deployments whose rollouts were stuck so they do not wait for their retry backoff:

```bash
kubectl -n labeler-system rollout restart deploy/pod-labeler
kubectl -n shop rollout restart deploy/storefront
```
