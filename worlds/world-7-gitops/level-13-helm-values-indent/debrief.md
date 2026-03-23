# The Value Ignored

## What Was Broken
The `tag: v2.0.0` line was at the root YAML level instead of indented under `image:`. YAML parsed it as a root key `tag` (overriding nothing in the chart) while `image.tag` kept its chart default value.

## The Fix
Indent `tag:` and `repository:` two spaces under `image:` so they form the expected nested structure `image.tag` and `image.repository`.

## Why It Matters
YAML indentation bugs are silent — the file is valid YAML, just not the structure you intended. Always validate values files with `helm template <release> <chart> -f values.yaml` before applying, which renders the template and shows exactly what values were used.

## Pro Tip
Use `helm template` to preview rendered manifests: `helm template my-release ./chart -f values.yaml | grep image:`. This makes it obvious whether your image tag was picked up.

## Concepts
Helm, values.yaml, YAML indentation, helm template, values override
