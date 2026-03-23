# Common Mistakes — Ghost Patch

## Mistake 1: Ignoring silent no-match in Kustomize

**Wrong approach:** Assuming the patch applied because kubectl apply succeeded without errors

**Correct approach:** Verify with kubectl kustomize . | grep replicas or kubectl get deployment -o yaml

## Mistake 2: Fixing only the patch body and not the target

**Wrong approach:** Changing metadata.name in the patch but leaving target.name wrong — still no match

**Correct approach:** Both the patch body name AND the target.name selector must be corrected
