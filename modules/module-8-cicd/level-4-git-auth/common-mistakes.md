**Fixing only the annotation.** The Secret now matches the URL, but the next run still uses `default`, so the credentials are never mounted and the clone fails exactly as before. Check which ServiceAccount the new run actually has.

**Putting the password in the repository URL.** `http://ci-bot:...@gitserver...` makes the clone work, and leaks the password into the Pipeline, the pod spec and logs. The objective keeps the credentials in the `basic-auth` Secret.

**Recreating the Secret with another type.** Tekton recognises `kubernetes.io/basic-auth` and `kubernetes.io/ssh-auth` plus annotations; an `Opaque` Secret is ignored. The type was never the problem.
