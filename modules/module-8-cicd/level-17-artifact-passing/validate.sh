#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline ship-api >/dev/null 2>&1 || ! k get deployment registry >/dev/null 2>&1; then
  echo "❌ Pipeline ship-api or the registry is missing"
  exit 1
fi
runs=$(k get pipelinerun -l tekton.dev/pipeline=ship-api -o name 2>/dev/null | sed 's|.*/||' | grep -v '^ship-api-0422$')
if [ -z "$runs" ]; then
  echo "❌ no new PipelineRun of ship-api yet (ship-api-0422 is the old rejected one)"
  exit 1
fi
manifest_digest() { # tag
  kubectl -n "$NS" exec deploy/registry -- wget -qO- \
    --header 'Accept: application/vnd.docker.distribution.manifest.v2+json, application/vnd.oci.image.manifest.v1+json' \
    "http://localhost:5000/v2/ship-api/manifests/$1" 2>/dev/null | sha256sum | awk '{print "sha256:" $1}'
}
last=""
for r in $runs; do
  st=$(k get pipelinerun "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  got=$(k get taskrun -l "tekton.dev/pipelineRun=$r,tekton.dev/pipelineTask=deploy" \
    -o jsonpath='{.items[0].status.results[?(@.name=="deployed-digest")].value}' 2>/dev/null | tr -d '[:space:]')
  want=$(manifest_digest "$r")
  if [ "$st" = "True" ] && [ -n "$got" ] && [ "$got" = "$want" ]; then
    echo "✅ PipelineRun $r Succeeded and deploy received the registry digest ${got:0:19}..."
    exit 0
  fi
  last="$r status=${st:-running} deployed='${got:-none}'"
done
echo "❌ no new run has Succeeded with the pushed image's digest (last: $last)"
exit 1
