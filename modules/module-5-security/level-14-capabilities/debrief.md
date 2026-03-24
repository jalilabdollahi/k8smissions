# Capability Gap

## What Was Broken
The container dropped ALL Linux capabilities. Binding ports below 1024 requires `NET_BIND_SERVICE`. Without it, even a non-root user running `nc -l -p 80` gets permission denied.

## The Fix
Add `NET_BIND_SERVICE` to `capabilities.add` while keeping `drop: ALL`. This grants only the specific privilege needed, not full root.

## Why It Matters
Linux capabilities are the fine-grained alternative to running as root. The principle is: drop everything (capabilities.drop: ALL), then add back only what's needed. Common additions: NET_BIND_SERVICE (port binding), CHOWN (change file ownership), NET_ADMIN (networking).

## Pro Tip
Prefer listening on ports > 1024 (e.g., 8080) and using a Service with port 80→8080 mapping. This avoids needing NET_BIND_SERVICE entirely, which is a better security posture.

## Concepts
capabilities, NET_BIND_SERVICE, drop ALL, Linux capabilities, privileged ports
