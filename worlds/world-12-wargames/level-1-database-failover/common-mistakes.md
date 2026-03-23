# Common Mistakes — DB Down

## ❌ Fixing the app deployment first
The app connects to the DB on startup. Fix the DB first, then the app pods naturally recover.

## ❌ Wrong service selector
The Service must select `app: db` — if the selector doesn't match the pod label, endpoints stay empty.

## ❌ Forgetting the Service
Recreating the pod without the service means the app can't resolve `db-service` by DNS.
