#!/bin/bash
NS=${NS:-k8smissions}
CRD=invoicebatches.billing.acme.io
cache=$(mktemp -d)
trap 'rm -rf "$cache"' EXIT
fresh() { rm -rf "$cache"/*; kubectl --cache-dir="$cache" "$@"; }   # an empty discovery cache: what a colleague's kubectl sees

if ! kubectl get crd $CRD >/dev/null 2>&1; then
  echo "❌ the InvoiceBatch CRD is gone"
  exit 1
fi

# the batches must be untouched: 8 of them, 4 failed
total=$(kubectl -n "$NS" get $CRD -o name 2>/dev/null | grep -c .)
failed=$(kubectl -n "$NS" get $CRD -o jsonpath='{range .items[*]}{.status.state}{"\n"}{end}' 2>/dev/null | grep -c '^Failed$')
if [ "$total" != 8 ] || [ "$failed" != 4 ]; then
  echo "❌ the InvoiceBatch objects changed: $total found with $failed failed (expected 8 with 4 failed)"
  exit 1
fi
echo "✅ all 8 InvoiceBatch objects are intact"

# kubectl get all
ok=0
for i in $(seq 1 10); do
  n=$(fresh get all -n "$NS" -o name 2>/dev/null | grep -c 'invoicebatch')
  [ "$n" = 8 ] && { ok=1; break; }
  sleep 2
done
if [ "$ok" != 1 ]; then
  echo "❌ kubectl get all -n $NS lists ${n:-0} of 8 InvoiceBatch objects"
  exit 1
fi
echo "✅ kubectl get all lists the InvoiceBatch objects"

# short name
n=$(fresh get ib -n "$NS" -o name 2>/dev/null | grep -c 'invoicebatch')
if [ "$n" != 8 ]; then
  echo "❌ kubectl get ib does not list the 8 batches (got $n)"
  exit 1
fi
echo "✅ kubectl get ib works"

# default columns
out=$(fresh get invoicebatches -n "$NS" 2>/dev/null)
header=$(echo "$out" | head -1)
if ! echo "$header" | grep -qi 'STATE' || ! echo "$header" | grep -qi 'PROGRESS'; then
  echo "❌ the default output has the columns: $(echo "$header" | tr -s ' ') (STATE and PROGRESS expected)"
  exit 1
fi
col=$(echo "$header" | tr -s ' ' | tr ' ' '\n' | grep -n -i '^STATE$' | cut -d: -f1)
states=$(echo "$out" | tail -n +2 | tr -s ' ' | cut -d' ' -f"$col" | grep -c '^Failed$')
prog=$(echo "$out" | grep -c '[0-9]/[0-9]')
if [ "$states" != 4 ] || [ "$prog" != 8 ]; then
  echo "❌ the STATE and PROGRESS columns do not show the real values ($states failed states and $prog progress values seen, expected 4 and 8)"
  exit 1
fi
echo "✅ kubectl get invoicebatches shows STATE and PROGRESS"
exit 0
exit 1
