#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env/00-config.sh"

echo "=== Esperando a que el contenedor '${CONT_NAME}' esté en estado healthy ==="
until [ "$(docker inspect --format='{{.State.Health.Status}}' "${CONT_NAME}" 2>/dev/null)" == "healthy" ]; do
  echo "Estado actual: $(docker inspect --format='{{.State.Health.Status}}' "${CONT_NAME}" 2>/dev/null || echo 'desconocido'). Reintentando en 10s..."
  sleep 10
done

echo "=== ¡El contenedor '${CONT_NAME}' está HEALTHY y listo! ==="
