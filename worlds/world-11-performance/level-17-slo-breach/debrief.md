# SLO Breach Alert

## What Was Broken
livenessProbe failureThreshold: 10 with periodSeconds: 10 = pod can be dead for 100 seconds before being restarted. During that 100-second window, the pod was responding to 1/3 of traffic with errors.

## The Fix
Reduce failureThreshold to 3 (standard recommendation). Pod death is detected in 30 seconds, not 100 seconds.

## Why It Matters
SLO math: 1.4% error rate / 100s window / 3 pods = roughly 1 pod dead for ~100s every hour. With failureThreshold: 3, detection is 30s per event — much smaller impact on the error budget.

## Pro Tip
SLO burn rate alerts: don't just alert on raw error rate. Calculate error budget burn rate. If you're burning error budget 14x faster than baseline (14x burn rate over 1 hour), page immediately.

## Concepts
SLO, liveness probe, failureThreshold, availability, error budget
