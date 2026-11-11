1. `kubectl -n k8smissions get pdb` shows `ledger-api-pdb` with `MIN AVAILABLE 2` and `ALLOWED DISRUPTIONS 0`; the Deployment only has 2 replicas.
2. A drain evicts pods through the eviction API, which honours the PDB, so the drain retries forever.
3. Make room for one pod: `kubectl -n k8smissions patch pdb ledger-api-pdb --type=merge -p '{"spec":{"minAvailable":1}}'`. Scaling `ledger-api` to 3 replicas while keeping `minAvailable: 2` is equally valid.
4. Drain again; pods are evicted one at a time and rescheduled on the other worker, and the Service keeps answering.
