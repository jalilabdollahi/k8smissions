**What was broken.** The Envoy sidecar in front of invoice-render had a route timeout of 3 seconds, while generating an invoice takes 6 to 9. Every slow request was cut off by the proxy with a 504 even though the app was working and would have answered.

**The evidence.** Calls straight to the app container worked, calls through port 8080 (Envoy) failed at about 3 seconds each. Envoy's access log printed `504 UT` for these requests (`UT` means upstream request timeout), and the admin counter `cluster.app.upstream_rq_timeout` increased once per failure. The pair of facts, success at the app and 504 at the proxy, pointed at a timeout in the proxy rather than at the app.

**Why Kubernetes behaved this way.** Kubernetes has nothing to do with this timeout. The proxy is an ordinary container, and Envoy applies the `route.timeout` from the configuration file it loaded. Here that file is a static one from a ConfigMap, which Envoy reads once when it starts. The ConfigMap volume does update inside the pod after you edit it, but the running process never looks again, so the edit alone has no effect until the container restarts.

**The fix.** Raise the timeout above the slowest legitimate request, with some margin (15s), and restart the pod so Envoy re-reads the file. Setting `0s` removes the timeout entirely and looks like the same fix, but a hung backend would then hold every client forever; the validator tests that as well.

**In production.** A service mesh (Istio, Linkerd) pushes route changes to the proxies over xDS, so no restart is needed, but the timeouts still belong to the proxy and must be aligned with the backend's real latency and the caller's own timeout. Alert on proxy-generated 504s, and give long-running work an asynchronous API.

**Worth remembering.**
- `kubectl logs <pod> -c envoy` and the `UT` response flag
- `/stats?filter=upstream_rq_timeout` on the Envoy admin port
- `kubectl rollout restart deployment/<name>` to reload static config
