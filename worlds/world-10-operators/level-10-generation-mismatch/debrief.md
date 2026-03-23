# Stale Reconciliation

## What Was Broken
status.observedGeneration was stuck at 1 while metadata.generation was 5 — meaning 4 spec changes were never processed. The controller either had a bug that skipped generation updates or was reconciling the wrong object version.

## The Fix
Update status.observedGeneration = metadata.generation after each successful reconciliation.

## Why It Matters
generation/observedGeneration pattern: the standard way for operators to track which spec version they've processed. If observedGeneration < generation, the operator hasn't reconciled the latest spec. Most controllers also set a 'conditions' array in status with reason/message.

## Pro Tip
Anti-pattern: reconciling on every watch event without checking generation means any status update (which triggers a watch event) causes another full reconciliation — a hot loop.

## Concepts
generation, observedGeneration, reconciliation guard, operator optimization, status conditions
