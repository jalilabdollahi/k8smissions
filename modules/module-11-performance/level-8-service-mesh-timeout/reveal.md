The Envoy route has `timeout: 3s`, but rendering a PDF takes 6 to 9 seconds, so Envoy gives up and answers 504 (`UT`, upstream request timeout) while the app is still working.

1. `kubectl logs deploy/invoice-render -c envoy` shows `504 UT` lines; the admin stat `cluster.app.upstream_rq_timeout` rises with them.
2. Edit the ConfigMap: `route.timeout: 15s` (above 9s, still finite).
3. Envoy loads its static config at start, so `kubectl rollout restart deployment/invoice-render` is needed for the new value to take effect.
4. Do not use `0s` (no timeout): a hung backend would then hold the client forever, and the validator checks that `/hang` is still cut off with a 504.
