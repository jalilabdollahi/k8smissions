# Controller Crash Loop

## What Was Broken
The operator was deployed before its CRD was installed. During startup, the controller manager tried to register watches on the CRD's API type. With no CRD installed, this triggered a nil pointer panic.

## The Fix
Add an init container that polls for CRD existence before the operator starts.

## Why It Matters
Deployment ordering matters for operators. Some frameworks (like controller-runtime) handle CRD absence gracefully with retries. Others panic. The init container pattern is robust regardless of framework behavior.

## Pro Tip
Better long-term: bundle CRD installation in the operator's Helm chart with proper installation ordering. Use Helm hooks: helm.sh/hook: pre-install for CRD resources to ensure they're created before the operator Deployment.

## Concepts
operator startup, CRD dependency, init container, CrashLoopBackOff, deployment ordering
