## What went wrong

The Helm `values.yaml` had `image.tag: ""` — an empty value. The chart template `image: {{ .Values.image.repository }}:{{ .Values.image.tag }}` resolved to `nginx:latest`. `latest` is a moving target: it changes whenever the upstream maintainer pushes a new image, making deployments non-deterministic.

## Fix

```yaml
spec:
  containers:
  - name: helm-app
    image: nginx:1.27.4
```

In a real Helm workflow you would set this in `values.yaml`:
```yaml
image:
  repository: nginx
  tag: "1.27.4"
```

## Why this matters

Pinning image tags is a foundational GitOps principle: the Git repository should contain everything needed to reproduce an exact cluster state. `latest` breaks this because two identical commits can produce different running software. Tools like Renovate or Dependabot automate tag updates while keeping them explicit and reviewed.