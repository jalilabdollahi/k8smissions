# Common mistakes: level 9

**Looking for the policy on the PVC.** `kubectl edit pvc ledger-data` has no reclaim field. The policy belongs to the PV, and the claim only references it by name.

**Editing the StorageClass `standard`.** `reclaimPolicy` on a class is only read when a volume is provisioned, so existing PVs do not change, and the class is shared by every other workload in the cluster. Patch the PV that already exists.

**Setting Retain on every PV.** It protects the ledger, but the disposable scratch volume would then outlive its claim forever and leak disk space. The task is the volume behind `ledger-data` only; check the CLAIM column before patching.
