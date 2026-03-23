# Unvalidated Resource

## What Was Broken
The CRD used x-kubernetes-preserve-unknown-fields: true which disabled all validation. Any values in any fields were accepted. The operator received garbage data and was crashing silently.

## The Fix
Add a structural OpenAPI schema with type, required, and property constraints.

## Why It Matters
Kubernetes CRDs require structural schemas in apiextensions.k8s.io/v1 (not v1beta1). A structural schema: every field has a type, no use of oneOf/anyOf/not at the top level without allOf, no additionalProperties combined with named properties.

## Pro Tip
Use CEL validation rules for complex cross-field validation: x-kubernetes-validations: - rule: self.minReplicas <= self.maxReplicas - message: minReplicas must be <= maxReplicas

## Concepts
CRD schema, OpenAPI v3, structural schema, x-kubernetes-preserve-unknown-fields, field validation
