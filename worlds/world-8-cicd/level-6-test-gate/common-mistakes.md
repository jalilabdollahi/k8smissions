# Common Mistakes — Gate Blocks Deploy

## Mistake 1: Allowing failures with continueAfterFailures

**Wrong approach:** Using a Tekton alpha feature to skip failures — bypasses the safety gate

**Correct approach:** Fix the test failure; don't bypass the gate
