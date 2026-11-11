**A longer `sleep`.** Raising 5 to 15 passes the 8-second case and the 12-second case, and then a slow day needs 20. Every run also pays the full wait even when the database is ready in two seconds. Retry instead of guessing.

**An endless `until` loop.** It handles every startup time, and the unreachable-database run then never ends: it stays Running until a timeout nobody set. Count attempts or compare against a deadline, and fail with a message.

**Reaching for the sidecar's readiness probe.** Tekton does not hold the first step until a sidecar is ready, so a readiness probe changes nothing about the race. The wait has to live in the step.
