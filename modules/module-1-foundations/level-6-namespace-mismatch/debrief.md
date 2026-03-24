# Lost in Space

## Situation
A Pod and its Service were deployed to the "default" namespace but the app expects to be in "k8smissions". Service lookup fails.

## Successful Fix
Delete and recreate both in namespace: k8smissions

## What To Validate
Pod and Service exist in k8smissions namespace and are reachable

## Why It Matters
Explain namespace isolation, RBAC per namespace, default namespace

## Concepts
namespaces, resource isolation, cross-namespace DNS
