# Random Logout

## Situation
Users randomly get logged out. App stores sessions in-memory. Service load-balances to different pods per request.

## Successful Fix
Set service.spec.sessionAffinity: ClientIP

## What To Validate
Use the validator to confirm the repaired state.

## Why It Matters
Review how the fix changed the cluster behavior for Random Logout.

## Concepts
Session affinity, sticky sessions, ClientIP, stateful vs stateless apps, shared session stores
