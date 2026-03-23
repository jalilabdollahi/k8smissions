# Common Mistakes — Capability Gap

## Mistake 1: Removing drop: ALL instead of adding the capability

**Wrong approach:** Removing capabilities.drop to make the pod work — this gives the container full capabilities

**Correct approach:** Keep drop: ALL and selectively add only what is needed

## Mistake 2: Using privileged: true for port binding

**Wrong approach:** Setting privileged: true gives all root capabilities — far more than needed for port binding

**Correct approach:** Use capabilities.add: [NET_BIND_SERVICE] which is the minimal privilege needed
