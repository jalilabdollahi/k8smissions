**Asking for more quota or editing it.** The objective forbids it and the validator checks the hard limit; it also hides the real problem, which is requests several times larger than usage.

**Deleting `batch-reprocess`.** It frees the quota, but the workload belongs to another team. Scaling a stranger's deployment to zero is a conversation, not a fix; and the next surge still sits on a narrow margin. Prefer a change within your own Deployment.

**Dropping the CPU request entirely.** The surge pod then needs 0m and the rollout runs, but the pods lose their reservation and, with the quota in place, new pods in the namespace without a request are rejected outright. Keep a request close to real use instead.
