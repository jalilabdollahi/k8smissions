# The Mixed Signals

## What Was Broken
The multi-port Service had two ports (80 and 443) but neither had a `name`. The Ingress referenced the backend by port name (`port.name: http`). Without named ports, the Ingress controller couldn't resolve which port `http` refers to.

## The Fix
Add `name:` fields to each port in the Service spec. The Ingress then resolves by name, and the reference becomes unambiguous.

## Why It Matters
Kubernetes requires port names on multi-port Services in two contexts: Ingress backends referencing a named port, and StatefulSet pod DNS records. Single-port Services don't need names but naming is good practice for readability.

## Pro Tip
Named ports also benefit readiness probes and liveness probes — use the port name instead of a number so probes remain correct if port numbers change.

## Concepts
Service, multi-port, named ports, Ingress, port name resolution
