## Gestión de credenciales y Docker secrets

Para máxima seguridad, todas las credenciales y claves sensibles deben gestionarse únicamente con Docker secrets. No definas contraseñas ni tokens en archivos .env ni en template.env.

### Secrets recomendados:

- OMRS_DB_PASSWORD
- OMRS_DB_R_PASSWORD
- OMRS_DB_BACKUP_USER
- OMRS_DB_BACKUP_PASSWORD
- MYSQL_ROOT_PASSWORD
- BACKUP_ENCRYPTION_PASSWORD
- KEYCLOAK_DB_PASSWORD
- KEYCLOAK_ADMIN_PASSWORD
- GHP_USERNAME
- GHP_PASSWORD

### Ejemplo para crear secrets:

```bash
echo "<valor>" | docker secret create OMRS_DB_PASSWORD -
echo "<valor>" | docker secret create OMRS_DB_R_PASSWORD -
echo "<valor>" | docker secret create OMRS_DB_BACKUP_USER -
echo "<valor>" | docker secret create OMRS_DB_BACKUP_PASSWORD -
echo "<valor>" | docker secret create MYSQL_ROOT_PASSWORD -
echo "<valor>" | docker secret create BACKUP_ENCRYPTION_PASSWORD -
echo "<valor>" | docker secret create KEYCLOAK_DB_PASSWORD -
echo "<valor>" | docker secret create KEYCLOAK_ADMIN_PASSWORD -
echo "<valor>" | docker secret create GHP_USERNAME -
echo "<valor>" | docker secret create GHP_PASSWORD -
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
