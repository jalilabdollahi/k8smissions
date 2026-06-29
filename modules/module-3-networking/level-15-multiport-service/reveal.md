## What went wrong

The Service exposes two ports but neither has a `name` field. When a Service has multiple ports, Kubernetes requires all ports to be named. The Ingress references the backend port as `name: http` — but with no names on the Service ports, the controller cannot find a match.

## Fix

In manifest.yaml, add names to both Service ports:

```yaml
ports:
- name: http
  port: 80
  targetPort: 80
- name: https
  port: 443
  targetPort: 443
```

## Why multi-port Services need names

With a single port, Kubernetes can unambiguously identify which port you mean. With multiple ports, it cannot guess — names make the reference explicit. This is enforced by the API server: a multi-port Service without names will fail validation.