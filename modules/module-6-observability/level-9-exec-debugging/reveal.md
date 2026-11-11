http-echo was started with `-listen=127.0.0.1:5678`, so it only accepts connections made from inside the pod. The Service sends traffic to the pod IP, where nothing listens.

1. `kubectl -n k8smissions debug <pod> -it --image=busybox:1.36 --target=echo` gives a shell next to the shell-less container; `netstat -ltn` shows `127.0.0.1:5678` and `wget -qO- localhost:5678` works.
2. Change the argument to `-listen=:5678` (all interfaces) in the Deployment: `kubectl patch deploy quote-api --type=json -p='[{"op":"replace","path":"/spec/template/spec/containers/0/args/0","value":"-listen=:5678"}]'`.
3. Wait for the rollout; the Service now answers.
