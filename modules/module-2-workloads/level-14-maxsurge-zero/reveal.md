1. `kubectl -n k8smissions describe pod <pending pod>` says `didn't have free ports for the requested pod ports`: both nodes already run a pod holding hostPort 9000.
2. The default strategy is `maxSurge: 25%` (rounds up to 1) and `maxUnavailable: 25%` (rounds down to 0), so the Deployment must start a third pod before it may stop an old one.
3. `kubectl -n k8smissions patch deployment api-server --type=merge -p '{"spec":{"strategy":{"rollingUpdate":{"maxSurge":0,"maxUnavailable":1}}}}'` lets the controller stop one old pod first, which frees the port for its replacement.
4. `kubectl -n k8smissions rollout status deployment/api-server` completes; one pod serves at all times.
