**Raising the quota.** `count/configmaps: 100` was set on purpose, and the validator checks it is unchanged. A bigger limit lets the leak run for longer and puts more objects into the API server's datastore.

**Deleting every ConfigMap with `app=exporter`.** It frees the quota instantly, but one of those ConfigMaps, `export-result-0042`, is mounted by billing-web. The running pod survives, the next restart fails with a missing volume, and the validator reports the missing ConfigMap. Check what pods mount before you delete.

**Cleaning up once and stopping.** After the manual delete the bot works again, but the exporter keeps adding a ConfigMap every run. In a few weeks the namespace is full again. Run the CronJob by hand twice and watch the count.

**Pointing the cleanup selector at `app=exporter` without protecting the mounted one.** That does fix the mismatch, but the exporter's own cleanup would then delete `export-result-0042` on its next run. Either label the new results differently, or remove the label from the ConfigMap that billing-web needs.
