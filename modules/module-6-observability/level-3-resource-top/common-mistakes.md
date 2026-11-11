## Limiting the container that looks big on the pod line

Pod-level `top` makes it tempting to put the limit on the container you recognise, usually `app`. That one is idle, the sidecar keeps burning a core, and the validator reads the quota from the `exporter` container.

## Deleting the pod or scaling the Deployment down

New pods start the same busy loop, and scaling down removes the service capacity that users need. The cause lives in the pod template.

## Setting a limit that is far too small

A limit below 50m starves the exporter, which then cannot do its work, so the level requires a limit that still lets the process run. Pick a value that caps the damage and keeps the sidecar usable.
