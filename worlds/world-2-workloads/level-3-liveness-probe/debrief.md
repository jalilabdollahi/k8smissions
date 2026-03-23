# The Restart Loop

## Situation
Pods keep restarting. Liveness probe hits /healthz but the app only exposes /health (path mismatch).

## Successful Fix
Change path to /health

## What To Validate
Pods Running, RESTARTS count not increasing

## Why It Matters
When liveness kills vs when it should, probe tuning strategy

## Concepts
livenessProbe, httpGet, tcpSocket, exec, initialDelaySeconds, periodSeconds, failureThreshold
