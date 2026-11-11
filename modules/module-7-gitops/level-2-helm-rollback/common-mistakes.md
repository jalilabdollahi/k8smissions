**`helm rollback webapp` without a revision.** It goes to the previous revision, number 3, which is the one that crash-loops. The release shows `deployed` afterwards and the pods are still failing. Check what revision 3 rendered before choosing it.

**Trusting `superseded` as "was fine".** That status only records that a later revision replaced it. Revision 3 is superseded and broken. Read the manifest and the pod logs, not the label.

**Uninstalling and installing again.** It brings the app back with fresh values, but it removes the history (and any hooks and keep-annotated objects with it). The check requires revisions 1 to 4 to still be there, which is also what you want for the incident report.
