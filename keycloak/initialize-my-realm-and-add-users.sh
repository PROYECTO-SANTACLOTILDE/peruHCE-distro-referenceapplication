#!/bin/bash

set -euo pipefail

KEYCLOAK_BASE_URL="http://localhost:8080"
ADMIN_USERNAME="${KEYCLOAK_ADMIN_USER:-admin}"
ADMIN_PASSWORD="${KEYCLOAK_ADMIN_PASSWORD:-admin}"
REALM_NAME="${KEYCLOAK_REALM:-openmrs}"
CLIENT_ID="${KEYCLOAK_CLIENT_ID:-openmrs}"
CLIENT_SECRET="${KEYCLOAK_CLIENT_SECRET:-openmrs-secret}"

echo "Waiting for Keycloak to be ready..."
until curl -s -f "${KEYCLOAK_BASE_URL}/health/ready" > /dev/null; do
    echo "Waiting for Keycloak..."
    sleep 5
done

echo "Keycloak is ready. Getting admin token..."

# Get admin token
ADMIN_TOKEN=$(curl -s -X POST "${KEYCLOAK_BASE_URL}/realms/master/protocol/openid-connect/token" \
    -H "Content-Type: application/x-www-form-urlencoded" \
    -d "username=${ADMIN_USERNAME}" \
    -d "password=${ADMIN_PASSWORD}" \
    -d "grant_type=password" \
    -d "client_id=admin-cli" | jq -r '.access_token')

if [ "$ADMIN_TOKEN" == "null" ] || [ -z "$ADMIN_TOKEN" ]; then
    echo "Failed to get admin token"
    exit 1
fi

echo "Admin token obtained. Creating realm..."

# Create realm
curl -s -X POST "${KEYCLOAK_BASE_URL}/admin/realms" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"realm\": \"${REALM_NAME}\",
        \"enabled\": true,
        \"displayName\": \"OpenMRS Realm\",
        \"loginWithEmailAllowed\": true,
        \"duplicateEmailsAllowed\": false
    }" || echo "Realm may already exist"

echo "Realm created/verified. Creating client..."

# Create client
curl -s -X POST "${KEYCLOAK_BASE_URL}/admin/realms/${REALM_NAME}/clients" \
    -H "Authorization: Bearer ${ADMIN_TOKEN}" \
    -H "Content-Type: application/json" \
    -d "{
        \"clientId\": \"${CLIENT_ID}\",
        \"enabled\": true,
        \"redirectUris\": [\"http://localhost:8080/openmrs/oauth2/callback\", \"http://localhost/openmrs/oauth2/callback\"],
        \"webOrigins\": [\"http://localhost:8080\", \"http://localhost\"],
        \"protocol\": \"openid-connect\",
        \"publicClient\": false,
        \"secret\": \"${CLIENT_SECRET}\",
        \"serviceAccountsEnabled\": true,
        \"authorizationServicesEnabled\": false,
        \"standardFlowEnabled\": true,
        \"directAccessGrantsEnabled\": true
    }" || echo "Client may already exist"

echo "Client created/verified. Creating users from CSV..."

# Read users from CSV and create them
while IFS=',' read -r username password email firstName lastName roles
do
    if [[ "$username" != "username" ]]; then # Skip header
        echo "Creating user: $username"
        
        # Create user
        curl -s -X POST "${KEYCLOAK_BASE_URL}/admin/realms/${REALM_NAME}/users" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" \
            -H "Content-Type: application/json" \
            -d "{
                \"username\": \"${username}\",
                \"email\": \"${email}\",
                \"firstName\": \"${firstName}\",
                \"lastName\": \"${lastName}\",
                \"enabled\": true,
                \"emailVerified\": true,
                \"attributes\": {
                    \"roles\": [\"${roles}\"]
                }
            }" || echo "User $username may already exist"
        
        # Get user ID
        USER_ID=$(curl -s -X GET "${KEYCLOAK_BASE_URL}/admin/realms/${REALM_NAME}/users?username=${username}" \
            -H "Authorization: Bearer ${ADMIN_TOKEN}" | jq -r '.[0].id')
        
        if [ "$USER_ID" != "null" ] && [ -n "$USER_ID" ]; then
            # Set password
            curl -s -X PUT "${KEYCLOAK_BASE_URL}/admin/realms/${REALM_NAME}/users/${USER_ID}/reset-password" \
                -H "Authorization: Bearer ${ADMIN_TOKEN}" \
                -H "Content-Type: application/json" \
                -d "{
                    \"type\": \"password\",
                    \"value\": \"${password}\",
                    \"temporary\": false
                }"
            echo "Password set for user: $username"
        fi
    fi
done < /opt/keycloak/bin/users.csv

echo "Keycloak initialization completed successfully!"