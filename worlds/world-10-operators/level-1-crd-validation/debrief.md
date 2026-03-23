# Rejected by the API

## What Was Broken
The CRD schema had minimum: 5 for the replicas field. The AppTemplate CR specified replicas: 2, which fails OpenAPI schema validation. The API server rejects the request before it reaches any controller.

## The Fix
Lower the minimum to 1 in the CRD schema, or change the CR to replicas: 5.

## Why It Matters
CRD OpenAPI validation is enforced by the API server — no controller or webhook needed. Use it for field-level constraints: required fields (nullable: false), ranges, pattern matching, enum values.

## Pro Tip
Use kubectl explain to explore CRD schemas: kubectl explain AppTemplate.spec. For advanced validation (cross-field rules), use x-kubernetes-validations (CEL expressions) added in k8s 1.25.

## Concepts
CRD, OpenAPI validation, minimum, custom resource, API server validation
