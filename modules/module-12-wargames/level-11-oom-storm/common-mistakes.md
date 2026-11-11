**Only raising the limits.** Giving all three 256Mi stops the kills and hides the real defect: the cache is oversized by design of the new default and the spool sits in RAM. It is accepted only if the cache really fits, but it triples the memory reservation of three services for no reason.

**Editing `lib-defaults` and waiting.** The pods keep their old environment until the container restarts. A crash-looping pod may pick the new value up on its next restart, but a healthy-looking one will not: `kubectl rollout restart` the consumers, and check `/work` for the cache size actually in use.

**Stopping after the shared cache.** `svc-alpha` and `svc-beta` calm down and the incident feels over, but `svc-gamma` keeps dying and its heap looks normal. Whatever it writes into a `Memory` volume counts against the same limit.
