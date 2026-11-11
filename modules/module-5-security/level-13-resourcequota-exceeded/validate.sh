#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

# 1. the guard rail is untouched
hard=$(k get quota object-counts -o jsonpath='{.spec.hard.count/pods}' 2>/dev/null)
if [ "$hard" != "10" ]; then
  echo "❌ quota object-counts must keep count/pods: 10 (found: ${hard:-quota missing})"
  exit 1
fi
if [ "$(k get quota --no-headers | wc -l)" -ne 1 ]; then
  echo "❌ there must be exactly one quota in the namespace"
  exit 1
fi
echo "✅ quota object-counts still limits the namespace to 10 pods"

# 2. the CronJob is alive and now bounded
if ! k get cronjob price-sync >/dev/null 2>&1; then
  echo "❌ CronJob price-sync was deleted"
  exit 1
fi
sched=$(k get cronjob price-sync -o jsonpath='{.spec.schedule}')
susp=$(k get cronjob price-sync -o jsonpath='{.spec.suspend}')
if [ -z "$sched" ] || [ "$susp" = "true" ]; then
  echo "❌ price-sync must stay scheduled and not suspended"
  exit 1
fi
hist=$(k get cronjob price-sync -o jsonpath='{.spec.successfulJobsHistoryLimit}')
ttl=$(k get cronjob price-sync -o jsonpath='{.spec.jobTemplate.spec.ttlSecondsAfterFinished}')
bounded=no
[ -n "$hist" ] && [ "$hist" -le 5 ] && bounded=yes
[ -n "$ttl" ] && [ "$ttl" -le 86400 ] && bounded=yes
if [ "$bounded" != yes ]; then
  echo "❌ price-sync still keeps up to ${hist:-3} finished runs with no expiry: it will fill the quota again"
  exit 1
fi
echo "✅ price-sync is scheduled and its finished pods are bounded"

# 3. the service itself
if [ "$(k get deploy catalog-web -o jsonpath='{.spec.replicas}' 2>/dev/null)" != "3" ]; then
  echo "❌ Deployment catalog-web must exist with 3 replicas"
  exit 1
fi
if ! k wait --for=condition=Available deploy/catalog-web --timeout=45s >/dev/null 2>&1 \
   || [ "$(k get deploy catalog-web -o jsonpath='{.status.readyReplicas}')" != "3" ]; then
  ready=$(k get deploy catalog-web -o jsonpath='{.status.readyReplicas}')
  used=$(k get quota object-counts -o jsonpath='{.status.used.count/pods}')
  echo "❌ catalog-web has ${ready:-0} of 3 pods Ready (namespace counts ${used:-?} of 10 pods)"
  exit 1
fi
used=$(k get quota object-counts -o jsonpath='{.status.used.count/pods}')
echo "✅ catalog-web: 3 of 3 pods Ready; the namespace counts $used of 10 pods"
exit 0
exit 1
