## Lowering the pod requests or deleting the Pending pods

Deleting a Pending pod just makes the Job controller create another one that cannot fit either. Shrinking requests may squeeze in a pod, but it changes the capacity of both jobs without fixing the interleaving, and the training will be starved.

## Reducing parallelism

With `parallelism: 2` the barrier still waits for 3 peers, so the Jobs never pass it. The point of the barrier is that all three workers are alive together.

## Suspending both Jobs

That frees the room and nothing runs. One Job has to go first and finish; the other waits suspended until it is done.
