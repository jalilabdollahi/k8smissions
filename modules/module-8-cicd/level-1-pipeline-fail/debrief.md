# Broken Stage

## What Was Broken
The Tekton Task used image golang:99.9-nonexistent — a tag that doesn't exist. The TaskRun pod failed with ErrImagePull before any step ran.

## The Fix
Change the image to a valid tag like golang:1.21.

## Why It Matters
Image pull failures are the most common early-stage CI failures. Always pin exact image digests in production pipelines for reproducibility.

## Pro Tip
Use image digests instead of tags: golang@sha256:abc123 — tags are mutable, digests are immutable.

## Concepts
Tekton, Task, image pull, ErrImagePull, CI pipeline
