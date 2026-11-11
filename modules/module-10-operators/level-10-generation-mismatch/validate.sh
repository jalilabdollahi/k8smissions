#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
CR=inventories.stock.acme.io

ready=$(k get deploy inventory-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ inventory-operator has no ready pod"
  exit 1
fi
for n in stock-eu stock-us; do
  if ! k get $CR "$n" >/dev/null 2>&1; then
    echo "❌ Inventory $n does not exist"
    exit 1
  fi
done
echo "✅ inventory-operator is running and both Inventory objects exist"

rv() { k get $CR "$1" -o jsonpath='{.metadata.resourceVersion}' 2>/dev/null; }
synced() {  # synced <name>: observedGeneration equals generation
  local g o
  g=$(k get $CR "$1" -o jsonpath='{.metadata.generation}' 2>/dev/null)
  o=$(k get $CR "$1" -o jsonpath='{.status.observedGeneration}' 2>/dev/null)
  [ -n "$g" ] && [ "$g" = "$o" ]
}

# let a freshly restarted operator finish its first pass
for i in $(seq 1 8); do
  synced stock-eu && synced stock-us && break
  sleep 2
done

# an idle object must not be written to
a1=$(rv stock-eu); b1=$(rv stock-us)
for i in 1 2 3 4 5; do
  sleep 3
  if [ "$(rv stock-eu)" != "$a1" ] || [ "$(rv stock-us)" != "$b1" ]; then
    echo "❌ Inventory objects are still being rewritten while nobody edits them (resourceVersion keeps changing)"
    exit 1
  fi
done
echo "✅ idle Inventory objects stay untouched for 15 seconds"

# a spec change flows through to status and to the child
cur=$(k get $CR stock-eu -o jsonpath='{.spec.reorderLevel}')
new=$((cur + 7))
k patch $CR stock-eu --type=merge -p "{\"spec\":{\"reorderLevel\":$new}}" >/dev/null
ok=0
for i in $(seq 1 10); do
  got=$(k get cm inventory-stock-eu -o jsonpath='{.data.reorderLevel}' 2>/dev/null)
  if synced stock-eu && [ "$got" = "$new" ]; then ok=1; break; fi
  sleep 1
done
if [ "$ok" != 1 ]; then
  echo "❌ after a spec change to reorderLevel $new, observedGeneration is '$(k get $CR stock-eu -o jsonpath='{.status.observedGeneration}')' (generation $(k get $CR stock-eu -o jsonpath='{.metadata.generation}')) and the child ConfigMap says '${got:-nothing}'"
  exit 1
fi
echo "✅ a spec change reaches the status and the child ConfigMap"

# drift is still healed
sku=$(k get $CR stock-us -o jsonpath='{.spec.sku}')
k delete cm inventory-stock-us --ignore-not-found >/dev/null
ok=0
for i in $(seq 1 20); do
  if [ "$(k get cm inventory-stock-us -o jsonpath='{.data.sku}' 2>/dev/null)" = "$sku" ]; then ok=1; break; fi
  sleep 1
done
if [ "$ok" != 1 ]; then
  echo "❌ ConfigMap inventory-stock-us was deleted and the operator did not bring it back"
  exit 1
fi
echo "✅ a deleted child ConfigMap is recreated"
exit 0
exit 1
