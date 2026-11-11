#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

ep_count() { k get endpointslices -l kubernetes.io/service-name=blog -o jsonpath='{range .items[*].endpoints[?(@.conditions.ready==true)]}{.addresses[0]}{"\n"}{end}' 2>/dev/null | grep -c .; }
serve() { k exec probe -- sh -c 'for i in 1 2 3 4 5 6 7 8 9; do curl -s --max-time 3 http://blog; echo; done' 2>/dev/null | grep -c '^Acme blog: latest posts$'; }

ready=$(k get deploy blog -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -ne 3 ]; then
  echo "❌ Deployment blog: ${ready:-0} of 3 replicas Ready"
  exit 1
fi
n=$(ep_count)
if [ "$n" -ne 3 ]; then
  echo "❌ Service blog selects $n of 3 replicas"
  exit 1
fi
echo "✅ Service blog selects all 3 replicas"

if [ "$(serve)" -ne 9 ]; then
  echo "❌ not every request through Service blog returned the blog page"
  exit 1
fi
echo "✅ Service blog serves the blog on 9 of 9 requests"

victim=$(k get pods -l app=blog --no-headers | awk '$3=="Running"{print $1; exit}')
k delete pod "$victim" --wait=false >/dev/null 2>&1
ok=no
for i in $(seq 25); do
  sleep 2
  if [ "$(k get deploy blog -o jsonpath='{.status.readyReplicas}')" = "3" ] && [ "$(ep_count)" -eq 3 ] && ! k get pod "$victim" >/dev/null 2>&1; then ok=yes; break; fi
done
if [ "$ok" != "yes" ]; then
  echo "❌ after replacing a pod, Service blog no longer selects every replica"
  exit 1
fi
echo "✅ a replacement pod is selected by the Service too"
exit 0
exit 1
