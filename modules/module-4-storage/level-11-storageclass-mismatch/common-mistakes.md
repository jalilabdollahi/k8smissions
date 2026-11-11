# Common mistakes: level 11

**Trusting `Bound` and `Running`.** Both are true on the wrong volume. The check that matters is which PV the claim is bound to, and what the pod actually sees at the mount.

**Patching `storageClassName` on the claim.** The API rejects it: the field is immutable once the claim exists. The claim has to be deleted and created again.

**Deleting the claim while the pod still uses it.** The claim then stays `Terminating` (protected by `kubernetes.io/pvc-protection`) until the pod is gone, and a new claim of the same name cannot be created. Scale the Deployment to 0 first.

**Deleting or recreating `archive-2023`.** The PV is the only pointer to the data. Leave it alone and change the claim instead.
