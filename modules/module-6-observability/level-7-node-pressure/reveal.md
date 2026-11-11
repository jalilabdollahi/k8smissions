The nodes are fine. Each `audit-spooler` pod writes 8 MiB segments to an emptyDir with `sizeLimit: 50Mi` and never deletes any (`SPOOL_KEEP=0`), so the kubelet evicts it once the directory passes 50Mi.

1. `kubectl -n k8smissions describe pod <evicted pod>` shows `Usage of EmptyDir volume "spool" exceeds the limit "50Mi"`; node Conditions are all False.
2. The startup log says retention is disabled. `kubectl -n k8smissions set env deploy/audit-spooler SPOOL_KEEP=3` keeps 24 MiB at most.
3. Optionally clean the leftovers: `kubectl -n k8smissions delete pod --field-selector=status.phase=Failed`.
