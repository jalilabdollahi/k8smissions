**Chasing the node clock.** Cordoning nodes or looking for NTP problems wastes the window: every pod on a kind node shares the same kernel clock, and the `date` of the `api` pod matches reality. The difference is in the `auth` pod's environment.

**Setting an enormous leeway.** `LEEWAY_SECONDS=36000` would make the fresh-token requests pass and hides both the time zone and the short TTL, but then a token issued two hours ago is accepted, and the validator checks that it is still rejected. Leeway is for seconds of drift, not for hours.

**Fixing the time and calling it done.** After the zone and TTL are right, the error becomes `bad signature`. That is a different fault (a half-finished key rotation), and a Secret change is not seen by running pods: restart `api` after patching `api-verify`.
