#!/bin/bash

# Define the directory containing the docker-compose.yml file
MODE="development"
COMPOSE_DIR="../"
ENV_FILE="enviromentVariables.env"
INCLUDE_SSO=false

# Function to display mode of deployment
usage() {
    echo "Usage: $0 -m [production|development] [-s|--sso]"
    echo "  -m: deployment mode (production|development)"
    echo "  -s, --sso: include Keycloak SSO services (optional)"
    exit 1
}

# Parse options
while [[ $# -gt 0 ]]; do
    case $1 in
        -m)
            if [[ "$2" == "production" || "$2" == "development" ]]; then
                MODE="$2"
                shift 2
            else
                usage
            fi
            ;;
        -s|--sso)
            INCLUDE_SSO=true
            shift
            ;;
        *)
            usage
            ;;
    esac
done

# Ensure mode is set
if [[ -z "$MODE" ]]; then
    usage
fi

# Navigate to the directory containing the docker-compose.yml file
cd "$COMPOSE_DIR" || { echo "Directory $COMPOSE_DIR not found"; exit 1; }

# Stop and remove all containers defined in the docker-compose.yml file
if sudo docker compose ps -q > /dev/null 2>&1; then
    echo "Stopping and removing containers..."
    sudo docker compose down
else
    echo "No containers to stop and remove."
fi

# Remove all associated volumes
if sudo docker compose ps -q > /dev/null 2>&1; then
    echo "Removing volumes..."
    sudo docker compose down -v
else
    echo "No volumes to remove."
fi

# Define services to start
SERVICES="portainer gateway frontend backend db db-replic dns fua-generator fua-generator-db"
if [[ "$INCLUDE_SSO" == "true" ]]; then
    SERVICES="$SERVICES keycloak keycloak-db"
    echo "Including Keycloak SSO services..."
fi

# Build and start the Docker Compose stack
if [[ "$MODE" == "production" ]]; then
    echo "Starting in production mode..."
    docker compose up -d --build --env-file "$ENV_FILE" $SERVICES
else
    echo "Starting in development mode..."
    echo "WARNING: Using default environment variables. DO NOT DEPLOY IN A PRODUCTION ENVIRONMENT."
    if [[ "$INCLUDE_SSO" == "true" ]]; then
        echo "⚠️  SSO mode: Make sure to configure Keycloak variables in .env if needed"
    fi
    docker compose up -d --build $SERVICES
fi

# Check if the stack started successfully
if [ $? -eq 0 ]; then
    echo "Docker Compose stack started successfully."
    echo ""
    echo "🌐 Services available:"
    echo "   - OpenMRS: http://localhost:8080"
    if [[ "$INCLUDE_SSO" == "true" ]]; then
        echo "   - Keycloak: http://localhost:8081"
        echo "   - Keycloak Admin: http://localhost:8081/admin"
        echo ""
        echo "👤 Default SSO users:"
        echo "   - admin/Admin123 (System Developer)"
        echo "   - doctor/Doctor123 (Provider)"
        echo "   - nurse/Nurse123 (Provider)"
        echo "   - clerk/Clerk123 (Data Assistant)"
    fi
    echo "   - Portainer: http://localhost:9000"
    echo ""
    echo "📋 Commands:"
    echo "   - View logs: docker compose logs -f [service]"
    echo "   - Restart: docker compose restart [service]"
    echo "   - Stop all: docker compose down"
else
    echo "ERROR: Failed to start Docker Compose stack."
    exit 1
fi
