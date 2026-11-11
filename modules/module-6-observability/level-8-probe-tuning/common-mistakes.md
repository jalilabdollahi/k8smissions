## Raising failureThreshold instead of timeoutSeconds

The probes fail on every attempt, not occasionally. A higher threshold only delays the restart, and the readiness probe still never succeeds, so the pods are not Ready. The timeout is the field that matches the symptom.

## Stopping the load generator

The pods then look healthy, but the incident is that real traffic arrives at this rate. The validator requires `search-load` to keep running with both replicas.

## Removing the probes

The flapping stops, but a hung server would never be restarted and an overloaded pod would keep receiving traffic. Both probes must stay, with a timeout of 30 seconds or less.
