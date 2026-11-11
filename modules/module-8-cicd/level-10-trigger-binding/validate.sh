#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
URL=http://gitserver.gitops-git.svc.cluster.local:8080/cgi-bin/git/webhook-app.git

if ! k get deployment hook >/dev/null 2>&1 || ! k get pipeline clone-at >/dev/null 2>&1; then
  echo "❌ Deployment hook or Pipeline clone-at is missing"
  exit 1
fi
if ! k rollout status deployment/hook --timeout=40s >/dev/null 2>&1; then
  echo "❌ Deployment hook is not rolled out and ready"
  exit 1
fi
sha=$(kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/webhook-app.git rev-parse main~1 2>/dev/null | tr -d '[:space:]')
if [ -z "$sha" ]; then
  echo "❌ cannot read the repository webhook-app from the Git server"
  exit 1
fi
payload="{\"ref\":\"refs/heads/main\",\"after\":\"$sha\",\"head_commit\":{\"id\":\"$sha\",\"message\":\"first release\"},\"repository\":{\"full_name\":\"acme/webhook-app\",\"clone_url\":\"$URL\"}}"

before=$(k get pipelinerun -l source=webhook -o name | sort)
resp=$(kubectl -n "$NS" run "hook-probe-$$" --rm -i --restart=Never --image=curlimages/curl:8.10.1 --quiet -- \
  curl -s --max-time 15 -X POST -H 'Content-Type: application/json' -d "$payload" http://hook:8080/ 2>/dev/null)
after=$(k get pipelinerun -l source=webhook -o name | sort)
new=$(comm -13 <(echo "$before") <(echo "$after"))
n=$(echo "$new" | grep -c .)
if [ "$n" != "1" ]; then
  echo "❌ a push payload should create exactly one PipelineRun, $n were created (receiver said: ${resp:-nothing})"
  exit 1
fi
run=${new#*/}
trap 'k delete pipelinerun "$run" --wait=false >/dev/null 2>&1' EXIT
rev=$(k get pipelinerun "$run" -o jsonpath='{.spec.params[?(@.name=="revision")].value}')
repo=$(k get pipelinerun "$run" -o jsonpath='{.spec.params[?(@.name=="repo-url")].value}')
if [ "$rev" != "$sha" ]; then
  echo "❌ the run created for the push has revision '${rev}', the payload commit is ${sha:0:10}"
  exit 1
fi
if [ "$repo" != "$URL" ]; then
  echo "❌ the run has repo-url '${repo}', not the clone URL from the payload"
  exit 1
fi
echo "✅ the push created $run with revision ${sha:0:10} and the payload's clone URL"
for _ in $(seq 1 30); do
  st=$(k get pipelinerun "$run" -o jsonpath='{.status.conditions[0].status}' 2>/dev/null)
  [ "$st" = "True" ] || [ "$st" = "False" ] && break
  sleep 2
done
commit=$(k get taskrun -l "tekton.dev/pipelineRun=$run" -o jsonpath='{.items[0].status.results[?(@.name=="commit")].value}' 2>/dev/null)
if [ "$st" = "True" ] && [ "$commit" = "$sha" ]; then
  echo "✅ $run Succeeded and checked out ${commit:0:10}"
  exit 0
fi
echo "❌ $run did not succeed with the pushed commit (status '${st:-running}', commit '${commit:-none}')"
exit 1
