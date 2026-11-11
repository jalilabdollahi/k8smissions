## Deleting the readiness probe

The pods become Ready and the Service gets endpoints, but the API still has no index and answers 503. The probe was telling the truth.

## Looking at the Service

The selector is correct and matches all four pods. An empty endpoint list with Running pods is a readiness question, not a Service question.

## Reading only the current log of the sidecar

A crash-looping container may have just started and printed nothing yet. `kubectl logs --previous` holds the output of the run that failed.
