#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
REG=http://registry:5000

if ! k get pipeline build-and-push >/dev/null 2>&1; then
  echo "❌ Pipeline build-and-push does not exist"
  exit 1
fi
probe() { k exec probe -- curl -s --max-time 8 "$@"; }

anon=$(probe -o /dev/null -w '%{http_code}' -X POST "$REG/v2/ledger/api/blobs/uploads/")
if [ "$anon" != "401" ]; then
  echo "❌ the registry answered $anon to an anonymous push, it must answer 401"
  exit 1
fi

tag="v$(date +%s)"
run=$(k create -o name -f - <<YAML
apiVersion: tekton.dev/v1
kind: PipelineRun
metadata:
  generateName: verify-push-
spec:
  pipelineRef:
    name: build-and-push
  params:
  - name: tag
    value: $tag
  taskRunTemplate:
    serviceAccountName: builder
YAML
)
if [ -z "$run" ]; then
  echo "❌ could not start a run of build-and-push"
  exit 1
fi
trap 'k delete "$run" --wait=false >/dev/null 2>&1' EXIT
for _ in $(seq 1 30); do
  st=$(k get "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  if [ "$st" = "True" ] || [ "$st" = "False" ]; then break; fi
  sleep 2
done
if [ "$st" != "True" ]; then
  echo "❌ the push run did not Succeed (status: ${st:-still running})"
  exit 1
fi
echo "✅ run of build-and-push as builder Succeeded"

tags=$(probe -u ci-push:ship-it-4711 "$REG/v2/ledger/api/tags/list")
if ! echo "$tags" | grep -q "\"$tag\""; then
  echo "❌ the registry does not list tag $tag in ledger/api (got: ${tags:-nothing})"
  exit 1
fi
reported=$(probe -I -u ci-push:ship-it-4711 \
  -H 'Accept: application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' \
  "$REG/v2/ledger/api/manifests/$tag" | tr -d '\r' | awk 'tolower($1)=="docker-content-digest:" {print $2}')
got=$(k get taskrun -l "tekton.dev/pipelineRun=${run#*/}" -o jsonpath='{.items[0].status.results[?(@.name=="digest")].value}' | tr -d '[:space:]')
if [ -z "$reported" ] || [ "$got" != "$reported" ]; then
  echo "❌ result digest '${got:-empty}' does not match the registry's '${reported:-none}'"
  exit 1
fi
echo "✅ tag $tag is in the registry with digest ${reported:0:19}..."

anon=$(probe -o /dev/null -w '%{http_code}' -X POST "$REG/v2/ledger/api/blobs/uploads/")
if [ "$anon" != "401" ]; then
  echo "❌ the registry accepts anonymous pushes now"
  exit 1
fi
echo "✅ anonymous pushes are still refused"
exit 0
exit 1
