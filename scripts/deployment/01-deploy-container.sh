#!/usr/bin/env bash
source scripts/deployment/env/00-config.sh

if [ -f config/.env ]; then
  set -a; source config/.env; set +a
else
  echo "Error: config/.env no existe."
  exit 1
fi

echo "=== 1. Creando volumen '${VOL_NAME}' si no existe ==="
docker volume create "${VOL_NAME}" >/dev/null

echo "=== 2. Eliminando contenedor anterior '${CONT_NAME}' si existe ==="
docker rm -f "${CONT_NAME}" 2>/dev/null || true

echo "=== 3. Creando e iniciando contenedor '${CONT_NAME}' ==="
docker run -d \
  --name "${CONT_NAME}" \
  -p "${PORT_DB}:1521" \
  -p "${PORT_ORDS}:8080" \
  -e ORACLE_PWD="${ORACLE_PWD}" \
  -v "${VOL_NAME}:/opt/oracle/oradata" \
  "${IMG}"

echo "=== Contenedor iniciado correctamente ==="
