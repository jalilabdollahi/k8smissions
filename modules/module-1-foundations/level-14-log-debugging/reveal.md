1. `kubectl logs <pod> --previous | grep ERROR` prints `rates.conf line 7: invalid refresh_interval '5min'`. The value must look like `5m` or `300s`.
2. Fix line 7 in ConfigMap `rates-sync-conf` (`refresh_interval = 5m`) and delete the pods so they re-read the file.
3. The next start stops at the second fault: `line 12: unknown region 'eu-west-9' (allowed: eu-west-1, eu-central-1)`. Change it to an allowed region such as `eu-central-1`.
4. Delete the pods again; the log shows `rates loaded: 2 regions` and the Service serves the JSON.
