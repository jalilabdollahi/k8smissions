1. `kubectl logs welcome-page` prints `welcome to acme` and the pod's container exited with code 0: it ran `echo`, not nginx.
2. The manifest has `command: ["echo", "welcome to acme"]`, which replaces the image's ENTRYPOINT.
3. A pod's `command` cannot be edited in place, so delete the pod and recreate it from the same manifest without the `command` line.
4. Wait for it to be Ready; Service `welcome-page` then has an endpoint and serves nginx.
