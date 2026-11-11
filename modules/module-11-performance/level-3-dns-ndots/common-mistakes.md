**Emptying the search list.** Removing `searches` stops the extra queries immediately, but `session-cache` only resolves because of the search domains. The validator also checks that short name, and in a real app the first Service-name lookup would start failing.

**Scaling or restarting the DNS server.** dns-lab is answering fast (microseconds); it is just being asked four times as much as needed. More replicas treat the symptom and the log would look exactly the same.

**Changing the Corefile.** Adding a cache or fallthrough rule to dns-lab hides the NXDOMAIN lines from the client's point of view only if the client stops asking; the fault is in the client's resolver settings. Fix the asker, not the answerer.

**Setting `ndots` to 5 or higher "to be safe".** Any value above the number of dots in the name (2) keeps the name relative and keeps all four queries. The value must be at most 2 for this name.
