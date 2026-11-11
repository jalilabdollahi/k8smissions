#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get sts consul -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ] || [ "$(k get sts consul -o jsonpath='{.spec.replicas}')" != "3" ]; then
  echo "❌ StatefulSet consul must have 3 Ready replicas (found: ${ready:-0})"
  exit 1
fi
echo "✅ consul: 3 of 3 pods Ready"

n=$(k get pdb -o name 2>/dev/null | wc -l)
if [ "$n" -ne 1 ]; then
  echo "❌ expected exactly one PodDisruptionBudget in the namespace, found $n"
  exit 1
fi
pdb=$(k get pdb -o jsonpath='{.items[0].metadata.name}')
expected=$(k get pdb "$pdb" -o jsonpath='{.status.expectedPods}')
healthy=$(k get pdb "$pdb" -o jsonpath='{.status.currentHealthy}')
allowed=$(k get pdb "$pdb" -o jsonpath='{.status.disruptionsAllowed}')
if [ "${expected:-0}" -ne 3 ] || [ "${healthy:-0}" -ne 3 ]; then
  echo "❌ PDB $pdb protects ${expected:-0} pods (healthy: ${healthy:-0}), it should protect the 3 consul pods"
  exit 1
fi
echo "✅ PDB $pdb selects the 3 consul pods"
if [ "${allowed:-0}" -ne 1 ]; then
  echo "❌ PDB $pdb allows ${allowed:-0} disruptions; quorum needs exactly 1 at a time (so one member can still be drained)"
  exit 1
fi
echo "✅ exactly 1 voluntary disruption is allowed"

# the Eviction API agrees: one eviction is admitted (dry run, nothing is deleted)
cat > /tmp/evict-$$.json <<EOP
{"apiVersion":"policy/v1","kind":"Eviction","metadata":{"name":"consul-0","namespace":"$NS"},"deleteOptions":{"dryRun":["All"]}}
EOP
out=$(kubectl create --raw "/api/v1/namespaces/$NS/pods/consul-0/eviction" -f /tmp/evict-$$.json 2>&1)
rm -f /tmp/evict-$$.json
if ! echo "$out" | grep -q '"status": *"Success"'; then
  echo "❌ an eviction of consul-0 was refused: $(echo "$out" | head -c 200)"
  exit 1
fi
echo "✅ the Eviction API admits one eviction"
exit 0
exit 1
