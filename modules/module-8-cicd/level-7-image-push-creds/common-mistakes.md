**Only recreating the Secret from the same values.** `registry-creds` already looks right at a glance: type, name and binding. Rebuilding it with the same host `registry:5000` reproduces the 401. The host must be the one the step pushes to.

**Fixing the host but copying the password from the decoded `auth`.** The decoded value ends in a newline; if it goes into `--docker-password`, or into another `echo | base64`, the registry still refuses it. Take the password without trailing whitespace.

**Trying to switch the registry's authentication off.** That removes the symptom and the security the registry team asked for, and the level checks that anonymous pushes are still refused. The defect is in the client credentials.
