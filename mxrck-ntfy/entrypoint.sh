#!/bin/sh
# Runs inside the ntfy container (uid 1000). Starts the server, then makes sure the
# administrator exists.
#
# Why a script: the official Umbrel package runs `ntfy user add ... || true` on every
# start, which rewrites the password hash with the container's own generated password.
# That makes the password shown in the UI stop working after any restart or update.
# Here the account is created ONLY when it is missing, and never touched again.
set -e

ntfy serve &
serve_pid=$!

# Give the server a moment to open the auth database.
sleep 3

if [ -n "${NTFY_ADMIN_USER}" ] && [ -n "${NTFY_ADMIN_PASSWORD}" ]; then
  if ntfy user list 2>/dev/null | awk 'NR>1 {print $1}' | grep -qx "${NTFY_ADMIN_USER}"; then
    if [ "${NTFY_ADMIN_FORCE_PASSWORD}" = "true" ]; then
      echo "[entrypoint] NTFY_ADMIN_FORCE_PASSWORD=true: applying the configured password"
      NTFY_PASSWORD="${NTFY_ADMIN_PASSWORD}" ntfy user change-pass "${NTFY_ADMIN_USER}" \
        && echo "[entrypoint] password updated; set NTFY_ADMIN_FORCE_PASSWORD back to false"
    else
      echo "[entrypoint] user ${NTFY_ADMIN_USER} already exists, leaving it untouched"
    fi
  else
    echo "[entrypoint] creating admin user ${NTFY_ADMIN_USER}"
    if NTFY_PASSWORD="${NTFY_ADMIN_PASSWORD}" ntfy user add --role=admin "${NTFY_ADMIN_USER}"; then
      # No `ntfy access` needed: admin users bypass access control entirely, so this
      # account can publish and subscribe to every topic, including the ones
      # UnifiedPush creates later (verified with ntfy 2.38.1).
      echo "[entrypoint] admin ${NTFY_ADMIN_USER} created; admins bypass topic access control"
    else
      echo "[entrypoint] ERROR: could not create ${NTFY_ADMIN_USER}" >&2
    fi
  fi
else
  echo "[entrypoint] NTFY_ADMIN_USER or NTFY_ADMIN_PASSWORD empty: skipping user creation"
fi

wait "${serve_pid}"
