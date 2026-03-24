# Common Mistakes — Frozen Rollout

## Mistake 1: Deleting replicas hoping new ones replace them

**Wrong approach:** Deleting pods — since spec.paused, the controller still won't roll out the new template

**Correct approach:** Resume the deployment; then the controller triggers a fresh rollout

## Mistake 2: Assuming rollout is stuck due to image pull

**Wrong approach:** Checking image pull logs when the real issue is paused spec

**Correct approach:** Always check kubectl get deployment -o yaml for spec.paused first
