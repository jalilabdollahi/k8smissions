# Webhook Ignored

## What Was Broken
The TriggerBinding referenced $(body.commits[0].sha) but GitHub push webhook payloads use body.head_commit.id for the most recent commit. Empty string extraction caused PipelineRun creation with empty git-revision param.

## The Fix
Correct the body field reference to match the actual GitHub webhook JSON structure.

## Why It Matters
Webhook payload structure varies by provider. GitHub, GitLab, and Bitbucket all use different JSON schemas. Check the actual webhook payload in the EventListener pod logs.

## Pro Tip
Debug Tekton triggers: kubectl logs -l eventlistener=my-listener -n k8smissions -c event-listener. The logs show received payloads and extraction results.

## Concepts
Tekton Triggers, TriggerBinding, webhook payload, CEL, field extraction
