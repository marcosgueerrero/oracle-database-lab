#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "${SCRIPT_DIR}/env/00-config.sh"
source config/.env

mkdir -p "${EVID}/spool"
OUT_FILE="${EVID}/spool/verificacion_${ts}.txt"

echo "=== Generando reporte de verificación en ${OUT_FILE} ==="

docker exec -i "${CONT_NAME}" sqlplus -s "sys/${ORACLE_PWD}@${PDB_NAME} as sysdba" <<SQL > "${OUT_FILE}"
SET LINESIZE 200 PAGESIZE 100 HEADING ON FEEDBACK ON;

PROMPT ====================================================
PROMPT 1. TABLESPACES CREADOS
PROMPT ====================================================
SELECT tablespace_name, status, contents 
FROM dba_tablespaces 
WHERE tablespace_name LIKE 'TS_%'
ORDER BY tablespace_name;

PROMPT
PROMPT ====================================================
PROMPT 2. USUARIOS Y ESQUEMAS CONFIGURADOS
PROMPT ====================================================
SELECT username, account_status, default_tablespace, created 
FROM dba_users 
WHERE username LIKE 'USR_%'
ORDER BY username;

PROMPT
PROMPT ====================================================
PROMPT 3. TABLAS POR ESQUEMA CREADAS
PROMPT ====================================================
SELECT owner, table_name, tablespace_name 
FROM dba_tables 
WHERE owner LIKE 'USR_%'
ORDER BY owner, table_name;

SQL

cat "${OUT_FILE}"
