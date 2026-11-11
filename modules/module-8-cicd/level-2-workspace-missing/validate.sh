#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline ingest >/dev/null 2>&1; then
  echo "❌ Pipeline ingest does not exist"
  exit 1
fi

runs=$(k get pipelinerun -l tekton.dev/pipeline=ingest -o name 2>/dev/null | sed 's|.*/||' | grep -v '^ingest-2210$')
if [ -z "$runs" ]; then
  echo "❌ no new PipelineRun of ingest yet (ingest-2210 is the old failed one)"
  exit 1
fi

best=""
for r in $runs; do
  st=$(k get pipelinerun "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  files=$(k get taskrun -l "tekton.dev/pipelineRun=$r,tekton.dev/pipelineTask=verify" \
    -o jsonpath='{.items[0].status.results[?(@.name=="files")].value}' 2>/dev/null | tr -d '[:space:]')
  if [ "$st" = "True" ] && [ "$files" = "3" ]; then best=$r; break; fi
  last="$r: status=${st:-unknown}, files=${files:-none}"
done
if [ -z "$best" ]; then
  echo "❌ no new run of ingest has Succeeded with files=3 (last seen $last)"
  exit 1
fi
echo "✅ PipelineRun $best Succeeded and verify saw 3 files"

fetch=$(k get taskrun -l "tekton.dev/pipelineRun=$best,tekton.dev/pipelineTask=fetch" -o jsonpath='{.items[0].status.conditions[0].status}')
if [ "$fetch" != "True" ]; then
  echo "❌ in run $best the fetch Task did not succeed"
  exit 1
fi
echo "✅ both Tasks of $best ran against the shared workspace"
exit 0
exit 1
