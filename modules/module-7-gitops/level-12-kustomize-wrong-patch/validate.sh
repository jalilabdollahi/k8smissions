#!/bin/bash
NS=${NS:-k8smissions}
work=$(mktemp -d); trap 'rm -rf "$work"' EXIT
if ! kubectl -n gitops-git exec -c gitserver deploy/gitserver -- git --git-dir=/srv/git/payments.git archive main 2>/dev/null | tar -x -C "$work" 2>/dev/null; then
  echo "❌ cannot read the payments repository"
  exit 1
fi
prod=$(kubectl kustomize "$work/overlays/prod" 2>/dev/null)
reps=$(echo "$prod" | awk '/^kind: Deployment/{d=1} d&&/^  replicas:/{print $2; exit}')
img=$(echo "$prod" | awk '/^kind: Deployment/{d=1} d&&/image:/{print $2; exit}')
if [ "$reps" != "4" ] || [ "${img##*:}" != "1.0" ]; then
  echo "❌ overlays/prod in the repository renders replicas=${reps:-?} image=${img:-?}"
  exit 1
fi
stg=$(kubectl kustomize "$work/overlays/staging" 2>/dev/null | awk '/^  replicas:/{print $2; exit}')
if [ "$stg" != "2" ]; then
  echo "❌ overlays/staging no longer renders 2 replicas (${stg:-?})"
  exit 1
fi
echo "✅ overlays/prod at the repository head renders 4 replicas on the 1.0 image"

ready=$(kubectl -n "$NS" get deploy payments -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
live=$(kubectl -n "$NS" get deploy payments -o jsonpath='{.spec.template.spec.containers[0].image}' 2>/dev/null)
if [ "${ready:-0}" -ne 4 ] || [ "${live##*:}" != "1.0" ]; then
  echo "❌ Deployment payments: ${ready:-0} of 4 pods Ready on image ${live:-none}"
  exit 1
fi
bad=$(kubectl -n "$NS" get pods -l app=payments -o jsonpath='{range .items[*]}{.spec.containers[0].image}{"\n"}{end}' | grep -vc ':1.0$')
if [ "$bad" -ne 0 ]; then
  echo "❌ $bad payments pods still run an older image"
  exit 1
fi
echo "✅ Deployment payments runs 4 Ready pods on $live"

out=$(kubectl -n "$NS" exec probe -- sh -c 'for i in $(seq 20); do curl -s --max-time 2 http://payments; echo; done' 2>/dev/null)
good=$(echo "$out" | grep -c '^payments gateway$')
if [ "$good" -ne 20 ]; then
  echo "❌ Service payments: only $good of 20 requests answered"
  exit 1
fi
echo "✅ Service payments answers 20 of 20 requests"
exit 0
exit 1
