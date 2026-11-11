**Starting at the Ingress.** It was the last change, so it looks guilty, but with no pods behind the Service there is nothing to route to; correcting the port first changes nothing visible. Start from the empty ReplicaSet.

**Deleting the PVC before the Job.** The claim is protected while a pod references it, so `kubectl delete pvc` hangs in `Terminating`. Remove the migration Job (and its pod) first. Also do not just delete the PVC and forget to re-create it: the web pods and the migration need it.

**Re-running the migration with a schema that merely works.** `--schema=v6` is accepted by the script and the Job completes, but the web pods wait for v7 and never start. Read what the init container is waiting for.
