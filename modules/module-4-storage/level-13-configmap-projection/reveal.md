## What went wrong

The ConfigMap volume uses `items` to select which keys become files. Only `app.properties` is listed — `logging.properties` is silently omitted. The container expects both files but finds only one.

## Fix

In manifest.yaml, add the missing entry to the volume's items list:

```yaml
volumes:
- name: config
  configMap:
    name: app-config
    items:
    - key: app.properties
      path: app.properties
    - key: logging.properties
      path: logging.properties
```

## items vs no items

- **With `items`** — only the listed keys are projected; unlisted keys are excluded
- **Without `items`** — all ConfigMap keys are projected as files

Use `items` when you want to rename a key to a different filename (e.g. key `app.conf.prod` → path `app.conf`). If you just want all keys as files, omit `items` entirely.