#!/bin/bash
# Level 11: replace a pod that is transcoding a 20s clip and check the clip finished and the pod exited by itself.
. ../_fixtures/lib.sh
SEL=app=video-transcoder

for d in video-transcoder result-collector; do
  if ! kubectl get deployment "$d" -n "$NS" >/dev/null 2>&1; then
    bad "Deployment $d does not exist"
    exit 1
  fi
done
if ! wait_ready "$SEL" 2 60 || ! wait_ready app=result-collector 1 30; then
  bad "video-transcoder needs 2 Ready pods and result-collector 1"
  exit 1
fi

GRACE=$(kubectl get deployment video-transcoder -n "$NS" -o jsonpath='{.spec.template.spec.terminationGracePeriodSeconds}')
POD=$(live_pods "$SEL" | head -1)
IP=$(kubectl get pod "$POD" -n "$NS" -o jsonpath='{.status.podIP}')
JOB="val-$$-$RANDOM"

COLL() { kubectl exec -n "$NS" deploy/result-collector -- python -c "import urllib.request;print(urllib.request.urlopen('http://127.0.0.1:8081/',timeout=4).read().decode())" 2>/dev/null; }

kubectl exec -n "$NS" deploy/result-collector -- python -c "import urllib.request;print(urllib.request.urlopen('http://$IP:8080/submit?id=$JOB&secs=20',timeout=5).status)" >/dev/null 2>&1
if ! COLL | jq -e --arg j "$JOB" '.started | index($j)' >/dev/null 2>&1; then
  bad "could not start a test clip on pod $POD"
  exit 1
fi
ok "a 20 second clip is running on $POD (grace period ${GRACE:-30}s)"

kubectl delete pod "$POD" -n "$NS" --wait=false >/dev/null 2>&1
T0=$SECONDS
while [ $((SECONDS - T0)) -lt 40 ]; do
  S=$(COLL)
  echo "$S" | jq -e --arg j "$JOB" '.done | index($j)' >/dev/null 2>&1 && break
  kubectl get pod "$POD" -n "$NS" >/dev/null 2>&1 || break
  sleep 2
done
sleep 2
S=$(COLL)
if ! echo "$S" | jq -e --arg j "$JOB" '.done | index($j)' >/dev/null 2>&1; then
  bad "the clip was lost: pod $POD was removed before reporting it finished (elapsed $((SECONDS - T0))s)"
  exit 1
fi
ok "the clip was reported finished"
if ! echo "$S" | jq -e --arg p "$POD" '.bye | index($p)' >/dev/null 2>&1; then
  bad "pod $POD never reported a clean shutdown (it was killed rather than stopped)"
  exit 1
fi
ok "pod $POD shut down by itself after its work"

if ! wait_ready "$SEL" 2 45; then
  bad "video-transcoder is back to only $(ready_count $SEL) Ready pods"
  exit 1
fi
ok "2 video-transcoder pods are Ready again"
exit 0
exit 1
