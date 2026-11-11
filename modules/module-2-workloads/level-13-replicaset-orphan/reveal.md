1. `kubectl -n k8smissions get rs -o custom-columns=NAME:.metadata.name,OWNER:.metadata.ownerReferences[*].kind` shows `checkout-v1-<hash>` with no owner, next to the ReplicaSet owned by Deployment `checkout`.
2. Its pods still match Service `checkout` (`app=checkout`) and the ReplicaSet recreates any pod you delete.
3. `kubectl -n k8smissions delete rs <the ownerless checkout-v1 ReplicaSet>` deletes the ReplicaSet and, by default cascade, its three pods.
4. All traffic to Service `checkout` now reaches the three `v2` pods of the Deployment.
