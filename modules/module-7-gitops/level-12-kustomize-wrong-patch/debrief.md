**What was broken.** The `prod` overlay contained two entries that matched nothing. A JSON patch set the replica count on a Deployment named `payments-gateway`, but the Deployment's name is `payments`; `payments-gateway` is only its container. The `images` entry used the short name `http-echo`, while kustomize compares the full image name, `hashicorp/http-echo`. Both were silently skipped, so the build succeeded, `kubectl apply` reported `configured` (labels changed) and the workload stayed at one old pod.

**The evidence.** The rendered output, not the exit code. `kubectl kustomize overlays/prod` printed `replicas: 1` and the old tag.

**Why it behaved that way.** Kustomize transformers select objects by matching; matching nothing is not an error for patches with a `target` and for `images`, because the same overlay is often reused with bases that do not contain every object. The `replicas` field is stricter (it fails when the name is unknown), which is why this overlay uses a patch.

**The fix.** Make the selectors match what the base declares, check the rendered output, commit the overlay, and apply it.

**In production.** Diff the rendered output in CI (`kubectl kustomize | kubectl diff -f -`) and assert on the fields that matter; a green build proves nothing about a transformer.

**Commands worth remembering.**
- `kubectl kustomize DIR | grep -E 'replicas|image:'`
- `kubectl diff -k DIR`
- `kubectl get deploy NAME -o jsonpath='{.spec.template.spec.containers[0].image}'`
