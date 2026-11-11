#!/bin/bash
# worker 1: SSD node with a stale drain-pending label left from last week; worker 2: HDD node
. ../_fixtures/lib.sh
kubectl label node "$(worker_n 1)" disktype=ssd drain-pending=true --overwrite
kubectl label node "$(worker_n 2)" disktype=hdd --overwrite
