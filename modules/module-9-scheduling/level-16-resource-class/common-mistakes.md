## Creating the class and stopping

With the class present, the event moves from "not found" to an allocation failure. The pod is still Pending, and the cause is now in the claim's own selector.

## Guessing the driver name from the class name

`gpu.example.com` is only the class's name. The selector has to name the driver the slices really publish (`gpu.lab.example.net`), which is only visible in the ResourceSlices.

## Editing the template and waiting

The pod's claim was generated from the old template when the pod was created. Replace the template, then delete the pod so the Deployment creates a new one with a new claim.
