**Approving the gate by deleting it or making it always succeed.** The release then promotes without ever looking at the canary, and the broken-build rehearsal ships to stable. The gate has to be able to say no.

**Only adding the timeout.** A bounded gate fails instead of hanging, which is an improvement, but with the canary unreachable the healthy release also fails after the timeout. Fix the labels as well.

**Changing the Service selector to match the canary.** Pointing the Service at `app: checkout-canary` would drop stable traffic. The selector must keep matching stable pods and also reach the canary, so the canary pod gets the stable `app` label plus its own `track`.
