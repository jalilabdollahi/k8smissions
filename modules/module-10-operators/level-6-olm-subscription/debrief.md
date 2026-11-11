## What was broken

The operator was pinned to release 1.2.0 while the platform CRD had already moved on to the 1.4.0 schema. Real operator lifecycle tools (OLM, Helm charts, GitOps overlays) treat a release as a node in an upgrade graph: each version declares which one it replaces and what migration it assumes was done. Here 1.3.0 is the release that converts existing Widgets and 1.4.0 refuses to run until that has happened.

## The evidence

Three things together: the Deployment's labels and volume showed the pin (1.2.0), the `bundle.json` of each ConfigMap showed the chain (`replaces`), and, for anyone who tried to jump straight to 1.4.0, the crash-looping pod's log said exactly why it stopped ("widgets ... are not on schema 2"). `kubectl get widgets -o yaml` showed the migration state between steps.

## Why it behaved this way

A schema change that renames fields cannot be done by the API server alone: someone has to rewrite the stored objects, and in the operator world that someone is the migration release. A later release then drops the old code path and is free to assume the data is already in the new shape; starting it early would corrupt or ignore the old objects, so well-behaved operators check and stop. Crash-looping is the safe failure here: the old operator is not running either, and nothing is damaged.

## The fix

Install 1.3.0, wait until every Widget reports `schemaVersion: 2`, then install 1.4.0. Do not shortcut the check inside the bundle: the validator verifies that the old Widgets really carry the migrated data.

## In production

Read the release notes and the `replaces`/`skipRange` metadata before changing a subscription, pin versions deliberately, and take a backup of the CRs before a migration release runs. Prefer channels that follow the graph automatically (OLM does) over hand-editing volumes.

## Worth remembering

- `kubectl logs deploy/<operator>` right after a rollout
- `kubectl get <crd> -o custom-columns=NAME:.metadata.name,SCHEMA:.status.schemaVersion`
- `kubectl rollout status deployment/<name>`
