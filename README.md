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
