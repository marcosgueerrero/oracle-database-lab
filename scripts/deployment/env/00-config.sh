#!/usr/bin/env bash
export CONT_NAME="oralab-26ai"
export VOL_NAME="oralab-26ai-data"
export IMG="container-registry.oracle.com/database/free:latest"
export PORT_DB="1521"
export PORT_ORDS="8080"
export PDB_NAME="FREEPDB1"
export EVID="docs/bitacora/evidencia"
export ts="$(date -u +%Y%m%dT%H%M%SZ)"
