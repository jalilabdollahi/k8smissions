The CPU is burned by the `exporter` sidecar in each thumbnailer pod, not by the `app` container.

1. `kubectl -n k8smissions top pod --containers --sort-by=cpu` shows `exporter` at about 1000m and `app` near 0m.
2. `kubectl -n k8smissions set resources deploy/thumbnailer -c exporter --limits=cpu=200m` caps only that container; the Deployment rolls out new pods.
3. Verify: `kubectl -n k8smissions exec <pod> -c exporter -- cat /sys/fs/cgroup/cpu.max` prints `20000 100000`.
