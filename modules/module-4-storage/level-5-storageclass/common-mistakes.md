# Common mistakes: level 5

**Editing the claim's storageClassName in place.** The field is immutable on an existing PVC: the API server refuses the change. Either create the class the claim wants or delete and recreate the claim.

**Creating the class with a provisioner copied from a cloud manifest.** `kubernetes.io/aws-ebs` or `ebs.csi.aws.com` are accepted as text, but nothing in kind watches them, so the claim stays Pending with `waiting for a volume to be created by external provisioner`. Look at `kubectl get sc standard -o yaml` and reuse its provisioner.

**Deleting the pod or Deployment hoping it recovers.** The new pod references the same unbound claim and stays Pending. The claim is the object to fix, and nothing needs to be restarted once it binds.
