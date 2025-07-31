#!/bin/bash

set -euo pipefail

echo "Starting Keycloak in development mode..."

/opt/keycloak/bin/kc.sh start-dev --import-realm &
KEYCLOAK_PID=$!

sleep 30

echo "Initializing realm and users..."
/opt/keycloak/bin/initialize-my-realm-and-add-users.sh

echo "OAuth2 configuration available at /opt/keycloak/bin/oauth2.properties"
echo "Copy this file to your OpenMRS application data directory to enable OAuth2 login"

wait $KEYCLOAK_PID