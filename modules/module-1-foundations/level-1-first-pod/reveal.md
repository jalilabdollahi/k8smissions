## What went wrong

The field `command: ["nginxzz"]` overrides the image's ENTRYPOINT. Instead of starting nginx, the container tries to run `nginxzz` — which does not exist anywhere in the image. It exits immediately with code 127 (command not found).

## Fix

Remove the `command` field from manifest.yaml:

```yaml
# delete this line:
command: ["nginxzz"]
```

Without `command`, the container uses the nginx image's default ENTRYPOINT (`nginx -g 'daemon off;'`).

## Why this matters

In a Dockerfile there are two fields: ENTRYPOINT (the executable) and CMD (default arguments). In Kubernetes, `command` maps to ENTRYPOINT and `args` maps to CMD. Setting `command` completely replaces the image's entrypoint — a common source of confusion when writing pod specs.