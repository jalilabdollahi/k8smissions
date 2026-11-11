# Common mistakes: level 3

**Scaling down to one replica.** The pods stop being Pending, but the objective is three Ready replicas serving the content. The check also counts the Deployment's replicas, so this fails.

**Changing the claim to ReadWriteMany or adding more claims.** `accessModes` cannot be edited on an existing claim, and kind has no provisioner that offers RWX, so a new RWX claim stays Pending. One claim per replica starts empty and does not hold the catalogue files; the level requires exactly one claim, `site-content`.

**Pinning the pods with a nodeSelector or pod affinity and leaving the spread rule alone.** Putting the pods on the volume's node does not help while the spread constraint is a hard rule: it still forbids more than one replica there. The constraint is part of the problem.
