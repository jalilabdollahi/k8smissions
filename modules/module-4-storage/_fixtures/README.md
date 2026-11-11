# Module 4 fixtures

Shared by the storage levels. Level `setup.sh` files read these through
`../_fixtures/`; they are never copied into a level.

- `uploader.py` - stdlib upload service (`POST /upload/<name>`, `GET /files/<name>`,
  `GET /status`). Levels load it into a ConfigMap with
  `kubectl create configmap uploader-src --from-file=app.py=../_fixtures/uploader.py`
  and run it with `python:3.12-alpine` (`python /src/app.py`, `DATA_DIR` picks the
  directory it stores into). Used by levels 2 and 10.
- `lib.sh` - helpers for `validate.sh` (`. ../_fixtures/lib.sh`): `ok`/`bad`
  message printers, `ensure_probe` (a `curlimages/curl` pod named `probe` in `$NS`)
  and `pcurl` (curl from that pod).
