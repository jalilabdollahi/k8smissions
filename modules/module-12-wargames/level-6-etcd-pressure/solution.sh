#!/bin/bash
NS=k8smissions
# delete the superseded releases except the newest one (the "previous" release)
kubectl -n $NS get secrets -l owner=release-deployer,app=shop,status=superseded \
  -o jsonpath='{range .items[*]}{.metadata.labels.revision}{" "}{.metadata.name}{"\n"}{end}' \
  | sort -n | sed '$d' | awk '{print $2}' | xargs kubectl -n $NS delete secret
# bound the history and slow the syncer down
kubectl -n $NS set env cronjob/release-deployer MAX_REVISIONS=5
kubectl -n $NS set env deploy/config-syncer SYNC_INTERVAL_MS=10000
kubectl -n $NS rollout status deploy/config-syncer --timeout=90s
sleep 12
