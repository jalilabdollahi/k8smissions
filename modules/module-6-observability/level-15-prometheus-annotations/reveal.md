The annotations were written on the Deployment object, not on its pod template, so no pod carried them and prom-lite (which discovers pods) saw nothing. They also pointed at the wrong port and path: the app serves metrics on 9102 at `/metrics`, not 8080 at `/actuator/prometheus`.

1. `curl http://prom-lite:9090/targets` has no payments-api entry; `get pod -o jsonpath='{...annotations}'` shows none of the `prometheus.io/*` keys.
2. Patch the pod template with all three annotations as strings: `kubectl patch deploy payments-api --type=merge -p '{"spec":{"template":{"metadata":{"annotations":{"prometheus.io/scrape":"true","prometheus.io/port":"9102","prometheus.io/path":"/metrics"}}}}}'` (an unquoted `true` is rejected by the API).
3. After the rollout `/targets` shows both pods `up` with `app_orders_total`. The first attempt with the old port and path would show `down` with `HTTP Error 404`.
