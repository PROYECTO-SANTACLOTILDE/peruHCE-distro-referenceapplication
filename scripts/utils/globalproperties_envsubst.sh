#!/bin/bash
# Sustituye variables de entorno en los archivos globalproperties antes de arrancar OpenMRS
set -e

CONFIG_DIR="/openmrs/distribution/openmrs_config/configuration/globalproperties"

for f in "$CONFIG_DIR"/*.xml; do
  if [ -f "$f" ]; then
    echo "[INFO] Sustituyendo variables de entorno en $f"
    envsubst < "$f" > "$f.tmp" && mv "$f.tmp" "$f"
  fi
done

# Ejecutar el comando original (OpenMRS)
exec "$@"