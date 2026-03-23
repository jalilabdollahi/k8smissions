# Config Not Found

## Situation
Pod tries to mount a ConfigMap volume that doesn't exist yet. Pod stuck in ContainerCreating.

## Successful Fix
Create ConfigMap app-config with key APP_MODE=production and apply it before the pod

## What To Validate
Pod Running, ConfigMap mounted successfully

## Why It Matters
ConfigMap as env variables vs mounted files, immutable ConfigMaps

## Concepts
ConfigMap, volumes, volumeMounts, envFrom
