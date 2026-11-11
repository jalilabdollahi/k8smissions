# Reveal

`billing-pv` has `Retain`, so when the namespace `billing-v1` was deleted the PV stayed with its data, in phase `Released`, with `spec.claimRef` still pointing at the deleted claim `billing-v1/billing-data` (name, namespace and UID). A new claim, even one with the same name in another namespace, is refused: "volume already bound to a different claim".

1. See it: `kubectl describe pvc billing-data -n k8smissions` and `kubectl get pv billing-pv -o jsonpath='{.spec.claimRef}'`.
2. Clear the stale claimRef (do not delete the PV):

   ```bash
   kubectl patch pv billing-pv --type=merge -p '{"spec":{"claimRef":null}}'
   ```
3. The volume turns `Available`, the pre-bound claim binds it, and the Deployment's pod starts and serves `ledger-2024.db`.
