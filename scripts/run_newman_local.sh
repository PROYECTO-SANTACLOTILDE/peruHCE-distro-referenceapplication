#!/bin/bash
set -e

# Ir a la raíz del repo (por si el script se ejecuta desde otra carpeta)
cd "$(dirname "$0")/.."

# Asegurar carpeta de resultados
mkdir -p api-tests/results

# Ejecutar Newman con la colección y el environment de SIH.SALUS
newman run api-tests/sihsalus-api.postman_collection.json \
  -e api-tests/environments/dev.postman_environment.json \
  --reporters cli,junit \
  --reporter-junit-export "api-tests/results/newman-results-$(date +%s).xml"
