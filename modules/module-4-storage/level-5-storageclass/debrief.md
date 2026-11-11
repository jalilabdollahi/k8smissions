# Debrief: a StorageClass from another cloud

**What was broken.** The manifest was written for a cluster that has a StorageClass called `gp3`. This cluster does not, so the PersistentVolumeClaim referencing it could not be provisioned and stayed `Pending`, and the Deployment's pod could not start behind it.

**The evidence.** `kubectl describe pvc reports-data` ended with an event saying the storage class `gp3` was not found. `kubectl get storageclass` showed that the only class available was `standard`, which is the default and was never part of the story: a claim that names a class does not fall back to the default.

**Why Kubernetes behaves this way.** A StorageClass is the contract between a claim and a provisioner: its `provisioner` field says which controller creates volumes, `volumeBindingMode` when, and `reclaimPolicy` what happens at deletion. A claim with an explicit `storageClassName` waits for exactly that class; once it appears, the claim is retried on its own. `storageClassName` itself is immutable on a claim.

**The fix.** Create `gp3` using a provisioner that exists here (`rancher.io/local-path`, the one behind `standard`), or recreate the claim against `standard`. A class whose provisioner is not running, such as `kubernetes.io/aws-ebs`, would be accepted by the API but the claim would wait forever for an external provisioner.

**In production.** Keep class names consistent across clusters (or parameterise them in Helm), and check `kubectl get sc` before porting manifests. Watch the default class and the reclaim policy: they decide whether data survives claim deletion.

**Commands worth remembering**
- `kubectl get sc` and `kubectl get sc <name> -o yaml`
- `kubectl describe pvc <name>`: provisioning events.
- `kubectl explain storageclass.volumeBindingMode`
