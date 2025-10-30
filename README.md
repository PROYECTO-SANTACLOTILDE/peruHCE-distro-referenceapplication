# peruHCE - Distribución OpenMRS para el Perú

## Tabla de Contenidos

- [Configuración SSL/HTTPS](#configuración-sslhttps)
- [Autenticación OIDC/Keycloak](#autenticación-oidckeycloak-en-el-frontend-spa)
- [Gestión de Credenciales](#gestión-de-credenciales-y-docker-secrets)

---

## Configuración SSL/HTTPS

peruHCE incluye soporte completo para SSL/HTTPS con certificados auto-firmados optimizados para redes hospitalarias internas.

### Inicio Rápido con SSL

```bash
# Iniciar con SSL habilitado
docker compose -f docker-compose.yml -f docker-compose-prod.yml -f docker-compose.ssl.yml up -d

# Acceder vía HTTPS
https://localhost
# o
https://sihsalus.hsc
```

### Características de Seguridad

- ✅ Certificados RSA de 4096 bits
- ✅ Soporte TLS 1.2 y 1.3
- ✅ Headers de seguridad HTTP (HSTS, CSP, X-Frame-Options, etc.)
- ✅ Renovación automática opcional
- ✅ Parámetros Diffie-Hellman de 4096 bits
- ✅ Soporte para múltiples dominios e IPs

### Documentación Completa

Para configuración avanzada, instalación de certificados en clientes, renovación, y solución de problemas, consulta:

**[📘 Guía Completa de Certificados SSL](SSL-CERTIFICATE-GUIDE.md)**

---

## Autenticación OIDC/Keycloak en el Frontend SPA

El archivo `frontend/config/oauth2.json` ahora utiliza variables de entorno para permitir la configuración dinámica de Keycloak/OIDC al levantar los contenedores.

Ejemplo de variables necesarias (agrega en tu `.env` o como variables de entorno en Docker Compose):

```
KEYCLOAK_HOST=keycloak.example.com
KEYCLOAK_REALM=mi_realm
KEYCLOAK_CLIENT_ID=frontend-spa
SPA_URL=https://spa.example.com
```

El script de inicio del frontend (`frontend_startup.sh`) aplicará automáticamente `envsubst` sobre `oauth2.json` para inyectar estos valores antes de iniciar Nginx.

**No es necesario editar manualmente el JSON para cada entorno.**

---
## Gestión de credenciales y Docker secrets

Para máxima seguridad, todas las credenciales y claves sensibles deben gestionarse únicamente con Docker secrets. No definas contraseñas ni tokens en archivos .env ni en template.env.



### Secrets requeridos (según docker-compose.yml y configuración):

- keycloak_admin_password
- keycloak_db_password
- mysql_root_password
- mysql_openmrs_password
- mysql_repl_password
- mysql_backup_password
- grafana_admin_password
- pihole_password
- fua_db_password
- fua_token
- OMRS_OCL_TOKEN (token OCL, sensible)
- BACKUP_ENCRYPTION_PASSWORD (para scripts de backup)
- GHP_USERNAME (para builds privados)
- GHP_PASSWORD (para builds privados)

### Ejemplo para crear secrets:

```bash
# Para los servicios principales:
echo "<valor>" | docker secret create keycloak_admin_password -
echo "<valor>" | docker secret create keycloak_db_password -
echo "<valor>" | docker secret create mysql_root_password -
echo "<valor>" | docker secret create mysql_openmrs_password -
echo "<valor>" | docker secret create mysql_repl_password -
echo "<valor>" | docker secret create mysql_backup_password -
echo "<valor>" | docker secret create grafana_admin_password -
echo "<valor>" | docker secret create pihole_password -
echo "<valor>" | docker secret create fua_db_password -
# Para OCL:
echo "<valor>" | docker secret create OMRS_OCL_TOKEN -
# Para backups:
echo "<valor>" | docker secret create BACKUP_ENCRYPTION_PASSWORD -
# Para builds privados:
echo "<tu_usuario_github>" | docker secret create GHP_USERNAME -
echo "<tu_token_github>" | docker secret create GHP_PASSWORD -
```

Variables de entorno NO sensibles (definir en .env o template.env):

```env
# OMRS_DB_USER=
# OMRS_DB_REPL_USER=
# TAG=qa                # Versión/tag de las imágenes Docker (ej: qa, latest, prod)
# KEYCLOAK_ADMIN=admin  # Usuario admin de Keycloak
# KC_DB_DATABASE=keycloak   # Base de datos de Keycloak
# KC_DB_USERNAME=keycloak   # Usuario de la base de datos de Keycloak
# KC_HOSTNAME=localhost     # Hostname de Keycloak
# KEYCLOAK_PORT=8180        # Puerto de Keycloak expuesto
# OPENMRS_DB_USER=openmrs   # Usuario de la base de datos OpenMRS
# OMRS_OCL_TOKEN=           # Token OCL (si aplica)
# OMRS_DB_BACKUP_USER=openmrs_backup   # Usuario para backups de OpenMRS
# HOSPITAL_GATEWAY=192.168.1.1         # Gateway/red hospital
# HOSPITAL_NETWORK=192.168.1.0/24      # Red hospital
# PERUHCE_FUA_GEN_DB_USER=fuagenerator # Usuario BD FUA Generator
# PERUHCE_FUA_GEN_DB=fuagenerator      # Nombre BD FUA Generator
# GRAFANA_ADMIN_USER=admin             # Usuario admin de Grafana
```

Recomendación: Copia y renombra `template.env` a `.env` y personaliza los valores según tu entorno antes de levantar los servicios.
```

Los scripts y servicios están preparados para leer primero de Docker secrets (ubicados en `/run/secrets/NOMBRE_SECRET`). Si no existe el secret, intentarán usar la variable de entorno correspondiente.

Consulta el archivo `template.env` para ver solo variables no sensibles.
## Uso de credenciales seguras con Docker secrets

Para descargar dependencias privadas desde GitHub Packages durante el build de la imagen backend, este proyecto utiliza Docker secrets en lugar de variables de entorno. Esto mejora la seguridad y evita exponer credenciales sensibles.

### ¿Cómo crear y usar los secrets?

1. Crea los secrets antes de construir la imagen:
  ```bash
  echo "<tu_usuario_github>" | docker secret create GHP_USERNAME -
  echo "<tu_token_github>" | docker secret create GHP_PASSWORD -
  ```

2. Al construir la imagen, Docker los montará automáticamente y el build los usará para autenticarse en Maven.

3. Ya no es necesario definir las variables de entorno `GHP_USERNAME` ni `GHP_PASSWORD` en el sistema ni en archivos `.env`.

4. El archivo `credentials/settings.xml.template` está preparado para tomar las credenciales desde el entorno exportado por el build.

**Importante:** Si cambias tus credenciales, elimina y vuelve a crear los secrets.

Para más información sobre Docker secrets: https://docs.docker.com/engine/swarm/secrets/

## Políticas de Seguridad: Cifrado de Backups y Retención de Logs

Este proyecto implementa:
- **Cifrado automático de backups**: Todos los archivos de respaldo generados por los scripts se cifran con AES-256 usando openssl. La clave se provee vía la variable de entorno `BACKUP_ENCRYPTION_PASSWORD` (recomendado: Docker secrets). El backup sin cifrar se elimina tras el cifrado exitoso.
- **Rotación y retención de logs**: Los scripts de backup mantienen solo los últimos 5 archivos de log, eliminando los más antiguos automáticamente.

Estas medidas contribuyen al cumplimiento de HIPAA y mejores prácticas de seguridad.

# OpenMRS 3.0 Reference Application

This project holds the build configuration for the OpenMRS 3.0 reference application, found on
https://dev3.openmrs.org and https://o3.openmrs.org.

## Quick start

### Package the distribution and prepare the run

```
docker compose build
```

### Run the app

```
docker compose up
```

The new OpenMRS UI is accessible at http://localhost/openmrs/spa

OpenMRS Legacy UI is accessible at http://localhost/openmrs

## Overview

This distribution consists of four images:

* db - This is just the standard MariaDB image supplied to use as a database
* backend - This image is the OpenMRS backend. It is built from the main Dockerfile included in the root of the project and
  based on the core OpenMRS Docker file. Additional contents for this image are drawn from the `distro` sub-directory which
  includes a full Initializer configuration for the reference application intended as a starting point.
* frontend - This image is a simple nginx container that embeds the 3.x frontend, including the modules described in  the
  `frontend/spa-build-config.json` file.
* proxy - This image is an even simpler nginx reverse proxy that sits in front of the `backend` and `frontend` containers
  and provides a common interface to both. This helps mitigate CORS issues.

## Contributing to the configuration

This project uses the [Initializer](https://github.com/mekomsolutions/openmrs-module-initializer) module
to configure metadata for this project. The Initializer configuration can be found in the configuration
subfolder of the distro folder. Any files added to this will be automatically included as part of the
metadata for the RefApp.

Eventually, we would like to split this metadata into two packages:

* `openmrs-core`, which will contain all the metadata necessary to run OpenMRS
* `openmrs-demo`, which will include all of the sample data we use to run the RefApp

The `openmrs-core` package will eventually be a standard part of the distribution, with the `openmrs-demo`
provided as an optional add-on. Most data in this configuration _should_ be regarded as demo data. We
anticipate that implementation-specific metadata will replace data in the `openmrs-demo` package,
though they may use that metadata as a starting point for that customization.

To help us keep track of things, we ask that you suffix any files you add with either
`-core_demo` for files that should be part of the demo package and `-core_data` for
those that should be part of the core package. For example, a form named `test_form.json` would become
`test_core-core_demo.json`.

Frontend configuration can be found in `frontend/config-core.json`.

Thanks!
