# No Cache Hit

## What Was Broken
The TaskRun mounted only the 'source' workspace. The maven-build Task declared a 'cache' workspace for ~/.m2 — without it, Maven downloads all dependencies fresh on every run.

## The Fix
Add the PVC binding for the cache workspace. The PVC persists between runs and dramatically speeds up builds.

## Why It Matters
Cache PVCs in k8s must be ReadWriteOnce if builds run on one node, ReadWriteMany for concurrent builds on multiple nodes. Check storage class support.

## Pro Tip
Use accessModes: ReadWriteMany for build caches with parallel pipelines. Alternatively use a distributed cache (Artifactory, Nexus) as the backing store.

## Concepts
Tekton, workspace, PVC, build cache, Maven
