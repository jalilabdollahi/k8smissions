1. `kubectl describe rs` shows `maximum memory limit to request ratio per Container is 2, but provided ratio is 8.000000`: the LimitRange `team-defaults` rejects pods with limit 512Mi over request 64Mi.
2. Lowering the limit to 128Mi would satisfy the ratio but a render needs about 360 MiB and would be OOMKilled.
3. Keep a limit of at least 400Mi and raise the request so limit/request is at most 2: `kubectl set resources deployment invoice-render --requests=memory=256Mi --limits=memory=512Mi`.
4. The Deployment creates its 3 pods; do not delete the LimitRange.
