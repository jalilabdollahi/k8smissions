# Common Mistakes — Time Drift

## ❌ Restarting pods
JWT validation happens at the network level — restarting pods doesn't help if the clock is wrong.

## ❌ Ignoring NTP configuration
Always ensure all nodes sync to the same NTP server pool.
