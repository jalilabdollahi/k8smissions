# Common Mistakes — Region Lag

## ❌ Not understanding the annotation structure
The leader annotation is JSON inside the annotation value — parse it carefully.

## ❌ Changing the active cluster without draining the old one
Always drain traffic from the current active before switching.
