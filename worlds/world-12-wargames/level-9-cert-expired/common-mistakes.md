# Common Mistakes — Mass Cert Expiry

## ❌ Not having alerting on cert expiry
Set up monitoring for certificate expiration well in advance (30/14/7 day alerts).

## ❌ Restarting the API server to fix certs
The API server uses the certs on disk — renew them first, then restart.
