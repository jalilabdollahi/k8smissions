# Common Mistakes — One-Shot Task

## Mistake 1: Increasing backoffLimit to hide the problem

**Wrong approach:** Setting backoffLimit: 100 so it keeps retrying without fixing root cause

**Correct approach:** Fix the command first; only increase backoffLimit if transient failures are expected

## Mistake 2: Wrong restartPolicy

**Wrong approach:** Setting restartPolicy: Always — Jobs require Never or OnFailure

**Correct approach:** Use Never for independent attempts, OnFailure to reuse the same pod on failure
