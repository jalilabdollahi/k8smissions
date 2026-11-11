**Stopping after the first improvement.** Fixing the CPU limit (the loudest fault) takes the page from timeouts to slow, and it feels done. The validator checks each layer separately, and the goal of 300ms at 30 requests per second is only met with all three fixed.

**Scaling pricing up.** More replicas do nothing while the Service pins the single client to one pod, and each new pod keeps the same 100m limit. Capacity per pod and routing are the problem, not the count.

**Setting search domains to empty to cut DNS queries.** It removes short-name resolution for everything else in the pod, and it treats the symptom of one name; the simple fix here is on that name or on `ndots`.
