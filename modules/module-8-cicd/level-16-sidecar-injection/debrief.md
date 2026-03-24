# Injected to Failure

## What Was Broken
The Istio sidecar injector added istio-proxy to every Tekton Task pod. Istio's proxy startup delays caused Tekton's step sequencing logic to fail — steps ran out of order or timed out.

## The Fix
Add 'sidecar.istio.io/inject: false' to the Task's podTemplate labels to opt out of injection.

## Why It Matters
Service mesh sidecars and Tekton's container lifecycle models conflict. Tekton uses init containers and entrypoint overrides that assume container ordering control. Sidecars disrupt this.

## Pro Tip
Apply namespace-level opt-out: kubectl label namespace k8smissions istio-injection=disabled — but this removes service mesh from all workloads. Per-task label is more surgical.

## Concepts
Tekton, Istio, sidecar injection, podTemplate, admission webhook
