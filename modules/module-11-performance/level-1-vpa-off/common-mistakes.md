**Sizing from the first `kubectl top`.** Right after a start the pod uses about 20Mi, so a limit of 64Mi or 128Mi looks generous. The index loads later. Wait until the pod has been through its load (or read the cgroup file after Ready) before choosing a number.

**Setting request and limit to 1Gi "to be safe".** The pods stop dying, but three replicas ask for 3Gi against a 1Gi request quota. The Deployment sits at 2 of 3 and `kubectl describe rs search-indexer` shows `exceeded quota`. Pick a request close to the observed use.

**Raising only the limit and leaving the request at 128Mi.** The pod survives, but the scheduler thinks it uses 128Mi when it really uses about 190Mi. That is the kind of lie that makes nodes overcommit and evict neighbours. The request should reflect real use.

**Raising the quota.** The quota is the team's budget, not the fault. The objective is to fit inside it.
