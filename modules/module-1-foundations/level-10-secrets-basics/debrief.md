# Forbidden Credentials

## Situation
Pod references Secret "db-credentials" that doesn't exist. Pod fails with CreateContainerConfigError.

## Successful Fix
Create Secret with username and password (base64 encoded)

## What To Validate
Pod Running, secret values accessible as env vars

## Why It Matters
Secrets vs ConfigMaps, base64 is NOT encryption, external secret stores (Vault, Sealed Secrets)

## Concepts
Secret, base64 encoding, envFrom, secretKeyRef
