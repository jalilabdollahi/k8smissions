**Only tightening liveness.** A short liveness probe still sends traffic to the wedged pod until it restarts, and each failed attempt costs a full client timeout. Detection by restart takes 10 to 20 seconds at best; readiness is what takes the pod out of the Service in 2.

**Setting failureThreshold: 1 on liveness.** It reacts fastest, but the application has a slow answer one time in eight, so healthy pods get restarted: the validator checks that none of the healthy pods restart.

**Probing a path that never fails.** A readiness probe on a path served by a different, unaffected thread passes while real requests hang. Probe something that shares the failure with the real traffic.
