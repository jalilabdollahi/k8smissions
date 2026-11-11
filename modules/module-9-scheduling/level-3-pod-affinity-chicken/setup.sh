#!/bin/bash
# The cache tier is only allowed on the high-memory worker (worker 2).
. ../_fixtures/lib.sh
kubectl label node "$(worker_n 2)" pool=cache --overwrite
