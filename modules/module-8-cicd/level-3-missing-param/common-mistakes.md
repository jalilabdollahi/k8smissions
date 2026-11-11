**Fixing only the first error.** Adding `env` to a copy of the old run just moves the failure: `targets` is still a string and the run is rejected again, with a different message. Read the message after every attempt.

**Quoting the list as one string.** `value: "slack-payments,pager-oncall,email-finance"` is a string whatever the commas say, and the loop in the step would see one argument. An array value is a YAML list, one item per entry, and the log must show three `notified` lines.

**Trying to `kubectl edit` the old PipelineRun.** Its params are part of the immutable spec. Create a new run; the old failed one can stay as history.
