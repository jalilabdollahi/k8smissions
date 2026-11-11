1. `kubectl -n k8smissions get cronjob,jobs,pods` shows `data-processor` with `concurrencyPolicy: Allow` and four Jobs running at once.
2. `kubectl -n k8smissions patch cronjob data-processor --type=merge -p '{"spec":{"concurrencyPolicy":"Forbid"}}'` stops new runs while one is active (`Replace` is also fine and swaps the run for a fresh one).
3. `kubectl -n k8smissions delete jobs -l app=data-processor` removes the Jobs already running; their pods go with them.
4. The CronJob stays unsuspended and starts one clean run at the next minute.
