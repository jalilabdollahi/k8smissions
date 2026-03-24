# Waiting Forever

## Situation
Pod stuck in Init:0/1 forever. The init container is pinging a service that doesn't exist.

## Successful Fix
Change the nslookup target to a service that actually exists OR create the missing service

## What To Validate
Init container exits 0, main container starts and runs

## Why It Matters
When to use init containers, common patterns (wait-for-db, git-clone, permission-setup)

## Concepts
initContainers, pod initialization, startup ordering, dependency waiting
