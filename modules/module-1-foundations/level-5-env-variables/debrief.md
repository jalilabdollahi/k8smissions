# Missing the Key

## Situation
Pod keeps crashing. The app expects DATABASE_URL env var but it is not set in the manifest.

## Successful Fix
Add env: [{name: DATABASE_URL, value: "postgres://localhost/app"}]

## What To Validate
Pod Running, no CrashLoop

## Why It Matters
Three ways to inject config: env literals, envFrom ConfigMap, envFrom Secret

## Concepts
env, environment variables, application config
