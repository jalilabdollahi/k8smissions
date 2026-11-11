**What was broken.** Two controllers wrote the same field. The HPA keeps `minReplicas: 3` by setting `spec.replicas` on the Deployment; Argo CD, with automated sync and self-heal, treats that as drift from the `replicas: 1` in Git and syncs it back. Each correction triggered the other, so the replica set went 1 to 3 to 1 all day, the Application flickered `OutOfSync`, and pods were created and killed during traffic.

**The evidence.** The ReplicaSet scale events alternate with the HPA's `SuccessfulRescale` events, and the Application's diff contains only `/spec/replicas`.

**Why it behaves this way.** Self-heal is Argo's job: any difference between live state and Git on a managed field is reverted. The HPA is a controller whose entire job is to write `spec.replicas`. Neither is misbehaving; the field has two owners.

**The fix.** Give the field to one owner. The usual answer is the HPA: add `ignoreDifferences` for `/spec/replicas` on the Deployment so Argo does not see the drift, and `RespectIgnoreDifferences=true` so that a sync triggered by some other change does not apply Git's `1` either. Removing `replicas` from the manifest is the other clean option (the first sync after removal resets to the default of 1 once, then the HPA takes over).

**In production.** Never keep `replicas` in Git for an autoscaled workload, and do not delete the HPA to quiet an alert. Keep self-heal on, so real drift (manual edits) is still reverted.

**Commands worth remembering.**
- `kubectl describe hpa NAME` and `kubectl get rs -l app=NAME`
- `kubectl get app NAME -n argocd -o yaml` (look at `status.resources` and conditions)
- `kubectl explain application.spec.ignoreDifferences`
