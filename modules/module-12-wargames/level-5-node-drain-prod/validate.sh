#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0

# the probe must never sit on the node under maintenance, and must tolerate a leftover taint
kubectl get pod probe -n "$NS" >/dev/null 2>&1 || kubectl apply -n "$NS" -f - >/dev/null 2>&1 <<'YAML'
apiVersion: v1
kind: Pod
metadata:
  name: probe
  labels: {app: probe}
spec:
  terminationGracePeriodSeconds: 0
  tolerations:
  - {operator: Exists}
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - {key: maintenance, operator: DoesNotExist}
  containers:
  - name: curl
    image: curlimages/curl:8.10.1
    command: ["sleep", "3600"]
YAML
kubectl wait pod/probe -n "$NS" --for=condition=Ready --timeout=60s >/dev/null 2>&1 || { bad "could not start the probe pod"; exit 1; }

target=$(kubectl get nodes -l maintenance=pending -o jsonpath='{.items[0].metadata.name}' 2>/dev/null)
if [ -z "$target" ]; then bad "no node is labelled maintenance=pending any more"; exit 1; fi
cordoned=$(kubectl get node "$target" -o jsonpath='{.spec.unschedulable}')
if [ "$cordoned" = "true" ]; then ok "$target is cordoned"; else bad "$target is not cordoned"; fail=1; fi

left=$(kubectl -n "$NS" get pods -o json | jq -r --arg n "$target" '.items[]
  | select(.spec.nodeName==$n and .metadata.deletionTimestamp==null)
  | select((.metadata.ownerReferences // []) | all(.kind != "DaemonSet"))
  | select(.metadata.labels.app != "probe") | .metadata.name' | tr '\n' ' ')
if [ -z "$left" ]; then ok "no workload pods are left on $target"; else bad "pods still on the node: $left"; fail=1; fi

for d in checkout search; do
  if rollout_done "$d" 2; then ok "$d: 2 of 2 replicas Ready"; else bad "$d: replicas are not all Ready"; fail=1; fi
  body=$(pcurl "http://$d/" | tr -d '\n')
  if [ "$body" = "$d-ok" ]; then ok "$d answers through its Service"; else bad "$d does not answer through its Service"; fail=1; fi
done

pdb=$(kubectl -n "$NS" get pdb -o json | jq -r '[.items[] | select(.spec.selector.matchLabels.app=="checkout")] | length')
if [ "${pdb:-0}" -ge 1 ]; then ok "a PodDisruptionBudget still protects checkout"; else bad "checkout has no PodDisruptionBudget"; fail=1; fi

[ "$fail" = 0 ] && exit 0
exit 1
