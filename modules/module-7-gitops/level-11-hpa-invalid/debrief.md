**What was broken.** One commit changed the image and the HPA. The HPA had `minReplicas: 8` above `maxReplicas: 4`, which the API server refuses. Argo CD applies all resources of a sync together after a dry run, so the invalid HPA blocked the whole commit and the new image never rolled out, while the old pods kept serving. A second mistake was hiding behind the first: the HPA's `scaleTargetRef.name` was `reports-api`, but the Deployment is called `reports`. Once the range was valid, the HPA was created and could not find anything to scale.

**The evidence.** `operationState.message` names the failing resource and the validation rule. After the first fix, `kubectl describe hpa` shows `AbleToScale` and `ScalingActive` conditions with `FailedGetScale` and the missing name.

**Why Kubernetes behaved that way.** HPA validation is done by the API server on every write, so it is a sync failure and not a runtime one. The scale target is looked up by name at runtime, not at admission, so a wrong name is accepted and just never works.

**The fix.** A valid range in the manifest, and the right target name, both through a Git commit, so the Application can reach the new head.

**In production.** Run `kubectl apply --dry-run=server` or a CI check on rendered manifests, so an invalid object fails in the pull request and not in the deploy. Alert on HPA conditions, not only on the Application status.

**Commands worth remembering.**
- `kubectl explain hpa.spec.scaleTargetRef`
- `kubectl describe hpa NAME` and `kubectl get hpa`
- `kubectl -n argocd get app NAME -o jsonpath='{.status.operationState.syncResult.resources}'`
