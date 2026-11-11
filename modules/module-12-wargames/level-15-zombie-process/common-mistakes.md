**Adding only probes.** The wedged pod is restarted and the incident seems closed, but the leak is still there: every pod wedges again after a minute or so, and the validator counts zombies under traffic. Probes are a safety net, not a repair.

**Fixing only the reaping.** The zombies disappear and the next wedge, whatever its cause, again goes unnoticed: nothing removes the pod from the Service or restarts it. The validator injects a wedge on purpose.

**Probes that are too lazy.** A liveness probe with a 30 second period and five failures takes minutes to react, and a readiness probe with a long period keeps sending traffic to the stuck pod. Keep the detection time short enough that the Service recovers within the window.
