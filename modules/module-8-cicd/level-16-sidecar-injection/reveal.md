## What went wrong

Istio's MutatingWebhook injects `istio-proxy` into every pod in namespaces labeled for injection. Tekton orchestrates step container ordering using its own entrypoint binary and a step sequencing mechanism. The Istio sidecar does not implement Tekton's wait protocol — it starts independently and interferes with the step lifecycle, causing hangs or out-of-order execution.

## Fix

```yaml
spec:
  podTemplate:
    labels:
      sidecar.istio.io/inject: "false"
  steps:
  - name: build
    image: busybox:1.36
    script: echo building
```

## Why this matters

Sidecar injection affects all pods in a namespace by default. For CI/CD task pods, Istio injection is almost never desirable — pipeline steps don't need mTLS, service discovery, or traffic management. The opt-out label `sidecar.istio.io/inject: "false"` (or the equivalent annotation on the pod) prevents injection for specific pods. An alternative: use a separate namespace for Tekton pipeline runs with injection disabled at the namespace level via the `istio-injection: disabled` label.