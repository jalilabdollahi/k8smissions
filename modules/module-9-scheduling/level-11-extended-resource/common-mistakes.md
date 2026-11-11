## Stopping after the name fix

Two transcoders start and it feels done, but the objective is three. Read the Events of the third pod: the resource is spelled right now and the cards are all taken.

## Editing the node's capacity to match the pod

Patching `status.capacity` to add `example.com/fpga`, or adding a fourth card to a node, makes pods schedule against hardware that does not exist. The validator compares node capacity to the inventory, and the fix belongs on the pod side.

## Lowering replicas to 2

Two pods run, but the service needs three transcoders and the three cards exist. A stale pod was holding one.
