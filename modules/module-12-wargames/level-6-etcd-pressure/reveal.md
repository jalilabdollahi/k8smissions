1. **Stale release Secrets.** 24 releases of about 330 KiB each; `status=superseded` revisions 1..23. Delete the old ones but keep `v24` (`status=deployed`) and `v23` (the previous release). A selector like `-l status=superseded` also removes `v23`: delete by name.
2. **Unlimited history in the deployer.** `MAX_REVISIONS=0` means "keep everything", so the pile grows again at every deploy. `kubectl set env cronjob/release-deployer MAX_REVISIONS=5` (any small number of at least 2).
3. **The syncer lists every Secret every 250 ms.** `kubectl set env deploy/config-syncer SYNC_INTERVAL_MS=10000` restarts it with a polite interval; with the small history its list calls now take a few milliseconds.

Pruning without fixing the syncer leaves the hammering; fixing the syncer without pruning leaves the payload and the next deploy adding to it.
