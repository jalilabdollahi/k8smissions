The `indexer` sidecar is started with a flag its script does not know, so it exits with a usage error and never creates the file `/index/ready`. Without that file the API container fails its readiness probe and no pod is listed as an endpoint.

1. `kubectl -n k8smissions logs deploy/search-api -c indexer --previous` shows the usage error, which names the required `--output` flag.
2. `kubectl -n k8smissions patch deployment search-api -p '{"spec":{"template":{"spec":{"containers":[{"name":"indexer","args":["--output","/index"]}]}}}}'` corrects the arguments.
3. Keep the readiness probe: removing it adds pods to the Service while the API still answers 503 "index missing".
