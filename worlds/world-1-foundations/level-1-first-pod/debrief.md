# Hello, Kubernetes!

## Situation
A Pod was created but it is stuck in Error state. The user defined a bad entrypoint command.

## Successful Fix
Remove the command override so nginx starts normally

## What To Validate
kubectl get pod hello-pod -n k8smissions → Running

## Why It Matters
Explain ENTRYPOINT vs CMD in Docker and how Kubernetes command/args maps to them

## Concepts
pod, command, entrypoint, CrashLoopBackOff
