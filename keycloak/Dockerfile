# Dockerfile para Keycloak (OpenMRS OAuth2)
# Basado en la imagen oficial de Keycloak, preparado para producción

FROM quay.io/keycloak/keycloak:24.0.4

# Copia opcional de un realm preconfigurado (ajusta el nombre si tienes un export)
# COPY realm-export.json /opt/keycloak/data/import/realm-export.json

# Permite usar variables de entorno definidas externamente (docker-compose o entorno host)
ENV KEYCLOAK_ADMIN=${KEYCLOAK_ADMIN_USER}
ENV KEYCLOAK_ADMIN_PASSWORD=${KEYCLOAK_ADMIN_PASSWORD}

# Arranque optimizado y modo producción, usando variables de entorno
ENTRYPOINT ["/opt/keycloak/bin/kc.sh", "start", "--optimized"]

# Documentación rápida:
# - Usa variables de entorno para la configuración (ver template-enviromentVariables.env)
# - Si tienes realm-export.json, descomenta la línea COPY para importar la configuración inicial
# - Usa un proxy inverso (NGINX, Traefik) para exponer Keycloak por HTTPS
