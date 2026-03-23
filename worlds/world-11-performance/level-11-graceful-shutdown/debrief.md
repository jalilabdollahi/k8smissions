# In-Flight Request Drop

## What Was Broken
terminationGracePeriodSeconds: 5 is too short for an HTTP server. Kubernetes first sends SIGTERM, then sends SIGKILL after 5 seconds. Any long-running requests (file uploads, DB writes) were killed mid-operation.

## The Fix
Increase terminationGracePeriodSeconds to 60+ seconds. Add a preStop sleep of 10 seconds to allow kube-proxy to withdraw the pod from Service endpoints before the process receives SIGTERM.

## Why It Matters
Shutdown race condition: Kubernetes removes the pod from Service endpoints and sends SIGTERM at the same time — new requests can still arrive for a few seconds while shutdown begins. The preStop sleep solves this race.

## Pro Tip
Application-level graceful shutdown: configure the app to stop accepting new connections on SIGTERM, complete in-flight requests, then exit. Frameworks: nginx worker_shutdown_timeout, Gunicorn --graceful-timeout, Express graceful-http.

## Concepts
preStop hook, terminationGracePeriodSeconds, graceful shutdown, SIGTERM, SIGKILL, endpoint removal
