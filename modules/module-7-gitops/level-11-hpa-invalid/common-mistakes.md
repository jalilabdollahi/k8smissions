**Changing the live HPA with `kubectl edit`.** The Application is out of sync and automated sync would put Git's state back, and the commit that holds the new image is still blocked. The repository is where the manifest is wrong.

**Fixing only the replica range and calling it done.** The Application may turn Synced, but the HPA still cannot find its target and never scales. The objective needs current metrics on the HPA.

**Deleting the HPA from Git.** The sync then goes through and the image rolls out, but the workload no longer autoscales. The HPA has to stay, valid and active.

**Waiting for the three minute poll.** Argo checks Git every three minutes. A `refresh=hard` annotation makes it look now.
