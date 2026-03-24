# Image Not Found

## Situation
Pod stuck in ImagePullBackOff. Image name has a typo.

## Successful Fix
Change image to "nginx:latest"

## What To Validate
Pod Running, no ImagePullBackOff

## Why It Matters
Explain image naming (registry/name:tag), private registries, imagePullSecrets

## Concepts
ImagePullBackOff, ErrImagePull, image registry, tags
