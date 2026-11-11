**Using `helm rollback`.** The release returns to the old image and the pods are healthy, but the objective is the new build. Rolling back is right when the new version is bad, not when the values are mistyped.

**Retrying with `--set image.tag=1.0`.** `--set` parses the value like YAML, so it is again the number one. Use `--set-string`, or quote it in the file.

**Trusting `helm get values`.** It prints `tag: 1`, which reads like a plausible value. Compare with `values-prod.yaml` and the rendered manifest.

**Reusing the old values with `--reuse-values`.** That keeps the stale values of the previous revision, including the old message, so the service would answer with the previous ranking.
