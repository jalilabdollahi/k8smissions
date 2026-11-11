The operator copies an `ownerReferences` entry with a hard-coded `uid` onto the Deployment and the ConfigMap of every Site, and sets none on the Service:

- Deployment and ConfigMap: the garbage collector looks up the owner `Site/<name>`, finds an object with a different uid, treats the owner as gone and deletes the child. The operator then recreates it and the cycle repeats.
- Service: no owner at all, so deleting the Site never collects it (and `site-legacy` has been orphaned since its Site was deleted).

Fix `controller.py` in ConfigMap `site-operator-code`: use `site["metadata"]["uid"]` in `owner()` and attach the reference to all three children (also repairing children that already exist), then restart the operator and delete the orphan:

```bash
kubectl -n k8smissions edit configmap site-operator-code
kubectl -n k8smissions rollout restart deploy/site-operator
kubectl -n k8smissions delete svc site-legacy
```
