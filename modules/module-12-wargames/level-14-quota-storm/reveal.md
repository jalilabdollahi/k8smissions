Three faults:

1. 17 finished `retry-old-*` Jobs plus 2 releases and the stuck run fill `count/jobs.batch` (20 of 20). Delete the finished retry Jobs by label and keep the `release=true` ones: `kubectl -n ci delete job -l kind=retry`.
2. `ci-retrier` creates Jobs without `ttlSecondsAfterFinished` (`JOB_TTL_SECONDS` is empty), so the namespace refills in minutes. `kubectl -n ci set env deploy/ci-retrier JOB_TTL_SECONDS=60`.
3. `flaky-suite` has been sleeping for hours and holds 600m of the 1 CPU `requests.cpu` quota (plus one Job slot). Once `release-v42` is created its pod (600m) is refused by the quota until the stuck run is gone: `kubectl -n ci delete job flaky-suite`.

Do the TTL before the cleanup, otherwise the retrier takes the slots back.
