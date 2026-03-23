# Manual Block

## What Was Broken
The approval-gate TaskRun was waiting for a file /approval/approved which would be created by a human reviewer. The reviewer was unavailable, blocking the pipeline indefinitely.

## The Fix
For stuck manual gates: either provide the approval externally (exec into pod, create the file) or cancel and recreate with an override.

## Why It Matters
Manual approval gates are important for compliance but create process bottlenecks. Design them with escape hatches: auto-expire after X days, list of fallback approvers, emergency override procedure.

## Pro Tip
Some teams use Slack-based approvals: a bot posts approval buttons. The approval bot creates the approval file in the PVC when clicked. This is the approval gate with a better UX.

## Concepts
Tekton, manual gate, approval, pipeline block, process bottleneck
