# Ghost Deployment

## Situation
Deployment exists but has replicas: 0. No pods running.

## Successful Fix
Set replicas: 3

## What To Validate
3/3 pods Ready

## Why It Matters
Deployment → ReplicaSet → Pod ownership chain

## Concepts
Deployment, replicas, ReplicaSet, desired vs actual state
