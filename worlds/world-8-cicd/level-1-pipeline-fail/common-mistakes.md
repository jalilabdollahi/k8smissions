# Common Mistakes — Broken Stage

## Mistake 1: Changing script instead of image

**Wrong approach:** Editing the build script when the image itself is wrong

**Correct approach:** Check the image tag first with kubectl describe taskrun
