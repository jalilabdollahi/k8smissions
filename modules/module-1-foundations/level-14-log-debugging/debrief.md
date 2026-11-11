## What was broken

`rates-sync` reads `/etc/rates/rates.conf`, mounted from ConfigMap `rates-sync-conf`, and refuses to start on a bad value. Two values were wrong: `refresh_interval = 5min` (the program wants `5m` or `300s`) and `region = eu-west-9` (only `eu-west-1` and `eu-central-1` exist). The program stops at the first bad line, so the second error only appeared after the first was fixed.

## The evidence

Each run printed 40 harmless boot lines followed by one `ERROR` line with the file name and line number, then exited with code 2. `kubectl logs <pod> --previous | grep ERROR` cut straight to it. Matching the line number against `kubectl get configmap rates-sync-conf -o yaml` showed the value in place.

## Why Kubernetes behaved this way

A container that exits with a non-zero code is restarted with an increasing back-off. While the pod waits, `kubectl logs` may show an empty or fresh log, and `--previous` is the reliable way to read the run that failed. The kubelet refreshes ConfigMap volumes in place after a delay of up to a minute, but the program reads its file only once, at start, so a restart is what applies a fix.

## The fix

Correct both lines in the ConfigMap, then delete the pods (or run `kubectl rollout restart deployment/rates-sync`) so they start with the new file and a clean back-off.

## In production

Make applications print the first error last, or on stderr, and validate configuration before rolling it out (a dry-run Job or a CI check). One fault at a time is common: after any fix, run the log check again before declaring victory.

## Commands worth remembering

- `kubectl logs <pod> --previous | grep -i error`
- `kubectl get configmap <name> -o jsonpath='{.data.rates\.conf}' | cat -n`
- `kubectl rollout restart deployment/<name>`
