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

## Parte C: reto OMF (que no vuelva a pasar)
- Comando: ALTER SYSTEM SET db_create_file_dest='/opt/oracle/oradata/FREE/FREEPDB1' SCOPE=BOTH; (ejecutado dentro de FREEPDB1).
- SCOPE=BOTH: se aplica ya en memoria y queda en el SPFILE, así que sobrevive al reinicio.
- Efecto: un CREATE TABLESPACE tbs_x; sin cláusula DATAFILE crea el archivo automáticamente (OMF) dentro de esa carpeta, es decir, dentro del volumen. Una ruta relativa ya no puede dejar archivos fuera.
- Hallazgos de la Parte C: 5 datafiles reubicados, 0 salían FUERA porque mi imagen enlaza dbs con el volumen, persistencia demostrada (mismas tablas por esquema antes y después), puerto 8181 eliminado.

## Parte D
- V003 deja los ADMIN_* como cuentas de solo esquema (AUTHENTICATION_TYPE NONE, estado OPEN). La contraseña vieja da ORA-01017.
- V002 es idempotente: la 2ª ejecución dijo "ya aplicada" y no insertó nada.

## Parte E: instancia, arranque por etapas y alert log
- ORA-01507 (NOMOUNT): v$database lee el control file, aún cerrado; v$parameter sí responde porque los parámetros están en memoria.
- ORA-01219 (MOUNT): dba_tables está en SYSTEM, datafile aún cerrado; solo V$ y X$ responden.
- FREEPDB1 se abrió sola en READ WRITE gracias a SAVE STATE (dba_pdb_saved_states: OPEN).
- Alert log: ORA-00800 [Set Priority Failed] VKTM/LGWR = conocido (el contenedor no permite subir prioridad). ORA-27300..27303 chdir() = ruido del arranque del contenedor, a documentar. Sin recuperación de instancia real: las PDB estaban cerradas limpiamente (Crash Recovery excluding pdb 2/3).
- Mi entorno difiere: 3 miembros de redo de 201 MB, ARCHIVELOG, 62 procesos de background.

### Parte E: parte del reinicio (reto)
- Parada solicitada (SHUTDOWN IMMEDIATE): 19:00:58 UTC (21:00:58 hora de Madrid).
- Apertura: mount a las 19:01:09 UTC y OPEN completado a las 19:01:12 UTC. Reinicio total: unos 14 segundos.
- Recuperación de instancia: no. Las PDB 2 y 3 estaban cerradas limpiamente (Crash Recovery excluding pdb 2/3).
- ORA-00800 [Set Priority Failed] VKTM/LGWR: conocido (el contenedor no permite subir prioridad); se excluye de alertas.
- ORA-27300..27303 (chdir() failed): a investigar. Aparece una sola vez, en un arranque previo a mis pruebas.

## Parte F: parámetros
- El SPFILE guarda 18 parámetros especificados de 564 documentados; v$parameter = memoria, v$spparameter = SPFILE (db_files: memoria 200, SPFILE 300 hasta el reinicio; RESET lo borra).
- PROCESSES: v$parameter dice IMMEDIATE pero da ORA-02095; en la práctica es estático porque dimensiona la SGA al arrancar.
- ORA-65040: processes no se puede cambiar desde una PDB. open_cursors sí (ISPDB_MODIFIABLE=TRUE).
- db_create_file_dest sale vacío desde CDB$ROOT porque lo fijé solo dentro de FREEPDB1.

### Change request: open_cursors 300 -> 1000
- Valor actual: 300, en el SPFILE y en memoria.
- Propuesto: 1000. Antes investigar ORA-01000: suele ser fuga de cursores de la aplicación; subir el límite solo retrasa el problema.
- SCOPE: BOTH (dinámico, inmediato y persistente); si afecta a una sola PDB, aplicarlo dentro de ella.
- Prueba: primero SCOPE=MEMORY, vigilando v$open_cursor y el alert log.
- Rollback: ALTER SYSTEM SET open_cursors=300 SCOPE=BOTH; (o RESET).
- Evidencia: PFILE antes y después versionados en git, y ticket asociado.
