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

## Parte K: bloque y fila
- ROWID de la fila 101: AAAR2lAAAAAAAMOAAF = objeto AAAR2l (17*64^2+54*64+37 = 73125, coincide con DATA_OBJECT_ID), archivo AAA (0, BIGFILE), bloque AAAAMO (12*64+14 = 782), fila AAF (5).
- avsp = fseo - fsbo: 0x427 - 0xc6 = 1063 - 198 = 865 = 0x361. nrow=90; hsiz 0xc6 = 14 + 4 + 90*2.
- ITL ranura 1: --U-, Lck 90 = limpieza diferida de bloques (el COMMIT no revisita los bloques). Un UPDATE de la fila 101 usaría la ranura 2 libre o limpiaría antes la 1.
- Fila 101: tl 78 = 3 (fb, lb, cc) + 7 (bytes de longitud) + 68 (datos); 80 con la entrada del directorio. AVG_ROW_LEN 76 es media de estadísticas.
- Caben 90 filas: con 865 libres, otra fila (80) dejaría 785 < 809 (PCTFREE 10 de 8088).
- Fecha de la fila: bytes 78 7e 0a 16 13 3b 12 -> 2026-10-22 18:58:17 (carga de V002).
- Espacio: 230 llenos + 1 + 13 = 244 bloques bajo la HWM; 17 extensiones (16 de 64 KB + 1 de 1 MB); 256 bloques asignados. TBS_ACADEMIA es BIGFILE: relative_fno 1024, hay que usar 'BIGFILE' en ROWID_BLOCK_NUMBER.
- Reto "abre otro bloque": no realizado todavía.

## Parte D (ampliación)
- No se edita V000 porque ya se aplicó: una migración aplicada es historia, y el repositorio debe describir lo que se ejecutó. Se corrige con una migración nueva (V003).
- Invalidar la contraseña es mejor que borrarla del archivo: la contraseña sigue en el historial de Git, así que se da por comprometida. NO AUTHENTICATION la hace inservible (ORA-01017 al probar la antigua) aunque alguien la conozca.
- Cuentas de solo esquema: poseen los objetos pero nadie puede iniciar sesión con ellas; su ACCOUNT_STATUS sigue OPEN porque no están bloqueadas, simplemente no tienen forma de autenticarse (distinto de ACCOUNT LOCK, que se puede desbloquear).
- 08 v2 usa "/ as sysdba" (autenticación del sistema operativo dentro del contenedor): ya no pasa sys/<contraseña> en la línea de comandos, visible con ps y en los eventos de docker.
- V002 carga 20000 estudiantes, 40 asignaturas y 60000 matrículas; es idempotente (comprueba si ya hay filas), por eso la 2ª ejecución no insertó nada. La fila 101 (00000101X, ACTIVO) es el ejemplo continuo.
- Pregunta P-D1: respuesta C (ALTER USER ... NO AUTHENTICATION).

## Parte L: capacidad y coste
- bfr (U3) = floor((8192-96)*0.9/76) = 95 -> b = 211; bfr (Oracle) = 93 -> b = 216; medido: 231 bloques con filas (media 86,6); estadísticas: 244 (230 llenos + 1 + 13 casi vacíos); asignados: 256. La fórmula es un modelo: ignora filas de 78-80 bytes, bloques vacíos al final y asignación por extensiones.
- Costes medidos: lógica 3,23 us; física aleatoria 107,5 us; secuencial 59,4 us/bloque (131 MB/s, ~84 bloques/petición).
- T_secuencial 273 ms; T_aleatorio = 4597 x 107,5 us = 494 ms (1,8 veces). Cociente 0,553; umbral 0,64 % de las filas.
- HDD (150 MB/s, 5 ms): c_sec ~52 us, cociente ~0,0104, umbral ~0,012 %. Mismo método, otro hardware, otra decisión.
- Las lecturas físicas son rápidas porque FLUSH BUFFER_CACHE no vacía la caché de páginas de Linux.
- Esperas de instancia: sequential 288 us, scattered 647 us, direct path 1266 us.
- Reto ACA_MATRICULAS: predicción ~330 bloques con R~40 (completar con AVG_ROW_LEN real); asignados 384.

### Parte L: corrección del reto ACA_MATRICULAS
- AVG_ROW_LEN real = 30, no 40. Predicción U3: bfr = floor(8096*0.9/30) = 242, b = ceil(60000/242) = 248 bloques. Real: 370 bajo la HWM (384 asignados). La fórmula no cuenta el directorio de filas, la cabecera de fila, la ITL ni el espacio libre al final del segmento.
- Recorrido completo en HDD a 150 MB/s: 370 x 8 KB / 150 MB/s = ~20 ms.

## Parte M: filas migradas y encadenadas
- PCTFREE 0 + UPDATE de 1 a 300 bytes en 1 de cada 5 filas: CHAIN_CNT 1000 (20 %), la tabla pasa de 13 a 58 bloques. CHAIN_CNT no distingue migradas de encadenadas y solo lo rellena ANALYZE, no DBMS_STATS.
- Coste: 3,2 lecturas lógicas por búsqueda = (800*3 + 200*4)/1000; table fetch continued row = 200. Un 7 % más de trabajo por acceso.
- Bloque: cabeza con fb --H----- y nrid 0x1625.0 (bloque 5669 en BIGFILE). Fila normal: --H-FL--.
- Encadenamiento: ANCHA (fila de ~12000 bytes) no cabe en ningún bloque de 8 KB, CHAIN_CNT 1; MOVE no lo cura, solo bloque mayor o rediseño.
- Cura: MOVE PCTFREE 20 deja CHAIN_CNT 0 (63 bloques) pero el índice queda UNUSABLE porque cambian los ROWID; REBUILD, o MOVE ONLINE en producción.
- Mi ejecución: fila listada id 2200, archivo 24, bloque 5643, ranura 0.
