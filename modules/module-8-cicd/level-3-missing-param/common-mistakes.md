# Common Mistakes — Missing Parameter

## Mistake 1: Setting empty string value

**Wrong approach:** params: [{name: IMAGE, value: ""}] — empty string is accepted but will cause runtime failure

**Correct approach:** Provide a valid non-empty value
