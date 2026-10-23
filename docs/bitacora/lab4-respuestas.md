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

## Parte G: memoria
- Modelo: ASMM (memory_size=0, memory_target=0, sga_target=1536M); PGA aparte con pga_aggregate_target=512M.
- Caché: ronda 1 = 355 lógicas / 261 físicas; ronda 2 = 247 lógicas / 0 físicas, acierto 1 - 0/247 = 100 %. Toda lectura física acaba en lógica; 261 > 244 bloques por cabecera de segmento y metadatos.
- Parse: literales = 1000 duros, 920 ms de CPU, 960 ms; bind = 1 análisis, 0 ms, 10 ms (~96 veces más rápido). V$SQL: 1000 cursores y 38845 KB frente a 1 cursor y 39 KB.
- PGA: automática = OPTIMAL, 0 KB en TEMP, 50 ms; manual 64 KB = 6 PASSES, 2048 KB en TEMP, 420 ms. maximum PGA (464 MB) < target (512 MB); el límite duro es pga_aggregate_limit (2 GB). VARIAS_PASADAS = 2: una es mi experimento.
- Asesor sga_target: mismo resultado con todas las SGA porque la base está casi ociosa.
- Reto: la firma 1863221789280198928 agrupa 1000 cursores de lab4_literal. Solución: variables de enlace en la aplicación (CURSOR_SHARING=FORCE solo es un parche).
- Mi entorno difiere: shared pool 896 MB (enunciado 416 MB) y no se expulsaron cursores.

## Parte H: procesos
- 86 procesos Oracle de background frente a 53 procesos Linux: unos 33 son hilos dentro de un mismo proceso Linux.
- LGWR: SPID 946 en v$process = PID 946 en /proc (db_lgwr_FREE). docker top muestra otro número porque es el PID del anfitrión (espacios de nombres de PID distintos).
- ARC0..ARC3 existen porque mi base está en ARCHIVELOG (el enunciado, en NOARCHIVELOG, no los tiene).
- Mi sesión: SID 177, SERIAL# 53361, servidor dedicado SPID 4147.
- Reto de la sesión que más consume: SID 182, SERIAL# 24278, SPID 4719, PGA usada 3,3 MB. Consulta usada: scripts/lab4/09-reto-sesion.sql (v$session JOIN v$process, filtrando sesiones de usuario ACTIVE).

## Parte I: contenedores
- SYS ve 16 datafiles desde la raíz (4+3+9) y 9 desde FREEPDB1: dentro de una PDB todas las vistas se filtran por el contenedor actual.
- V$LOG tiene filas con CON_ID 0 porque el redo es de toda la CDB; tengo 3 grupos.
- LAB4_ANALISTA recibe ORA-00942 en DBA_TABLES porque Oracle no revela lo que no puedes ver; ORA-41900 sí indica el privilegio que falta (UPDATE) porque el objeto es visible.
- C##LAB4_AUDITOR ve CON_ID 0 y 1 pero no FREEPDB1 por no tener CONTAINER_DATA. Lo igualaría a C##OPS_RO: ALTER USER c##lab4_auditor SET CONTAINER_DATA = ALL CONTAINER = CURRENT;
- Con SELECT ANY TABLE habría podido leer también ADMIN_CLINICA y el resto; el privilegio de esquema limita a un solo esquema, incluidas sus tablas futuras.
- COMMON_USER_PREFIX = C##: sin prefijo en la raíz da ORA-65096; con C## en una PDB, ORA-65094; la PDB abierta no se borra (ORA-65025).
- DBA_ en la raíz: 5 tablespaces; CDB_: 15 (5 + 10 de FREEPDB1; sin la semilla). V$LOG lee X$KCCLE (kcc = control file).

### Reto: auditor externo de ADMIN_CLINICA (diseño, no ejecutado)
- Usuario LOCAL en FREEPDB1: CREATE USER auditora_ext IDENTIFIED BY "<clave>"; GRANT CREATE SESSION TO auditora_ext;
- Privilegio mínimo: GRANT READ ANY TABLE ON SCHEMA admin_clinica TO auditora_ext;
- Último día: REVOKE READ ANY TABLE ON SCHEMA admin_clinica FROM auditora_ext; DROP USER auditora_ext;

### Parte J: correcciones de la revisión
- $ORACLE_HOME/dbs es un enlace simbólico a /opt/oracle/oradata/dbconfig/FREE/dbs. Un `ls -l` sin barra final solo muestra el enlace; con barra final (dbs/) lista spfileFREE.ora y orapwFREE, que están en el volumen. Evidencia: 11-archivos-so.dbs-enlace.
- Hallazgo para la autopsia (Parte N): el ADR (/opt/oracle/diag, 29 MB, 215 trazas) vive en la capa del contenedor, no en el volumen. Riesgo MEDIO: al recrear el contenedor se pierde el alert log, justo lo que necesita un postmortem. Acción propuesta: diagnostic_dest en almacenamiento persistente o envío centralizado de logs. No se cambia en este laboratorio porque exige reinicio y los scripts usan la ruta actual.

## Parte J: archivos
- La base son 16 datafiles (4489 MB), 3 tempfiles (124 MB), 2 control files (36 MB) y 3 redo online (600 MB). Relacionados: SPFILE, password file, ADR y 16 redo archivados (2704 MB, por mi ARCHIVELOG).
- El password file es relacionado, no parte de la base, pero sin él no hay SYSDBA remoto. SPFILE y password file viven en el volumen: dbs es un enlace a /opt/oracle/oradata/dbconfig/FREE/dbs.
- academia01.dbf mide 104865792 bytes = 100 MB + 8192 (cabecera del archivo, bloque 0).
- TEMP no se respalda: se recrea vacío.
- Puntos únicos de fallo: 2 control files en la misma carpeta y 1 miembro por grupo de redo.
- Copia en frío completa: 5249 MB (datafiles + tempfiles + control + redo) más SPFILE y password file. Con RMAN sobrarían tempfiles, redo online y el segundo control file.
- GRANT sobre V_$DIAG_ALERT_EXT (objeto), no sobre el sinónimo V$.
