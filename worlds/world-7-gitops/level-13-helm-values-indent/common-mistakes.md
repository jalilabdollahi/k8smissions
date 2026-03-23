# Common Mistakes — The Value Ignored

## Mistake 1: Assuming helm upgrade shows errors for bad values structure

**Wrong approach:** helm upgrade succeeds even if your values structure is wrong — chart defaults are used instead

**Correct approach:** Always use helm template to verify rendering before helm upgrade

## Mistake 2: Mixing tabs and spaces

**Wrong approach:** YAML requires consistent spaces; tabs cause parse errors or unexpected structure

**Correct approach:** Use a YAML linter (yamllint) and ensure editor uses spaces, not tabs
