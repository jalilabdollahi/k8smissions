# Helm Values Gone Wrong

## Situation
A Helm chart was deployed with wrong values. The image.tag value is empty ("") in values.yaml, so the pod pulls "latest" in production — against policy. Chart also fails linting.

## Successful Fix
Set image.tag: "1.2.3" in values.yaml helm upgrade myapp ./charts/myapp -n k8smissions

## What To Validate
helm status myapp → deployed, pod uses correct image tag

## Why It Matters
Review how the fix changed the cluster behavior for Helm Values Gone Wrong.

## Concepts
Helm values, chart templates ({{ .Values.image.tag }}), helm install/upgrade/status/get-values
