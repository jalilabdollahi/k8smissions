1. `kubectl get nodes -L disktype,drain-pending` shows the SSD worker still has `drain-pending=true`, left over from last week's maintenance.
2. The affinity term requires `disktype In [ssd,nvme]` AND `drain-pending DoesNotExist`; the SSD node fails the second expression, the HDD node the first.
3. Remove the stale label: `kubectl label node <ssd-node> drain-pending-`. The scheduler re-evaluates the Pending pods and both start on the SSD node.
   (Editing the affinity to drop the `drain-pending` expression is also accepted.)
