# Common Mistakes — DNS Blackout

## Mistake 1: Allowing only specific pod egress but forgetting DNS

**Wrong approach:** Adding an egress rule for the database but forgetting port 53 — app still can't resolve hostnames

**Correct approach:** DNS must always be in the egress allowlist; add port 53 as a baseline rule

## Mistake 2: Using namespaceSelector for kube-dns

**Wrong approach:** Only allowing egress to kube-system namespace — DNS requires both namespace AND port match

**Correct approach:** Add a separate ports-only rule for UDP/TCP 53 without a destination selector
