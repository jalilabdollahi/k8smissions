**What was broken.** A release changed four things in four places and each hid behind another: the ServiceAccount named by the Deployment was never created, the PVC used a StorageClass that does not exist, the migration Job was started with a schema argument the script does not know, and the Ingress asked for a Service port name the Service does not have. The 503 at the edge was only the last of them.

**The evidence.** `describe rs` showed `error creating: pods "shop-web-..." is forbidden: error looking up service account k8smissions/shop-runner: serviceaccount "shop-runner" not found`. After that, pods sat in `Init:0/1`; `describe pvc` reported `storageclass ... "fast-ssd" not found`, and the Job pod's log said `unknown schema 'v9' (known: v6 v7)`. The ingress controller log said the Service has no port named `http`.

**Why Kubernetes behaved this way.** ServiceAccount admission runs when the ReplicaSet creates a pod, so a missing account means no pod object and nothing to describe. `storageClassName` is immutable, and a claim in use by a pod is protected from deletion, so the Job had to go first. A Job's pod template is immutable too. The Ingress is validated against nothing at apply time; the controller only discovers the bad port when it builds its upstream, and answers 503.

**The fix.** Create the account, re-create the claim with an existing class, re-run the migration with the right schema, and point the Ingress at the Service's real port. The order matters because the migration needs the volume and the pods need the migration.

**In production.** Check dependencies before a release (`kubectl auth`, `get sc`, dry-run), set migration Jobs up as a pre-deploy step with a visible status, and test the Ingress against a staging Service.

**Commands to remember.** `kubectl describe rs`, `kubectl get sc`, `kubectl logs <pod> -c <init-container>`, `kubectl get job <name> -o yaml`.
