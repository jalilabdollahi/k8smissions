## Common mistakes

- **Renaming the host or port.** The names are right; only the order is wrong. The log line shows the unexpanded text, not a wrong value.
- **Fixing the Service `smtp-relay`.** The relay answers correctly. The mailer never reaches it because it never builds a valid address.
- **Deleting the pods without changing the Deployment.** New pods get the same env list and the same literal URL.
- **Using `kubectl set env SMTP_URL=...` with another `$(VAR)` reference.** `set env` updates in place without reordering, so a reference to later entries stays literal. Reorder, or spell out the URL.
