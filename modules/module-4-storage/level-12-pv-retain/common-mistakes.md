# Common mistakes: level 12

**Deleting the PV and recreating it.** With `Retain` the data is the whole point, and the PV object is the only record of where it is. A recreated object must describe the same backing directory exactly; if it does not, the ledger is unreachable. Clear the stale reservation instead.

**Changing the reclaim policy or the PVC.** The claim already asks for the right volume, and the policy is fine. The blocker is the old `claimRef` on the PV, which only a change to the PV removes.

**Recreating the namespace `billing-v1`.** A claim with the old name and UID would have to exist again; a claim with the same name is a different object with a different UID, so the volume still will not rebind. And the service now lives in `k8smissions`.
