# Can't Find the Service

## Situation
Pod tries to connect to a service using wrong DNS name. Uses just "db" instead of "db.k8smissions.svc.cluster.local".

## Successful Fix
Set DB_HOST=db.k8smissions.svc.cluster.local

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Can't Find the Service.

## Concepts
DNS FQDN, CoreDNS, ndots, short names vs FQDN, <svc>.<ns>.svc.cluster.local format
