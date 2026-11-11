## Common mistakes

- **Reading `kubectl logs` and stopping at the banner.** The first 40 lines are boot noise. Filter for `ERROR` and use `--previous` while the pod is in back-off.
- **Fixing the first error and walking away.** The program validates one problem at a time. After the first fix there is a second `ERROR` line; keep checking the logs after every restart.
- **Editing the ConfigMap and waiting.** The process read its file at start. Without deleting the pods or a rollout restart, they keep crashing on the old values until the next back-off retry, and then only if the kubelet has already refreshed the volume.
- **Deleting the unknown region line.** The pods start but the file then lists one region, and the check expects both regions loaded. Use an allowed region name instead.
