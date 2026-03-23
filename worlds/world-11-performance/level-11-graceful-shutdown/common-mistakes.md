# Common Mistakes — In-Flight Request Drop

## Mistake 1: Setting terminationGracePeriodSeconds to 0

**Wrong approach:** Immediate SIGKILL — guaranteed request drops and potential data corruption

**Correct approach:** Set grace period > longest expected request duration; add preStop sleep for endpoint propagation
