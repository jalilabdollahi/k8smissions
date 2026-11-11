**Fix**

1. `kubectl -n k8smissions get pdb` shows `ALLOWED DISRUPTIONS 0`; `describe pdb` shows 0 expected pods.
2. The PDB selects `app.kubernetes.io/name: concul`; the pods are labelled `app.kubernetes.io/name: consul`. The typo matches nothing.
3. `kubectl -n k8smissions patch pdb consul-pdb --type=merge -p '{"spec":{"selector":{"matchLabels":{"app.kubernetes.io/name":"consul"}}}}'`.
4. With `minAvailable: 2` and 3 healthy pods, `ALLOWED DISRUPTIONS` becomes 1: quorum is protected, one member can still be evicted.
