# Common Mistakes — The Garbled Token

## Mistake 1: Using stringData and data together incorrectly

**Wrong approach:** Setting both stringData.token and data.token — data overrides stringData if both present

**Correct approach:** Use only one field: stringData for plaintext, data for pre-encoded base64

## Mistake 2: Forgetting -n flag in echo

**Wrong approach:** echo 'value' | base64 includes a trailing newline — always use echo -n

**Correct approach:** Always echo -n 'value' | base64 to avoid a trailing newline in the decoded secret
