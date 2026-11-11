#!/bin/bash
# worker 1 = the reclaimed spot node, worker 2 = the on-demand node with its own taint
. ../_fixtures/lib.sh
spot=$(worker_n 1); od=$(worker_n 2)
kubectl label node "$spot" lifecycle=spot --overwrite
kubectl taint node "$spot" spot-reclaimed=true:NoSchedule --overwrite
kubectl label node "$od" lifecycle=on-demand --overwrite
kubectl taint node "$od" lifecycle=on-demand:NoSchedule --overwrite
