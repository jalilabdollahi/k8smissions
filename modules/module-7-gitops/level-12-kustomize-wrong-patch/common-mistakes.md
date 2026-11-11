**Scaling and setting the image with kubectl.** `kubectl scale` and `kubectl set image` make the cluster look right, but the overlay in the repository still renders 1 replica and the old tag, and the next apply undoes the change. The objective is about the overlay.

**Editing the base.** The base is shared with the staging overlay, which must keep rendering 2 replicas. Environment settings belong in the overlay.

**Fixing only one entry.** After the patch target is corrected the Deployment has 4 pods on the old image (or the reverse). Render the overlay again and look at both lines.

**Forgetting to apply.** Committing a correct overlay changes nothing in the cluster. Nothing here is automated, so run `kubectl apply -k`.
