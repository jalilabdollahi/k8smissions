1. `describe pod` shows `Insufficient cpu` on both workers. `describe node` shows each worker has about 40% of its CPU still unreserved after one encoder replica: the replica asks for about 60% of a node.
2. Total free room across the two workers is enough for 1.8 nodes of requests, but no single worker has room for two replicas, so the third cannot be placed. Fragmentation, not shortage.
3. Lower the request so two replicas fit on one worker (for example three quarters of the current value, which is about 45% of a node):
   `kubectl -n k8smissions set resources deploy/video-encoder --requests=cpu=<value>`
4. The rollout starts pods with the smaller request and all 3 run, split over the workers. Going to 2 replicas would hide the problem and lose capacity.
