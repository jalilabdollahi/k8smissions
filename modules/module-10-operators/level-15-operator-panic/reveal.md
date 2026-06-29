## What went wrong

The operator tries to register a controller for `workloads.example.com` at startup. If this CRD isn't registered in the API server, the scheme registration fails and controller-runtime panics with a nil dereference. The pod crashes, kubelet restarts it, and it panics again — classic CrashLoopBackOff.

## Fix

```yaml
initContainers:
- name: wait-for-crd
  image: bitnami/kubectl:latest
  command:
  - /bin/sh
  - -c
  - until kubectl get crd workloads.example.com; do sleep 5; done
```

## Why this matters

Operator deployment ordering matters: CRDs must be registered before the operator starts. In Helm charts, CRDs go in the `crds/` directory which is installed first. In raw manifests, apply CRDs separately before applying the operator Deployment. The init container pattern is a runtime safety net that protects against race conditions when both CRD and operator are deployed simultaneously. It's also useful in multi-operator setups where one operator depends on another's CRDs.