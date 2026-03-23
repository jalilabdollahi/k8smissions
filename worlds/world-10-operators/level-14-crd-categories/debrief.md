# Not in List

## What Was Broken
The CRD had no 'categories' defined. kubectl get all only includes resource types in the 'all' category. Without it, the custom resource exists but is invisible to generic discovery commands.

## The Fix
Add categories: [all] to spec.names to include the resource in kubectl get all output.

## Why It Matters
Categories are purely a UX feature — they don't affect API behavior. Custom categories can also be defined: categories: [mycompany] then kubectl get mycompany lists all resources in that category.

## Pro Tip
Also add printColumns to the CRD to customize what kubectl get shows: spec.versions[].additionalPrinterColumns. E.g., show status.phase, spec.replicas alongside NAME and AGE.

## Concepts
CRD, categories, kubectl get all, shortNames, additionalPrinterColumns
