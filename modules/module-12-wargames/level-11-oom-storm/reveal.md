Two faults:

1. `lib-defaults` (platform library 4.2.0) sets `CACHE_MB=90`, and all three services take it through `envFrom`. A 90 MB cache cannot fit in a 64Mi limit. Set a value that fits (for example 24) with `kubectl patch cm lib-defaults --type=merge -p '{"data":{"CACHE_MB":"24"}}'` and restart the pods so the new environment is read (`kubectl rollout restart deploy/svc-alpha deploy/svc-beta`).
2. `svc-gamma` writes a 40 MB export to a volume declared with `emptyDir: {medium: Memory}`. That is tmpfs: its pages are charged to the container's memory cgroup, so cache plus runtime plus 40 MB exceeds 64Mi even after fault 1 is fixed. Remove `medium: Memory` (a disk-backed emptyDir) with a JSON patch, or raise the limit of `svc-gamma` enough to cover everything.
