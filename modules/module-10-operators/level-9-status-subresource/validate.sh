#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }
B=backups.backup.acme.io

sub=$(kubectl get crd $B -o jsonpath='{.spec.versions[0].subresources.status}' 2>/dev/null)
if [ -z "$sub" ]; then
  echo "❌ the Backup API has no status subresource"
  exit 1
fi
echo "✅ the Backup API has a status subresource"

ready=$(k get deploy backup-operator -o jsonpath='{.status.readyReplicas}' 2>/dev/null)
if [ "${ready:-0}" -lt 1 ]; then
  echo "❌ backup-operator has no Ready pod"
  exit 1
fi

k delete job sla-probe --ignore-not-found >/dev/null 2>&1
k delete backup probe-bk --ignore-not-found >/dev/null 2>&1
k apply -f - >/dev/null <<'Y'
apiVersion: backup.acme.io/v1
kind: Backup
metadata: {name: probe-bk}
spec: {target: probe, retention: 1d}
Y
fail=0
phase=""
for i in $(seq 1 10); do
  phase=$(k get backup probe-bk -o jsonpath='{.status.phase}' 2>/dev/null)
  [ -n "$phase" ] && break
  sleep 2
done
if [ -z "$phase" ]; then
  echo "❌ backup-operator did not write a status.phase on a new Backup"
  fail=1
fi
for b in orders-db ledger-db audit-db; do
  p=$(k get backup "$b" -o jsonpath='{.status.phase}' 2>/dev/null)
  [ -n "$p" ] || { echo "❌ Backup $b has no status.phase"; fail=1; }
done
[ "$fail" = 0 ] && echo "✅ backup-operator writes status.phase"

# run the reporter once, the way the CronJob would
t0=$(date -u +%Y-%m-%dT%H:%M:%SZ)
sleep 1
if ! k create job sla-probe --from=cronjob/sla-reporter >/dev/null 2>&1; then
  echo "❌ cannot run a job from CronJob sla-reporter (is it still there?)"
  k delete backup probe-bk --ignore-not-found --wait=false >/dev/null 2>&1
  exit 1
fi
if ! k wait --for=condition=complete job/sla-probe --timeout=45s >/dev/null 2>&1; then
  echo "❌ a run of sla-reporter did not complete"
  fail=1
fi
for b in orders-db ledger-db audit-db probe-bk; do
  seen=$(k get backup "$b" -o jsonpath='{.status.lastSlaCheck}' 2>/dev/null)
  if [ -z "$seen" ] || [[ "$seen" < "$t0" ]]; then
    echo "❌ Backup $b: lastSlaCheck is '${seen:-empty}', the reporter's run did not land"
    fail=1
  fi
done
gen=$(k get backup probe-bk -o jsonpath='{.metadata.generation}' 2>/dev/null)
if [ "$gen" != 1 ]; then
  echo "❌ status writes changed metadata.generation of a Backup (now ${gen:-?})"
  fail=1
fi
k delete job sla-probe --ignore-not-found --wait=false >/dev/null 2>&1
k delete backup probe-bk --ignore-not-found --wait=false >/dev/null 2>&1
[ "$fail" = 0 ] || exit 1
echo "✅ sla-reporter's lastSlaCheck lands and generation stays put"
exit 0
exit 1
