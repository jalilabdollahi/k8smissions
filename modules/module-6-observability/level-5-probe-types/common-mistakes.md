## Fixing only the container that is obviously restarting

Both containers have broken probes. Fixing `tcp-echo` leaves `ticker` failing, and the pod stays 1/2 Ready. Read the events per container.

## Using a probe that always passes

Replacing the worker's probe with `exec: ["true"]` makes the pod Ready, but a hung worker would never be detected. The check has to look at something the worker produces; the validator runs your command and expects the heartbeat file in it.

## Opening a port on the worker to keep httpGet

Adding a fake HTTP listener to the worker changes the application to satisfy a probe, and a listener that always answers 200 proves nothing. The validator rejects httpGet on both containers.
