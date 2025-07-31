# keycloak/Dockerfile
ARG KEYCLOAK_VERSION=26.3.2
FROM quay.io/keycloak/keycloak:${KEYCLOAK_VERSION}

# Variables por defecto (se pueden sobreescribir desde docker-compose)
ENV KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN:-admin}
ENV KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD:-changeme}
ENV KC_DB=postgres
ENV KC_DB_URL=jdbc:postgresql://${KC_DB_HOST:-keycloak-db}:${KC_DB_PORT:-5432}/${KC_DB_DATABASE:-keycloak}
ENV KC_DB_USERNAME=${KC_DB_USERNAME:-keycloak}
ENV KC_DB_PASSWORD=${KC_DB_PASSWORD:-keycloak}
ENV KC_HOSTNAME=${KC_HOSTNAME:-keycloak.local}
ENV KC_HOSTNAME_STRICT=${KC_HOSTNAME_STRICT:-false}
# Permite importar automáticamente el realm al arrancar
ENV KEYCLOAK_IMPORT=/opt/keycloak/data/import/realm-export.json

# Copiamos el realm y el tema custom
COPY realm-export.json /opt/keycloak/data/import/realm-export.json
COPY themes/ /opt/keycloak/themes/

# Ajustamos permisos para el usuario 1000
USER root
RUN chown -R 1000:0 /opt/keycloak/data /opt/keycloak/themes
USER 1000

# Pre-compilamos con PostgreSQL para acelerar el startup
RUN /opt/keycloak/bin/kc.sh build --db=${KC_DB}

# Al arrancar, arranca en modo dev e importa el realm
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start-dev", "--import-realm"]
