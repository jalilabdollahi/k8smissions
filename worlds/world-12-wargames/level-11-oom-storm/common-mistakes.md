# Common Mistakes — Memory Wave

## ❌ Setting limits equal to requests
This creates Guaranteed QoS but removes all burst capacity — any temporary spike causes an OOM kill.

## ❌ Fixing one deployment and not the others
When multiple services OOM simultaneously, fix them all.
