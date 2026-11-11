`ledger-api` has `LOG_LEVEL=info` in lower case. The app only knows upper-case names, so it logs `unknown LOG_LEVEL 'info' ... using DEBUG` and writes a debug line 25 times a second. `ledger-batch` uses `INFO` and is quiet.

1. `kubectl logs -l tier=ledger --prefix --since=1m | awk '{print $1}' | sort | uniq -c` shows ledger-api pods with about 1500 lines each.
2. The first line of a ledger-api log is the warning about the unknown level.
3. `kubectl set env deploy/ledger-api LOG_LEVEL=INFO`, then wait for the rollout. `CRITICAL` would silence the noise too, but also hide the WARN and ERROR lines that operations needs.
