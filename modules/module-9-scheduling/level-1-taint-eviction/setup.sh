#!/bin/bash
# The first worker is the NVMe node and is already in its maintenance window.
. ../_fixtures/lib.sh
node=$(worker_n 1)
kubectl label node "$node" disktype=nvme --overwrite
kubectl taint node "$node" maintenance=nightly:NoExecute --overwrite
