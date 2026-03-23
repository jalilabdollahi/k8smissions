# Version Migration

## What Was Broken
The CRD had two versions but conversion strategy: None. Objects stored as v1alpha1 are not returned when queried as v1beta1. Without a webhook, there's no translation between schemas.

## The Fix
Add a conversion webhook that transforms v1alpha1 to v1beta1 format, and change the storage version to v1beta1.

## Why It Matters
CRD versioning strategy: one version is the 'storage' version (persistent). Conversion webhooks translate between versions on read/write. The Hub-and-Spoke pattern: v1 is the hub, all versions convert to/from v1.

## Pro Tip
Never remove a version that users are actively using without migration tooling. Use CRD migration scripts to re-write all stored objects to the new version before removing old version support.

## Concepts
CRD versioning, conversion webhook, storage version, hub-and-spoke, migration
