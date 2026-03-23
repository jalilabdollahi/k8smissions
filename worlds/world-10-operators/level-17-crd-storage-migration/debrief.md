# Stored Version Gone

## What Was Broken
v1alpha1 resources existed in etcd but the CRD version was removed. Kubernetes couldn't decode stored v1alpha1 objects because there was no schema for that version anymore. This breaks all API access to those resources.

## The Fix
Always re-add removed versions as served: false, storage: false, migrate all stored objects, then remove the version.

## Why It Matters
Safe CRD version removal checklist: (1) add new version with storage: true, keep old version storage: false, (2) convert all stored objects to new version via mass re-apply, (3) clear status.storedVersions, (4) remove old version from CRD spec.

## Pro Tip
Check which versions are stored: kubectl get crd configs.example.com -o jsonpath='{.status.storedVersions}'. This array must be empty (or contain only the current storage version) before safely removing a version.

## Concepts
CRD versioning, storage migration, storedVersions, etcd, version lifecycle
