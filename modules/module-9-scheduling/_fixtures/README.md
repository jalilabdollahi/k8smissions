# Module 9 fixtures

Shared by the levels of module 9. Levels reference these files from `setup.sh`
and `validate.sh` (`. ../_fixtures/lib.sh`); nothing is copied into a level
folder. Owned by the first-half author; the second half may only use them.

- `lib.sh`: bash helpers, sourced.
  - `workers`, `worker_n 1|2`: the two worker node names (control plane excluded), never hard-coded.
  - `free_cpu_m <node>`, `free_mem_mi <node>`: allocatable minus the requests the scheduler
    has counted (parsed from `kubectl describe node`, so it includes pod overhead and init
    container maths). Use them to size filler pods so a level works on any host.
  - `cpu_to_m`, `mem_to_mi`: quantity converters.
  - `wait_pods_ready <selector> <count> [seconds]`: waits for Ready pods in `$NS` (needs `jq`).

solution.sh runs in an empty directory and cannot source this file; it discovers
node names with `kubectl` itself, as a player would.
