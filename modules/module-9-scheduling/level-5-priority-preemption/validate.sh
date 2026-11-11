#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

sb=$(k get deploy dev-sandbox -o jsonpath='{.spec.replicas}' 2>/dev/null)
if [ "${sb:-0}" -ne 8 ]; then
  echo "❌ Deployment dev-sandbox must keep its 8 replicas (found ${sb:-none})"
  exit 1
fi
pay=$(k get pods -l app=pay-gateway -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null)]')
if [ "$(echo "$pay" | jq length)" -ne 2 ] || [ "$(echo "$pay" | jq '[.[] | select(.status.phase=="Running")] | length')" -ne 2 ]; then
  echo "❌ pay-gateway: $(echo "$pay" | jq '[.[] | select(.status.phase=="Running")] | length') of 2 pods Running"
  exit 1
fi
echo "✅ both pay-gateway pods are Running"

pay_prio=$(echo "$pay" | jq '[.[].spec.priority] | min')
sb_prio=$(k get pods -l app=dev-sandbox -o json | jq '[.items[].spec.priority] | max')
if [ "${sb_prio:-0}" -ge "${pay_prio:-0}" ]; then
  echo "❌ dev-sandbox pods (priority $sb_prio) do not rank below pay-gateway pods (priority $pay_prio)"
  exit 1
fi
if [ "$(echo "$pay" | jq '[.[] | select(.spec.preemptionPolicy=="Never")] | length')" -ne 0 ]; then
  echo "❌ pay-gateway pods are still not allowed to preempt: they only ran because room was made by hand"
  exit 1
fi
echo "✅ pay-gateway outranks dev-sandbox and is allowed to preempt it"

running=$(k get pods -l app=dev-sandbox -o json | jq '[.items[] | select(.metadata.deletionTimestamp==null) | select(.status.phase=="Running")] | length')
events=$(k get events --field-selector reason=Preempted -o name 2>/dev/null | wc -l | tr -d ' ')
if [ "$running" -ge 8 ] && [ "$events" -eq 0 ]; then
  echo "❌ no dev-sandbox pod was displaced to make room"
  exit 1
fi
echo "✅ dev-sandbox gave up room: $running of 8 sandbox pods still run"
exit 0
exit 1
