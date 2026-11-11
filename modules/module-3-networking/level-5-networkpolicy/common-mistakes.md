## Deleting the NetworkPolicies

Traffic flows again, but so it does for `report-batch`, and `ledger-api` loses its protection. The goal is a narrow allow rule, not no rule.

## Fixing only the label

With the peer selector right and port 80 still in the rule, requests to 8080 are still dropped. Both the peer and the port have to match.

## Using the Service port instead of the pod port

Here they are the same number, but a policy is checked against the destination pod's port. When Service port and `targetPort` differ, the policy needs the `targetPort`.
