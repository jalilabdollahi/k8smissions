# Debrief: the archive that looked fine and was empty

**What was broken.** Static PV `archive-2023` carries last year's files and the class `archive`. The claim `archive` did not set `storageClassName`, so Kubernetes applied the default class, `standard`, and dynamically created an empty volume. The claim was Bound, the pod Ready, and the directory listing was empty: every status was green and the data was somewhere else.

**The evidence.** `kubectl get pv,pvc` shows the claim bound to a generated `pvc-<uid>` volume while `archive-2023` sits `Available` next to it. `kubectl get pv archive-2023 -o yaml` shows its `storageClassName: archive`; the claim shows the class `standard` the API server filled in.

**Why Kubernetes behaves this way.** The default class is applied at admission when a claim omits the field, and binding only considers volumes whose class equals the claim's. Binding is silent about alternatives: a claim that finds a provisioner never looks at static volumes of other classes. `spec.storageClassName` on a PVC is immutable, so a wrong value cannot be edited.

**The fix.** Stop the workload so the claim is not in use, delete the claim (the stray dynamic volume is reclaimed with it) and recreate it with `storageClassName: archive`. The static PV then binds, because the class, access mode and size fit. The volume was never deleted, which would have lost the pointer to the data.

**In production.** Be explicit with `storageClassName` in manifests; use `""` for "static volumes only". Pre-provisioned volumes also need `volumeName` or a unique class so that they cannot be taken by the wrong claim.

**Commands worth remembering**
- `kubectl get pv,pvc -A`: compare claim to volume names and classes.
- `kubectl get sc`: which class is `(default)`.
- `kubectl explain pvc.spec.storageClassName`
