# Common Mistakes — The Mixed Signals

## Mistake 1: Changing the Ingress to use a port number

**Wrong approach:** Switching Ingress to use port.number: 80 — works but not idiomatic for Ingresses

**Correct approach:** Use named ports; it is the standard way and avoids magic numbers

## Mistake 2: Naming only one port

**Wrong approach:** Adding name: http to the 80 port but leaving 443 unnamed — the 443 rule still fails

**Correct approach:** All ports on a multi-port Service must be named
