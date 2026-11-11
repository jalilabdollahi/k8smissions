The `query` step sleeps a fixed 5 seconds and then makes one request. The sidecar's start time varies (4 to 12 seconds in the check), so a run passes only when the sidecar happens to be faster than the sleep. Tekton starts steps and sidecars together and does not wait for the sidecar to be ready.

1. Compare `kubectl logs POD -c sidecar-mock-db` with `-c step-query` of a failed run.
2. Replace the `sleep 5` + single `curl` in Task `db-test` with a retry loop: `until curl -sf --max-time 2 http://127.0.0.1:$(params.db-port)/rows.txt > /tmp/rows.txt; do ...; done`, counting attempts, sleeping 1 second between them and failing with `exit 1` after about 30.
3. Keep the loop bounded: a database that never comes up must fail the run quickly, not hang it for the default hour.
