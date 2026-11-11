The index is 180Mi of resident memory, loaded about 25 seconds after start. The 128Mi limit kills the process at that moment, which is why `kubectl top` looks harmless right after a restart.

1. Observe the real working set once the index is loaded (about 190Mi in `kubectl top pod --containers`).
2. `kubectl set resources deployment/search-indexer --requests=memory=224Mi --limits=memory=320Mi` sets a request near real use and a limit with headroom.
3. `kubectl scale deployment/search-indexer --replicas=3`: three pods of 224Mi/320Mi fit the 1Gi request and 2Gi limit quota (a generous 1Gi per pod would not).
4. Wait for the rollout; each pod needs about 25s to load before it is Ready.
