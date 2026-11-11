**Deleting the HPA.** The flapping stops because nothing scales any more, and the Deployment sits at 1 replica. The objective requires the HPA to remain and 3 or more replicas to hold.

**Turning off automated sync or self-heal.** It "stops the fight", but then real drift is no longer corrected, and the check requires self-heal to stay on. The goal is to settle who owns one field, not to switch Argo off.

**`ignoreDifferences` without `RespectIgnoreDifferences=true` (and no Git change).** The Application looks `Synced` and the flapping may stop, but the next sync caused by anything else (a new commit, a manual sync) applies `replicas: 1` again and the Deployment drops. The validation requests a fresh sync to catch exactly this.
