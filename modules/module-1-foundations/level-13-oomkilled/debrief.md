# Out of Memory

## Situation
Pod keeps restarting with exit code 137 (OOMKilled). Memory limit is set to 10Mi — far too low for the app.

## Successful Fix
Increase memory limit to "256Mi"

## What To Validate
Pod Running, no OOMKilled events, restartCount steady

## Why It Matters
OOMKilled vs CrashLoopBackOff, how to choose limits, VPA (Vertical Pod Autoscaler) introduction

## Concepts
OOMKilled, memory limits, exit code 137, resource tuning
