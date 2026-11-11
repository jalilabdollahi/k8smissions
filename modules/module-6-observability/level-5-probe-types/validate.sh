#!/bin/bash
NS=${NS:-k8smissions}
k() { kubectl -n "$NS" "$@"; }

pods=$(../_fixtures/live-pods.sh app=settlement-gateway)
if [ "$(echo "$pods" | grep -c .)" -ne 1 ]; then
  echo "❌ expected exactly one live settlement-gateway pod"
  exit 1
fi
pod=$pods

# Probe design: inspect what each container's probes actually are.
python3 - "$NS" "$pod" <<'PY'
import json, subprocess, sys
ns, pod = sys.argv[1:3]
spec = json.loads(subprocess.check_output(["kubectl", "-n", ns, "get", "pod", pod, "-o", "json"]))["spec"]
cs = {c["name"]: c for c in spec["containers"]}
bad = []
for name in ("tcp-echo", "ticker"):
    c = cs.get(name)
    if not c:
        bad.append("container %s is missing" % name)
        continue
    for kind in ("livenessProbe", "readinessProbe"):
        p = c.get(kind)
        if not p:
            bad.append("%s has no %s" % (name, kind))
            continue
        if "httpGet" in p or "grpc" in p:
            bad.append("%s %s still speaks a protocol the container does not" % (name, kind))
        elif name == "tcp-echo" and "tcpSocket" not in p and "exec" not in p:
            bad.append("%s %s is not a usable check" % (name, kind))
        elif name == "ticker":
            cmd = " ".join(p.get("exec", {}).get("command", []))
            if "heartbeat" not in cmd:
                bad.append("ticker %s does not check what the worker produces" % kind)
            elif subprocess.call(["kubectl", "-n", ns, "exec", pod, "-c", "ticker", "--"] + p["exec"]["command"],
                                 stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL) != 0:
                bad.append("ticker %s command fails inside the container" % kind)
for b in bad:
    print("❌", b)
if bad:
    sys.exit(1)
print("✅ each container is probed in a way that fits what it is")
PY
[ $? -eq 0 ] || exit 1

age=$(../_fixtures/min-age.sh app=settlement-gateway)
if [ "${age:-0}" -lt 45 ]; then
  wait=$(( 45 - ${age:-0} ))
  echo "… pod is ${age:-0}s old, watching it for another ${wait}s"
  sleep "$wait"
fi
status=$(k get pod "$pod" -o jsonpath='{range .status.containerStatuses[*]}{.name}={.ready}/{.restartCount}{"\n"}{end}' 2>/dev/null)
if [ "$(echo "$status" | grep -c '=true/0$')" -ne 2 ]; then
  echo "❌ both containers must be Ready with no restarts:"
  echo "$status"
  exit 1
fi
echo "✅ both containers are Ready and have not restarted"

../_fixtures/ensure-probe.sh
ip=$(k get pod "$pod" -o jsonpath='{.status.podIP}')
out=$(k exec probe -- sh -c "echo PING | curl -s --max-time 3 telnet://$ip:7000" 2>/dev/null)
if [ "$out" != "PONG" ]; then
  echo "❌ tcp-echo does not answer PING on port 7000 (got: ${out:-nothing})"
  exit 1
fi
echo "✅ tcp-echo answers PING with PONG"
exit 0
exit 1
