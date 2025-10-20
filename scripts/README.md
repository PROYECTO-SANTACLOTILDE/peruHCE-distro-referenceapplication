# Scripts Directory

Este directorio centraliza todos los scripts utilizados en el proyecto peruHCE Distribution.

## Estructura

```
scripts/
├── backup/          # Scripts relacionados con backups de base de datos
├── database/        # Scripts de inicialización y configuración de base de datos
├── frontend/        # Scripts para el frontend (nginx, SPA)
└── utils/           # Scripts de utilidades generales
```

## Contenido por Carpeta

### backup/
Scripts para realizar backups completos e incrementales de las bases de datos master y réplica:
- `fullBackup.sh` - Backup completo
- `incrementalBackup.sh` - Backup incremental
- `generateFullBackup.sh` - Generación de backup completo
- `generateIncrementalBackup.sh` - Generación de backup incremental
- `generateFullBackupReplic.sh` - Backup completo de réplica
- `generateIncrementalBackupReplic.sh` - Backup incremental de réplica
- `resetReplica.sql` - Script SQL para resetear réplica

### database/
Scripts de inicialización de las bases de datos:
- `init-master.sh` - Inicialización de la base de datos master
- `init-slave.sh` - Inicialización de la base de datos slave/réplica
- `init-master-sql.sql` - (futuro) Script SQL para master
- `init-slave-sql.sql` - (futuro) Script SQL para slave

### frontend/
Scripts relacionados con el frontend:
- `startup.sh` - Script de inicio del contenedor nginx con el SPA

### utils/
Scripts de utilidades generales:
- `fullInit.sh` - Inicialización completa del sistema desde cero
- `creationLogs.sh` - Obtención de logs del módulo initializer
- `generateCertificate.sh` - Generación de certificados SSL autofirmados
- `rebuildService.sh` - Reconstrucción del servicio
- `bulk_form_uploader.py` - Carga masiva de formularios
- `insertar_usuarios.py` - Inserción de usuarios en el sistema
- `rebuildScriptPython.py` - Script de reconstrucción en Python
- `docker-compose-app.service` - Archivo de servicio systemd

## Uso

Los scripts están referenciados en:
- `docker-compose.yml` - Para entornos de desarrollo
- `docker-compose-prod.yml` - Para entornos de producción
- `frontend/Dockerfile` - Para la construcción del contenedor frontend

## Migración

Esta estructura fue creada para centralizar scripts que anteriormente estaban dispersos en:
- `backupScripts/` → `scripts/backup/`
- `db-config/` → `scripts/database/`
- `utils/` → `scripts/utils/`
- `frontend/startup.sh` → `scripts/frontend/`

Todas las referencias en los archivos de configuración han sido actualizadas para reflejar la nueva ubicación.
