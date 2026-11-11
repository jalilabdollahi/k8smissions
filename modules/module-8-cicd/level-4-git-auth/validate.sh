#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

if ! k get pipeline build-payments >/dev/null 2>&1; then
  echo "❌ Pipeline build-payments does not exist"
  exit 1
fi
stype=$(k get secret ci-git -o jsonpath='{.type}' 2>/dev/null)
if [ "$stype" != "kubernetes.io/basic-auth" ]; then
  echo "❌ Secret ci-git is missing or is no longer of type kubernetes.io/basic-auth (${stype:-not found})"
  exit 1
fi
if k get pipeline build-payments -o yaml | grep -Eq '(ci-bot|ci-bot-secret|://[^/ ]*@)'; then
  echo "❌ the Pipeline carries credentials in its definition; the Secret must supply them"
  exit 1
fi
echo "✅ Secret ci-git is still basic-auth and no password is written into the Pipeline"

head=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- \
  git --git-dir=/srv/git/private/payments-ci.git rev-parse main 2>/dev/null | tr -d '[:space:]')
if [ -z "$head" ]; then
  echo "❌ cannot read the HEAD of payments-ci from the Git server"
  exit 1
fi

runs=$(k get pipelinerun -l tekton.dev/pipeline=build-payments -o name 2>/dev/null | sed 's|.*/||' | grep -v '^build-payments-31$')
if [ -z "$runs" ]; then
  echo "❌ no new PipelineRun of build-payments yet (build-payments-31 is the old failed one)"
  exit 1
fi
last=""
for r in $runs; do
  st=$(k get pipelinerun "$r" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  commit=$(k get taskrun -l "tekton.dev/pipelineRun=$r,tekton.dev/pipelineTask=clone" \
    -o jsonpath='{.items[0].status.results[?(@.name=="commit")].value}' 2>/dev/null | tr -d '[:space:]')
  if [ "$st" = "True" ] && [ "$commit" = "$head" ]; then
    echo "✅ PipelineRun $r Succeeded and clone reports commit ${commit:0:10}, the HEAD of payments-ci"
    exit 0
  fi
  last="$r status=${st:-running} commit=${commit:-none}"
done
echo "❌ no new run has Succeeded with the repository HEAD as its commit (last: $last)"
exit 1
