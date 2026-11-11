**What was broken.** The production values file said `tag: 1.0`. In YAML that is the floating-point number one, not the text "1.0". Helm passes the number to the template, which prints it as `1`, so the Deployment asked for `hashicorp/http-echo:1`, a tag that does not exist. The upgrade itself succeeded, because Helm only renders and applies; the failure appears when kubelet tries to pull. The rolling update kept the old pods up, which is why the service kept answering with the old ranking.

**The evidence.** `kubectl describe pod` shows the pulled image, and `helm get manifest` the rendered one. `helm get values` prints `tag: 1`, which looks harmless at a glance, so the comparison with the file is what reveals it.

**Why Helm behaves this way.** Values are parsed as YAML into typed data. Strings that look like numbers (`1.0`, `1.30`, `0123`, `yes`, `1e3`) become numbers or booleans unless quoted, and are formatted by the number's rules when they are put back into text.

**The fix.** Quote the tag, or use `--set-string` on the command line. `--set` parses its value the same way as YAML.

**In production.** Always quote image tags and version strings in values files, run `helm template` or `helm lint --strict` in CI, and prefer immutable full tags (`1.0.3`) or digests, which are not numbers.

**Commands worth remembering.**
- `helm template RELEASE CHART -f FILE | grep image:`
- `helm get manifest RELEASE` and `helm get values RELEASE --all`
- `helm upgrade RELEASE CHART -f FILE --set-string key=value`
