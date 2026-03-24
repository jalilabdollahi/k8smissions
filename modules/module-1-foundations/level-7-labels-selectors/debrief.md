# No Endpoints

## Situation
Service exists but has zero endpoints. Pod labels don't match the service selector.

## Successful Fix
Either update pod label to "backend" or service selector to "backend-v1"

## What To Validate
kubectl get endpoints labels-svc -n k8smissions → has IP

## Why It Matters
Explain how Services discover pods via label selectors, importance of consistent labeling strategy

## Concepts
labels, selectors, service endpoints, kubectl get ep
