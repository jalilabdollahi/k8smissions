## Trusting `kubectl top`

It shows what processes use, and the scheduler does not read it. A node at 8% CPU can be fully reserved. Compare with Allocated resources on the node.

## Deleting `capacity-reserve`

`checkout` schedules, and the headroom that the platform team keeps for the next spike is gone. The validator requires the placeholders to remain.

## Editing the priority on running pods or the class value

A pod's `priorityClassName` cannot be changed on a live pod, and existing pods keep their resolved priority. Change the Deployment's template and let it roll, using a class that sits below the workloads you want to protect.
