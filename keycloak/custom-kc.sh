#!/bin/bash

# SPDX-FileCopyrightText: 2025 ICRC
#
# SPDX-License-Identifier: BSD-3-Clause

# Wrapper script as docker entrypoint to run initialize-my-realm.sh in parallel to actual kc.sh (the official entrypoint).

set -e -u -o pipefail
shopt -s failglob

if [ -z "${OMRS_OAUTH_CLIENT_SECRET:-}" ]; then
  echo "ERROR: OpenMRS ClientSecret must be defined in OMRS_OAUTH_CLIENT_SECRET"
  exit 1
fi
if [ -z "${USERS_DEFAULT_PASSWORD:-}" ]; then
  echo "ERROR: Users Default Password must be defined in USERS_DEFAULT_PASSWORD"
  exit 1
fi

sh /opt/keycloak/bin/initialize-my-realm-and-add-users.sh & disown

/opt/keycloak/bin/kc.sh "$@"