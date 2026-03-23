# Gate Blocks Deploy

## What Was Broken
The run-tests Task had 'exit 1' hardcoded in the test script. Tekton treats any non-zero exit as step failure, blocking downstream stages.

## The Fix
Fix the test script to exit 0. In production, fix the actual test failures.

## Why It Matters
Test gates in pipelines are a core DevOps principle. Pipelines should fail fast: run unit tests first (cheap), then integration tests (expensive), then deploy only on clean test run.

## Pro Tip
Use Tekton Finally tasks for cleanup that must run even on failure: posting test reports, sending Slack notifications.

## Concepts
Tekton, exit codes, pipeline gates, test failure, step failure
