kubectl -n k8smissions get cm -l olm.acme.io/bundle -o jsonpath='{range .items[*]}{.metadata.name}{"  "}{.data.bundle\.json}{"\n"}{end}'
use() { kubectl -n k8smissions patch deployment widget-operator --type=json -p "[{\"op\":\"replace\",\"path\":\"/spec/template/spec/volumes/0/configMap/name\",\"value\":\"bundle-$1\"},{\"op\":\"replace\",\"path\":\"/metadata/labels/olm.acme.io~1pinned-version\",\"value\":\"$1\"}]"; kubectl -n k8smissions rollout status deployment/widget-operator --timeout=90s; }
use 1.3.0
for i in $(seq 1 30); do
  [ "$(kubectl -n k8smissions get widgets -o jsonpath='{.items[*].status.schemaVersion}')" = "2 2 2" ] && break
  sleep 2
done
use 1.4.0
