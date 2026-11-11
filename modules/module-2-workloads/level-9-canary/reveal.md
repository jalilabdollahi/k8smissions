1. `kubectl -n k8smissions get endpoints app` lists four pod IPs: two stable, two canary. Service `app` selects `app=app`, which both Deployments carry.
2. A Service balances per pod, so two canary pods out of four is roughly 50%.
3. Change the ratio: `kubectl -n k8smissions scale deployment app-stable --replicas=9` and `kubectl -n k8smissions scale deployment app-canary --replicas=1` gives about 10%.
4. `kubectl -n k8smissions get endpoints app` now shows ten addresses; one belongs to the canary.
