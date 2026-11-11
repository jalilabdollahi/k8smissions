1. `kubectl kustomize overlays/prod` shows `replicas: 1` and `http-echo:0.2.3`: nothing in the overlay took effect.
2. The patch targets `payments-gateway`, but the Deployment in the base is named `payments` (`payments-gateway` is the container). Change `target.name` to `payments`.
3. `images[].name: http-echo` does not match the base image `hashicorp/http-echo`; set `name: hashicorp/http-echo` with `newTag: "1.0"`.
4. Re-render to confirm 4 replicas and the 1.0 tag, commit and push the overlay, then `kubectl apply -n k8smissions -k overlays/prod` and wait for the rollout.
