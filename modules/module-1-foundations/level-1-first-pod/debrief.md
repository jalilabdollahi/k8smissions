## What was broken

Pod `welcome-page` was created from a tutorial snippet that carried `command: ["echo", "welcome to acme"]`. That field replaces the image's own ENTRYPOINT, so the container ran `echo`, printed one line, and exited with code 0. nginx never started, nothing listened on port 80, and the Service had no ready endpoint.

## The evidence

`kubectl get pod` showed `Completed` and then `CrashLoopBackOff`. `kubectl logs welcome-page` printed just `welcome to acme`, and `describe pod` showed `Terminated`, reason `Completed`, exit code 0. A web server should never finish; an exit code of 0 means the program you told it to run simply ended.

## Why Kubernetes behaved this way

The default `restartPolicy` of a pod is `Always`. Kubelet restarts any container that exits, even a successful one, with an exponential back-off (10s, 20s, 40s, up to 5 minutes). That is why a "successful" container ends up in `CrashLoopBackOff`.

## The fix

Remove the `command` override so the image's entrypoint runs. Most pod fields are immutable, so editing the running pod is rejected; delete it and apply the corrected manifest.

## In production

You almost never create bare Pods. A Deployment would have let you change the template and roll out. `command` and `args` are for when you really want a different program; use `args` alone to pass flags to the image's entrypoint.

## Commands worth remembering

- `kubectl logs <pod> --previous`
- `kubectl get pod <pod> -o jsonpath='{.status.containerStatuses[0].lastState}'`
- `kubectl explain pod.spec.containers.command`
