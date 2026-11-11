## Common mistakes

- **Reading only `kubectl logs <pod>`.** That shows nginx, which is fine. The sidecar's message is only in `-c log-shipper`.
- **Adding a second `emptyDir` volume.** A new volume has nothing to do with the one nginx writes to. Reuse the `logs` volume that already exists and mount it.
- **Changing nginx to log to stdout.** The page still works, but the objective is that the sidecar's logs carry the access lines, and with the sidecar still restarting READY stays `1/2`.
- **Removing the sidecar.** The pods go `2/2`... but the audit requirement is gone with it, and the check that every request reaches the shipper fails.
