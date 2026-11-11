## What was broken

`thumbnailer` builds a 150 MiB image cache when it starts. Its container had `limits.memory: 64Mi`, so the kernel's OOM killer ended the process before start-up finished, over and over. Each restart waited a little longer because of the back-off, which is why the Service flapped.

## The evidence

`kubectl describe pod` showed `Last State: Terminated`, `Reason: OOMKilled`, `Exit Code: 137` (128 + signal 9). The previous container's logs stopped right after `building image cache (150 MiB)`, with no error message, because a process that is killed cannot log anything. The limit in the pod spec was far below the number in the log line.

## Why Kubernetes behaved this way

Memory is not compressible. When a container tries to use more than its limit, the cgroup has nothing to reclaim and the kernel kills the process; the kubelet then restarts it according to `restartPolicy`. The memory request only influences scheduling, so raising it does not change the kill. CPU is different: over the limit it is merely throttled.

## The fix

Set a limit above the real use (the service needs about 160 MiB including the interpreter; 256Mi leaves headroom) and a request near what it normally uses. `kubectl set resources` changes the template and the Deployment rolls out new pods.

## In production

Size from measurement (`kubectl top pod`, a dashboard, a load test), not from a guess, and leave 20 to 30 percent headroom. Keep a limit; one pod without it can take down its neighbours. Module 6 covers telling OOM from other exit 137 causes.

## Commands worth remembering

- `kubectl describe pod <pod>` (Last State)
- `kubectl logs <pod> --previous`
- `kubectl set resources deployment <name> --limits=memory=<size>`
