1. `get pod -o wide` shows 2 running pods per Job and one Pending pod per Job. The Pending ones say `Insufficient cpu`: the cluster fits 4 pods, and each Job needs 3 at the same time for its barrier.
2. Free the room of one Job by suspending it (this terminates its pods):
   `kubectl -n k8smissions patch job train-b --type=merge -p '{"spec":{"suspend":true}}'`
3. `train-a` gets its third pod, passes the barrier with 3 of 3 peers and completes: `kubectl -n k8smissions wait --for=condition=complete job/train-a`.
4. Resume the other Job; it now has the cluster to itself:
   `kubectl -n k8smissions patch job train-b --type=merge -p '{"spec":{"suspend":false}}'`
