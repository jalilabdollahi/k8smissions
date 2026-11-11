#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ready=$(k get deploy invoice-mailer -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 2 ]; then
  echo "❌ invoice-mailer: ${ready:-0} of 2 pods Ready"
  exit 1
fi
echo "✅ invoice-mailer has 2 Ready pods"

sleep 8
pods=$(k get pods -l app=invoice-mailer --field-selector=status.phase=Running --no-headers 2>/dev/null | awk '$3=="Running"{print $1}')
n=0
for p in $pods; do
  n=$((n+1))
  tail=$(k logs "$p" --tail=4 2>/dev/null)
  if ! echo "$tail" | grep -q 'send status 200'; then
    echo "❌ $p: no successful send in its latest log lines"
    exit 1
  fi
  if echo "$tail" | grep -qF '$(SMTP'; then
    echo "❌ $p: still calling a URL with unexpanded variables"
    exit 1
  fi
done
if [ "$n" -ne 2 ]; then
  echo "❌ expected 2 running mailer pods, found $n"
  exit 1
fi
echo "✅ both mailer pods deliver to smtp-relay with status 200"
exit 0
exit 1
