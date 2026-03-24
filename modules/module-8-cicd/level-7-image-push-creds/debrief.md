# Push Denied

## What Was Broken
The ci-sa ServiceAccount had no imagePullSecrets or secrets. The image push step received 401 from the registry because no credentials were presented.

## The Fix
Create a docker-registry secret and attach it to the ServiceAccount. Tekton mounts all attached secrets into Task pods.

## Why It Matters
In production, use short-lived credentials: GitHub Actions OIDC tokens, GKE Workload Identity, or AWS IRSA. These avoid long-lived static secrets in etcd.

## Pro Tip
Never hardcode registry passwords. Use: kubectl create secret docker-registry with a short-lived token, or configure Workload Identity for cloud registries.

## Concepts
Tekton, registry credentials, docker-registry secret, image push, ServiceAccount
