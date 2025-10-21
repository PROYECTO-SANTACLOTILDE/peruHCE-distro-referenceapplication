
#!/bin/bash
# ------------------------------------------------------------------------------
# Script: backup_incremental.sh
# Descripción: Realiza un backup incremental de la base de datos MariaDB del contenedor especificado.
# Uso: ./backup_incremental.sh [--container NOMBRE] [--dir DIRECTORIO] [--max N]
# Autor: Equipo PeruHCE
# Fecha: 2025-10-20
# ------------------------------------------------------------------------------

set -euo pipefail

CONTAINER_NAME="${CONTAINER_NAME:-peruHCE-db-master}"
FULL_BACKUP_DIR="${FULL_BACKUP_DIR:-/home/${USER}/peruHCE-fullBackups}"
MAX_BACKUPS="${MAX_BACKUPS:-10}"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
BACKUP_NAME="incr_$TIMESTAMP"
TEMP_FULL_BACKUP_PATH="/backup/full"
TEMP_INCR_BACKUP_PATH="/backup/inc"

# Parseo de argumentos
while [[ $# -gt 0 ]]; do
    case $1 in
        --container)
            CONTAINER_NAME="$2"; shift 2;;
        --dir)
            FULL_BACKUP_DIR="$2"; shift 2;;
        --max)
            MAX_BACKUPS="$2"; shift 2;;
        *)
            echo "Uso: $0 [--container NOMBRE] [--dir DIRECTORIO] [--max N]"; exit 1;;
    esac
done

LOG_FILE="$FULL_BACKUP_DIR/incrementalBackup_log.txt"
mkdir -p "$FULL_BACKUP_DIR"
exec > >(tee -a "$LOG_FILE") 2>&1

echo "[INFO] Iniciando backup incremental $TIMESTAMP para contenedor $CONTAINER_NAME"

if ! docker ps -a --format '{{.Names}}' | grep -q "^$CONTAINER_NAME$"; then
    echo "[ERROR] Contenedor '$CONTAINER_NAME' no encontrado."; exit 1
fi

# Verificar directorio de backups
if [ ! -d "$FULL_BACKUP_DIR" ]; then
    echo "[ERROR] Directorio '$FULL_BACKUP_DIR' no existe."; exit 1
fi

# Crear backup incremental dentro del contenedor
docker exec --user root "$CONTAINER_NAME" mariadb-backup --user=root --password="${OMRS_DB_R_PASSWORD:-openmrs_r}" --backup --incremental-basedir="$TEMP_FULL_BACKUP_PATH" --target-dir="$TEMP_INCR_BACKUP_PATH"

# Copiar backup al host
docker cp "$CONTAINER_NAME:$TEMP_INCR_BACKUP_PATH" "$FULL_BACKUP_DIR/$BACKUP_NAME"

# Comprimir backup
tar -czf "$FULL_BACKUP_DIR/$BACKUP_NAME.tar.gz" -C "$FULL_BACKUP_DIR" "$BACKUP_NAME"
rm -rf "$FULL_BACKUP_DIR/$BACKUP_NAME"

# Rotar backups antiguos
BACKUP_COUNT=$(ls -1 "$FULL_BACKUP_DIR"/*.tar.gz 2>/dev/null | wc -l)
if [ "$BACKUP_COUNT" -gt "$MAX_BACKUPS" ]; then
    ls -1t "$FULL_BACKUP_DIR"/*.tar.gz | tail -n +$((MAX_BACKUPS+1)) | xargs rm -f
    echo "[INFO] Se eliminaron backups antiguos, manteniendo los últimos $MAX_BACKUPS."
fi

echo "[OK] Backup incremental realizado en '$FULL_BACKUP_DIR/$BACKUP_NAME.tar.gz'"

# List Temporal backups
fullBackups=($(ls -t "$FULL_BACKUP_DIR"))

# Check if directory is empty
if [ ${#fullBackups[@]} -eq 0 ]; then
    echo "No backups found in directory: $FULL_BACKUP_DIR"
    exit 1
fi

# Display numbered list of files
echo
echo "Available backups in $FULL_BACKUP_DIR (newest first):"
echo "------------------------------------------------------------------------------------------------------------------------"
echo "------------------------------------------------------------------------------------------------------------------------"
for ((i=0; i<${#fullBackups[@]}; i++)); do
    printf "%2d) %s\n" "$((i+1))" "${fullBackups[i]}"
    echo "------------------------------------------------------------------------------------------------------------------------"
done
echo "------------------------------------------------------------------------------------------------------------------------"


# Get user selection
while true; do
    read -p "Enter the number of the file you want to select (1-${#fullBackups[@]}): " selection
    
    # Validate input
    if [[ "$selection" =~ ^[0-9]+$ ]] && [ "$selection" -ge 1 ] && [ "$selection" -le ${#fullBackups[@]} ]; then
        selected_file="${fullBackups[$((selection-1))]}"
        full_path="$FULL_BACKUP_DIR/$selected_file"
        break
    else
        echo "Invalid selection. Please enter a number between 1 and ${#files[@]}."
    fi
done

# selection has the index selected and selected_file  the name of the file selected
#echo $selection
#echo $selected_file

# Erase previous files in back dir in master container
echo -e "\nErase backup directory in container"
docker exec ${CONTAINER_NAME} bash -c "rm -rf /backup/*"

# Create the directories in master container
echo -e "\nCreate the backup directories"
docker exec ${CONTAINER_NAME} bash -c "mkdir -p $TEMP_FULL_BACKUP_PATH"
docker exec ${CONTAINER_NAME} bash -c "mkdir -p $TEMP_INCR_BACKUP_PATH"

# Create temporal directory
echo -e "\nCreate temporal directory to unzip backup"
rm -rf ${TEMP_BACKUP_PATH}
mkdir -p ${TEMP_BACKUP_PATH}

# Unzip full backup in temporal directory
echo -e "\nUnzip backup in temporal directory"
tar -xzvf ${full_path} -C "${TEMP_BACKUP_PATH}" > /dev/null

# Copy unzipped full backup to container with dummy container
echo -e "\nCopy unzipped full backup to container"
docker cp $PWD/tmpFull/. ${CONTAINER_NAME}:${TEMP_FULL_BACKUP_PATH}

# Set backup to use with dummy container
echo -e "\nSet backup to use with dummy container"
docker exec ${CONTAINER_NAME} bash -c "mariadb-backup --prepare --target-dir=/backup/full"

# Stop db containers
echo -e "\nStopping database containers"
docker compose stop db-replic
docker compose stop db

# Free var/lib/mysql dir in db master
echo -e "\nFree var/lib/mysql dir in db master"
docker run --rm -v ${NAME_PREFIX}db-data:/var/lib/mysql busybox sh -c "rm -rf /var/lib/mysql/**"


# Execute dummy container to fill var/lib/mysql 
echo -e "\nRestore with backup"
docker run --rm --name mariadb-dummy -v ${NAME_PREFIX}db-data:/var/lib/mysql -v ${NAME_PREFIX}db-backup:/backup --user root mariadb:10.11.7 mariadb-backup --copy-back --target-dir=/backup/full


# Erase temporal folder of unzipped backup
echo -e "\nErase temporal folder of unzipped backup"
rm -rf tempFull/

# Resume docker compose stack
echo -e "\nResume docker compose stack"
docker compose up -d

# Get db master info
docker exec -it $CONTAINER_NAME mariadb -uroot -p -e "SHOW MASTER STATUS"

# Synchronize replic db container
echo -e "\nTo synchronize replic database container ..."

# Stop db replic container
docker compose db-replic stop

# Execeute 

exit 1



