## What was broken

The Backup CRD had no `status` subresource, but the operator wrote status through `/status`, an endpoint that only exists when the CRD enables it. Every write was a 404, forever, and the operator carried on. The obvious fix, turning the subresource on, moved the problem: from then on the API server ignores `status` in writes to the main resource, and the CronJob that had been stamping `lastSlaCheck` through the main resource kept getting `200 OK` while changing nothing.

## The evidence

The operator's log named the failing URL. For the second fault there was no error to find at all: the reporter's own log said "stamped 3 of 3", and only the object itself (`lastSlaCheck` unchanged) or a one-off run of the Job proved otherwise. `metadata.generation` was the other clue: without the subresource every status write counts as a change to the object and bumps it.

## Why Kubernetes behaved this way

With `subresources.status` the object splits into two write paths. The main endpoint accepts `spec` and drops `status`; `/status` accepts `status` and drops `spec`. The split is what lets users and controllers own different halves of an object, makes RBAC possible on `backups/status`, and keeps `metadata.generation` meaning "the spec changed", which controllers use with `status.observedGeneration`. Ignoring (not rejecting) the wrong half is how the API stays compatible with old clients, and why such bugs are silent.

## In production

Enable the status subresource on every CRD that has a status, from day one. When changing it on a live CRD, find every writer first (operators, CronJobs, scripts, GitOps tools) and check their writes land. Verify with the object, not with the HTTP code.

## Worth remembering

- `kubectl patch <kind> <name> --subresource=status --type=merge -p '{"status":{...}}'`
- `kubectl get <kind> <name> -o jsonpath='{.metadata.generation}'`
- `kubectl create job <name> --from=cronjob/<cronjob>` runs a CronJob once, now
