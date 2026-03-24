# No Endpoints

## Situation
Service exists, pods exist, but endpoints list is empty. Service selector label value doesn't match pod label.

## Successful Fix
Update service selector OR pod label to match

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for No Endpoints.

## Concepts
ClusterIP service, label selectors, endpoints, kubectl get ep
