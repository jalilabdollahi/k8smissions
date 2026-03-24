# Handshake Refused

## What Was Broken
The webhook config had a hardcoded caBundle with an expired/invalid certificate. Every pod CREATE request was sent to the webhook, which returned TLS errors. With failurePolicy: Fail, all pod creations were blocked.

## The Fix
Use cert-manager's CA injection annotation to automatically keep caBundle up-to-date. The caBundle must match the CA that signed the webhook server's TLS certificate.

## Why It Matters
Webhook TLS rotation strategy: use cert-manager Certificate + caBundle injection annotation on the webhook config. cert-manager rotates the server cert and updates caBundle automatically — zero-downtime cert rotation.

## Pro Tip
Check webhook cert expiry: kubectl get secret webhook-tls -n operators -o jsonpath='{.data.tls.crt}' | base64 -d | openssl x509 -noout -dates

## Concepts
admission webhook, TLS, caBundle, cert-manager, certificate rotation
