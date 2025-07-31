FROM quay.io/keycloak/keycloak:26.3.2

# Copiar archivos de configuración
COPY realm-export.json /opt/keycloak/data/import/
COPY themes/ /opt/keycloak/themes/

# Configurar permisos
USER root
RUN chown -R 1000:0 /opt/keycloak/data
RUN chown -R 1000:0 /opt/keycloak/themes
USER 1000

# Pre-configurar la base de datos para optimización
RUN /opt/keycloak/bin/kc.sh build --db=postgres