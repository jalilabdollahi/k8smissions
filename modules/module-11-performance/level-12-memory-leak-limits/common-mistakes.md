**Giving both services a bigger limit.** It fixes `render-svc`, and `profile-api` appears healthy for a few more minutes, but its memory still climbs at 2Mi per second and it dies later. Only a bound on the cache stops the growth; the validator checks the slope.

**Lowering `TEMPLATE_CACHE_MB` on render-svc.** The pod stops being OOMKilled because it now loads less, but `/render` answers 500: the data set is incomplete. Reducing the work is not a fix when the feature needs the whole data set.

**Reading one `kubectl top` right after a restart.** A fresh `profile-api` shows 15Mi and looks fine. A single sample cannot tell a leak from a plateau; take at least two, well apart.
