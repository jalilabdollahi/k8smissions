# The Missing File

## What Was Broken
The volume spec had an `items:` list that only projected `app.properties`. When `items:` is present, it acts as an explicit allowlist — only listed keys appear in the mount path. `logging.properties` was silently excluded.

## The Fix
Add `logging.properties` to the items list, or remove the `items:` block entirely to mount all ConfigMap keys automatically.

## Why It Matters
The `items:` field is useful for selective mounting and path renaming (e.g., mount `app.conf.production` as `app.conf`). But it is a footgun when keys are added to the ConfigMap later — they won't appear until the pod spec is updated.

## Pro Tip
To mount a ConfigMap key at a specific path without affecting other keys, use a subPath mount: `mountPath: /config/app.properties` with `subPath: app.properties`. This mounts a single file without replacing the entire directory.

## Concepts
ConfigMap, volume, items projection, key-to-path, subPath
