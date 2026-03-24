# Silent Failure

## Situation
Pod is in Running state but the app is not serving requests. The problem is only visible in logs: wrong config file path.

## Successful Fix
Change CONFIG_PATH to /etc/config/app.yml

## What To Validate
Pod Running AND health check endpoint returns 200

## Why It Matters
Difference between Pod Running and App Healthy, why readiness probes matter

## Concepts
kubectl logs, application logs, debugging running pods, exec into container
