1. `kubectl describe pod` shows `Insufficient memory` on both workers; each worker has 1400Mi unallocated.
2. The pod runs in RuntimeClass `sandboxed`, which adds 700Mi of fixed overhead. The scheduler needs 900Mi + 700Mi = 1600Mi, more than the 1400Mi free.
3. The measured working set (ConfigMap `ledger-batch-sizing`) is 300Mi, so the 900Mi request is padding. Lower it so request + overhead fits (up to 700Mi):
   `kubectl -n k8smissions set resources deploy/ledger-batch --requests=memory=400Mi`
