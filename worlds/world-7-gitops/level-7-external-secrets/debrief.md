# Secrets in Git? Never.

## Situation
Team committed plain-text secrets to Git — a security incident. Must migrate to External Secrets Operator (ESO). Secrets should come from a secret store, not YAML files.

## Successful Fix
Install External Secrets Operator (bundled manifest) Create SecretStore pointing to local fake backend Create ExternalSecret that pulls values from the store

## What To Validate
Secret exists in cluster but source is ESO, not Git

## Why It Matters
Review how the fix changed the cluster behavior for Secrets in Git? Never..

## Concepts
External Secrets Operator, SecretStore, ExternalSecret, Vault integration, Sealed Secrets alternative, secret rotation
