1. `kubectl describe pod` Events: `manifest for nginx:1.27-alpne not found`; the tag has a typo.
2. `kubectl get deploy -o wide` shows `storefront-canary` using `nginx:1.27-alpine`.
3. `kubectl set image deployment/storefront web=nginx:1.27-alpine` corrects the template; the rollout replaces the stuck pods.
