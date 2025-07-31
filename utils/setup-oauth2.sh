#!/bin/bash

set -e

COMPOSE_DIR="../"
cd "$COMPOSE_DIR" || { echo "ERROR: Directory $COMPOSE_DIR not found"; exit 1; }

echo "Setting up OAuth2 configuration for OpenMRS..."

# Check if Keycloak container is running
if ! docker compose ps keycloak | grep -q "Up"; then
    echo "ERROR: Keycloak container is not running. Please start it first with:"
    echo "  cd $COMPOSE_DIR && docker compose up -d keycloak"
    exit 1
fi

# Check if backend container is running
if ! docker compose ps backend | grep -q "Up"; then
    echo "ERROR: OpenMRS backend container is not running. Please start it first with:"
    echo "  cd $COMPOSE_DIR && docker compose up -d backend"
    exit 1
fi

echo "Copying OAuth2 configuration from Keycloak to OpenMRS backend..."

# Copy oauth2.properties from keycloak container to backend container's application data directory
docker compose exec keycloak cat /opt/keycloak/bin/oauth2.properties | \
docker compose exec -T backend sh -c 'cat > /openmrs/data/oauth2.properties'

if [ $? -eq 0 ]; then
    echo "✅ OAuth2 configuration copied successfully!"
    echo "📋 Next steps:"
    echo "   1. Restart OpenMRS backend: docker compose restart backend"
    echo "   2. Wait for OpenMRS to fully start"
    echo "   3. Access OpenMRS at http://localhost:8080"
    echo "   4. You should be redirected to Keycloak for login"
    echo ""
    echo "🔑 Default SSO users:"
    echo "   - admin/Admin123 (System Developer)"
    echo "   - doctor/Doctor123 (Provider)"
    echo "   - nurse/Nurse123 (Provider)"
    echo "   - clerk/Clerk123 (Data Assistant)"
else
    echo "❌ Failed to copy OAuth2 configuration"
    exit 1
fi