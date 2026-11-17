#!/bin/sh
# Runs inside the ntfy container (uid 1000). Starts the server, then makes sure the
# administrator exists.
#
# Why a script: the official Umbrel package runs `ntfy user add ... || true` on every
# start, which rewrites the password hash with the container's own generated password.
# That makes the password shown in the UI stop working after any restart or update.
# Here the account is created ONLY when it is missing, and never touched again.
#
# Password resolution, in order:
#   1. NTFY_ADMIN_PASSWORD from the app settings (what you configure yourself).
#   2. UMBREL_APP_PASSWORD, the per-install password umbrel generates for the app.
#   3. Random, generated once and stored at /var/lib/ntfy/admin-password.txt (0600).
# An app store package cannot ship a fixed password, so (3) is what a fresh install
# with no configuration gets: random, never a known default.
set -e

AUTH_DIR=$(dirname "${NTFY_AUTH_FILE:-/var/lib/ntfy/user.db}")

resolve_password() {
  if [ -n "${NTFY_ADMIN_PASSWORD:-}" ]; then
    printf '%s' "${NTFY_ADMIN_PASSWORD}"
    return
  fi
  if [ -n "${UMBREL_APP_PASSWORD:-}" ]; then
    printf '%s' "${UMBREL_APP_PASSWORD}"
    return
  fi
  pwfile="${AUTH_DIR}/admin-password.txt"
  if [ ! -s "${pwfile}" ]; then
    # hex, not base64: no slashes or plus signs to quote in a shell or a URL.
    head -c 16 /dev/urandom | od -An -tx1 | tr -d ' \n' > "${pwfile}"
    chmod 600 "${pwfile}"
    # stderr on purpose: this function's stdout is captured as the password.
    echo "[entrypoint] generated a random admin password at ${pwfile}" >&2
  fi
  cat "${pwfile}"
}

ntfy serve &
serve_pid=$!

# Give the server a moment to open the auth database (and create user.db).
sleep 3

ADMIN_USER="${NTFY_ADMIN_USER:-umbrel}"

# `ntfy user list` prints "user <name> (role: ..., tier: ...)" per line, not columns.
if ntfy user list 2>/dev/null | awk '/^user /{print $2}' | grep -qx "${ADMIN_USER}"; then
  if [ "${NTFY_ADMIN_FORCE_PASSWORD}" = "true" ]; then
    echo "[entrypoint] NTFY_ADMIN_FORCE_PASSWORD=true: applying the configured password to ${ADMIN_USER}"
    if NTFY_PASSWORD="$(resolve_password)" ntfy user change-pass "${ADMIN_USER}"; then
      echo "[entrypoint] password updated; set NTFY_ADMIN_FORCE_PASSWORD back to false"
    fi
  else
    echo "[entrypoint] user ${ADMIN_USER} already exists, leaving it untouched"
  fi
else
  echo "[entrypoint] creating admin user ${ADMIN_USER}"
  if NTFY_PASSWORD="$(resolve_password)" ntfy user add --role=admin "${ADMIN_USER}"; then
    # No `ntfy access` needed: admin users bypass access control entirely, so this
    # account can publish and subscribe to every topic, including the ones
    # UnifiedPush creates later (verified with ntfy 2.38.1).
    echo "[entrypoint] admin ${ADMIN_USER} created; admins bypass topic access control"
    if [ -z "${NTFY_ADMIN_PASSWORD:-}" ]; then
      echo "[entrypoint] NTFY_ADMIN_PASSWORD was empty, so the password is either the umbrel"
      echo "[entrypoint]   app password or the contents of ${AUTH_DIR}/admin-password.txt"
    fi
  else
    echo "[entrypoint] ERROR: could not create ${ADMIN_USER}" >&2
  fi
fi

wait "${serve_pid}"
