#!/bin/bash
NS=${NS:-k8smissions}
. ../_fixtures/lib.sh
fail=0
kubectl wait pod/kv-client pod/intruder -n "$NS" --for=condition=Ready --timeout=40s >/dev/null 2>&1 || { bad "kv-client and intruder pods must be Running"; exit 1; }
cl()  { kubectl exec -n "$NS" kv-client -- curl -s --max-time 5 "$@" 2>/dev/null; }
intr() { kubectl exec -n "$NS" intruder -- curl -s --max-time 3 "$@" 2>/dev/null; }

want=$(kubectl -n "$NS" get sts kv -o jsonpath='{.spec.replicas}' 2>/dev/null)
n=$(ready_count app=kv)
if [ "${want:-0}" = 3 ] && [ "${n:-0}" = 3 ]; then ok "kv: 3 of 3 members Ready"; else bad "kv: ${n:-0} of ${want:-?} members Ready (need 3)"; fail=1; fi

ips=$(kubectl -n "$NS" get pods -l app=kv -o jsonpath='{range .items[*]}{.status.podIP}{" "}{end}' 2>/dev/null)
for ip in $ips; do
  q=$(cl "http://$ip:8080/status" | jq -r '.quorum' 2>/dev/null)
  if [ "$q" = true ]; then ok "member $ip reports quorum"; else bad "member $ip reports no quorum"; fail=1; fi
done
[ "$fail" = 0 ] || exit 1

key="order-$RANDOM"; val="v$RANDOM$RANDOM"
code=$(cl -o /dev/null -w '%{http_code}' "http://kv/put?k=$key&v=$val")
if [ "$code" = 200 ]; then ok "write through Service kv accepted"; else bad "write through Service kv returned ${code:-no answer}"; fail=1; fi
sleep 1
for ip in $ips; do
  got=$(cl "http://$ip:8080/get?k=$key")
  if [ "$got" = "$val" ]; then ok "member $ip has the value"; else bad "member $ip does not have the written value (got: ${got:-nothing})"; fail=1; fi
done

# isolation must survive the fix
leak=0
for ip in $ips; do
  [ -n "$(intr "http://$ip:8080/status")" ] && leak=1
  [ -n "$(intr "http://$ip:9000/ping")" ] && leak=1
  [ -n "$(cl "http://$ip:9000/ping")" ] && leak=2
done
case $leak in
  0) ok "intruder cannot reach any member; kv-client cannot reach the peer port";;
  1) bad "the intruder pod can reach the kv members"; fail=1;;
  *) bad "kv-client can reach the peer port, which is for members only"; fail=1;;
esac

[ "$fail" = 0 ] && exit 0
exit 1
