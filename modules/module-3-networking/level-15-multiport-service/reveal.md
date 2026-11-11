1. The Ingress backend asks for Service port `web`; the Service has `http` and `metrics`. nginx has no upstream for an unknown port name and answers 503:

   `kubectl -n k8smissions patch ingress gateway --type=json -p '[{"op":"replace","path":"/spec/rules/0/http/paths/0/backend/service/port","value":{"name":"http"}}]'`

2. The `metrics` port was copied with `protocol: UDP`, but the scraper speaks TCP, so connections are refused. Set it back to TCP:

   `kubectl -n k8smissions patch svc gateway --type=json -p '[{"op":"replace","path":"/spec/ports/1/protocol","value":"TCP"}]'`
