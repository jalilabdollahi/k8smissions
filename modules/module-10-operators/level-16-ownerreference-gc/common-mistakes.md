## Changing the constant to another uid

Hard-coding the uid of `storefront` fixes `storefront` and breaks `blog` and every Site created later. The uid is different for every Site and for every re-creation of the same name: it has to be read from the live object.

## Fixing the references and forgetting the orphan

`site-legacy` has no owner, so nothing will ever garbage-collect it, not even the corrected operator. Orphans made by the old code are removed by hand.

## Only adding an ownerReference to the Service

The Service then goes away with its Site, but the Deployment and ConfigMap are still collected and recreated every few seconds, and the validator watches their uids stay the same.
