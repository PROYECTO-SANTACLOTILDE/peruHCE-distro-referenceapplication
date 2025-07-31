#!/bin/bash

set -euo pipefail

echo "Starting Keycloak in development mode..."

/opt/keycloak/bin/kc.sh start-dev --import-realm &
KEYCLOAK_PID=$!

sleep 30

echo "Initializing realm and users..."
/opt/keycloak/bin/initialize-my-realm-and-add-users.sh

wait $KEYCLOAK_PID