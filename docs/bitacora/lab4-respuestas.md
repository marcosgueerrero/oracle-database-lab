# Informe de diagnóstico inicial (Lab 4, Parte A)

1. Los 5 datafiles de negocio (TBS_*) están en $ORACLE_HOME/dbs, carpeta no estándar. 0 salen FUERA del volumen porque en mi imagen dbs es un enlace a /opt/oracle/oradata/dbconfig/FREE/dbs. Riesgo MEDIO: sobreviven a docker rm pero dependen de un enlace que una actualización de imagen puede cambiar. Se corrige en C.
2. V000 dejó contraseñas literales en el historial de Git. Riesgo ALTO. Se invalida en D (V003).
3. 08-aplicar-migraciones.sh v1 pasa sys/<contraseña> por línea de comandos (visible con ps). Riesgo ALTO. Se corrige en D (08 v2).
4. El contenedor publica el puerto 8181 sin servicio detrás. Riesgo BAJO. Se corrige en C (05 v2).
5. Sin OMF (db_create_file_dest vacío) y sin FRA con la base en ARCHIVELOG. Riesgo MEDIO.

Orden de corrección: 2 y 3 primero (la exposición de secretos ya ocurrió y el riesgo crece con el tiempo), luego 1 (los datos están a salvo hoy), luego 4 y 5 (limpieza).

## Parte B: mínimo privilegio
- Riesgo 1: con DBA, un error de la herramienta de monitorización (un DROP en la ventana equivocada) podría destruir datos o estructuras.
- Riesgo 2: si la contraseña se filtra, el atacante tiene control total de la base; con solo lectura el daño queda limitado.
- Para leer el alert log: GRANT SELECT sobre SYS.V_$DIAG_ALERT_EXT (sobre el objeto V_$, no sobre el sinónimo V$), como se hace en la Parte J.
