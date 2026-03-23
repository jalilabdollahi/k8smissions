# Connection Refused

## Situation
Service created but connections fail. targetPort points to port 8080 but the container actually listens on 80.

## Successful Fix
Change targetPort to 80

## What To Validate
curl / connection from another pod succeeds

## Why It Matters
Explain port vs targetPort vs containerPort, named ports

## Concepts
port, targetPort, containerPort, service routing
