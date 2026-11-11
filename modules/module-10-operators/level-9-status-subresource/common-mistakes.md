## Enabling the subresource and calling it done

The operator's 404s stop and `PHASE` fills in, which looks like success. The reporter still writes to the main endpoint, which now discards `status` while answering 200. Run it once (`kubectl create job --from=cronjob/sla-reporter`) and check `lastSlaCheck`.

## Trusting the reporter's log

"stamped 3 of 3" counts HTTP 200 responses, not changes. Read the object.

## Making the operator write status through the main resource instead

Without the subresource that appears to work, but status writes then bump `metadata.generation` on every change, which breaks any controller that compares generation with observed generation. The validator checks that generation stays put.
