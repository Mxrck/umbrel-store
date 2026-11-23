# Mxrck — Umbrel Community App Store

Community app store for umbrelOS. Currently ships **OpenTodo** (official package
from [OpenTodoApp/OpenTodo](https://github.com/OpenTodoApp/OpenTodo),
`deploy/umbrel/`), which is submitted to the official store
([PR #6251](https://github.com/getumbrel/umbrel-apps/pull/6251)) but not listed there yet,
and **ntfy (own admin)**.

Add this store in umbrelOS: **App Store → ⋯ → Community App Stores → Add**
and paste `https://github.com/Mxrck/umbrel-store`.

## ntfy (`mxrck-ntfy`)

Same ntfy server as the official app, with one difference: the administrator user and
password come from Umbrel's environment settings, so you decide them instead of
inheriting a generated password.

The official package runs this on every start:

```sh
NTFY_PASSWORD=${NTFY_PASSWORD} ntfy user add --role=admin umbrel || true
```

`ntfy user add` rewrites the password hash even when the user already exists, so the
password stops working after any restart or app update, and the admin name is hardcoded
to `umbrel`. This package checks first and creates the account only when missing, with
the user and password from the app settings.

## Cleaning plan, Yuvomi module (`mxrck-yuvomi-module-cleaningplan`)

Backend (sidecar) for the third-party Yuvomi module
[la3mmchen/yuvomi-cleaningplan](https://github.com/la3mmchen/yuvomi-cleaningplan): rooms,
recurring cleaning activities and iterations that become normal Yuvomi tasks.

Yuvomi modules are browser code and may not touch Yuvomi's database, so the plan lives in
this app's own SQLite file and the module page talks to it over
`/api/extensions/cleaningplan/*` on the Yuvomi origin. That means this app is only half of
it: the module page still has to be installed from Yuvomi's Settings and one
reverse-proxy rule has to send that path here from your Yuvomi domain. The app's status
page repeats both steps and shows whether the service answers.

Packaging notes: image pinned by index digest, source audited at the revision the image
declares; `PROXY_AUTH_WHITELIST=/api/*` because the module calls the API from the browser
with a Yuvomi session (the sidecar validates it against `/api/v1/auth/me` and enforces CSRF
and an exact `Origin` check on writes), while the status page stays behind the Umbrel
login; `PUBLIC_ORIGIN` must be the exact browser origin or writes answer
`403 csrf_invalid`.

