## What went wrong

The values file has:
```yaml
image:
tag: v2.0.0       # <-- at root level
  repository: nginx
```

YAML sees `tag` as a root-level key, not `image.tag`. The Helm template `{{ .Values.image.tag }}` finds nothing under `image.tag` and uses its default (the old version).

## Fix

```yaml
image:
  tag: v2.0.0        # indented 2 spaces under image:
  repository: nginx  # also 2 spaces
```

## Why this matters

YAML is whitespace-significant — indentation defines the document hierarchy. A single misaligned key silently parses as a different structure with no YAML error, because `tag: v2.0.0` is valid YAML at the root level. This is one of the most common sources of 'my Helm values aren't being applied' bugs. Always use `helm template . -f values.yaml` to render the chart locally and verify the output before running `helm upgrade`.