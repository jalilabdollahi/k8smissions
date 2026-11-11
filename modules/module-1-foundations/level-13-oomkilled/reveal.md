1. `kubectl describe pod` shows `Last State: Terminated`, `Reason: OOMKilled`, `Exit Code: 137`; `kubectl logs --previous` stops after "building image cache (150 MiB)".
2. The container limit is 64Mi but the cache alone takes 150 MiB, so the kernel kills it every time it starts.
3. Raise the limit above real use, for example `kubectl set resources deployment thumbnailer --requests=memory=192Mi --limits=memory=256Mi`.
4. Raising only the request would not help: the limit is what triggers the kill. Removing the limit would hide the problem and is not allowed here.
