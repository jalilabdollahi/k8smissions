**Why it is slow.** `maxSurge: 0, maxUnavailable: 1` replaces one pod per wave, and every wave waits for container start, a 4s readiness `initialDelaySeconds` and `minReadySeconds: 4`: about 10 seconds a pod, 40 pods in several minutes.

**The fix.** Replace many pods per wave and shorten the wave. The availability floor (30 of 40) means `maxUnavailable` must stay at or below 25%; the extra capacity comes from surge pods:

    kubectl patch deployment image-resizer -n k8smissions --type=merge \
      -p '{"spec":{"minReadySeconds":2,"strategy":{"rollingUpdate":{"maxSurge":"50%","maxUnavailable":"20%"}}}}'

Changing only the surge still leaves about a dozen waves; changing only the waits still leaves 40 waves.
