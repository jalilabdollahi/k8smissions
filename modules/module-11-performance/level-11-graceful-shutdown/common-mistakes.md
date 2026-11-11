**Raising only the grace period.** A pod whose PID 1 is a shell still never gets the signal in a form it acts on, so it waits the whole 40 seconds and is killed with the clip unfinished. Pods that take longer to die are the symptom of this mistake.

**Fixing the command but leaving 15 seconds.** The worker now drains and exits cleanly, but only clips that happen to finish inside 15 seconds survive. A 20 or 25 second clip is cut off by SIGKILL, and the clean-shutdown report never arrives.

**Adding a preStop `sleep`.** It delays SIGTERM, which uses up the same grace period, so it makes a long job less likely to finish. preStop is for endpoint drain (module 7), not for waiting out work.
