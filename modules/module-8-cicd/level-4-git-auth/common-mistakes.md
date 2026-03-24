# Common Mistakes — Clone Denied

## Mistake 1: Using HTTP credentials for SSH URL

**Wrong approach:** Creating an HTTP basic-auth secret for an ssh:// git URL

**Correct approach:** Match secret type to URL scheme: ssh-auth for ssh://, basic-auth for https://
