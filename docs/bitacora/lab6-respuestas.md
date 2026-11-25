# LAB 6 — Respuestas de comprobación y simulacro

## 9. Preguntas de comprobación

### 9.1. Partes A-C · Rol operativo, parámetros y estados

**1. ¿Cuántos errores ORA- tenía tu alert log en 24 h en la Parte B y a qué se debían? ¿Por qué ese número no es una alarma por sí solo?**

En mi ejecución se contabilizaron 4 errores ORA- en las últimas 24 horas. Para interpretar este número hay que revisar los códigos y mensajes concretos del alert log y comprobar en qué operaciones se produjeron. Un error generado durante una prueba controlada no implica necesariamente que exista un problema real en la base de datos. Por eso no basta con contar los errores, sino que hay que estudiar su contexto y comprobar si afectan al funcionamiento del servicio.

**2. ¿A qué hora empieza y cuánto dura la ventana de mantenimiento de un miércoles en tu base? ¿Qué tareas automáticas corren en ella?**

La ventana WEDNESDAY_WINDOW comienza los miércoles a las 22:00 y tiene una duración de 4 horas, hasta las 02:00 del jueves. Está habilitada. Entre las tareas automáticas de mantenimiento se encuentran la recopilación de estadísticas del optimizador, el asesor automático de espacio y el asesor de ajuste SQL. En mi ejecución los tres clientes aparecían habilitados.

**3. Explica con tu salida de la Parte C la diferencia entre lo que mostraban V$SPPARAMETER y V$PARAMETER tras el SCOPE = SPFILE. ¿Qué habría pasado en el siguiente reinicio sin el RESET?**

Al utilizar SCOPE=SPFILE, el cambio de db_files se guardó en el archivo de parámetros para el siguiente arranque, pero no modificó el valor que estaba utilizando la instancia en ese momento. Por eso V$SPPARAMETER mostraba el valor pendiente y V$PARAMETER seguía mostrando el valor activo. Sin ejecutar RESET, Oracle habría arrancado con el nuevo valor de 250.

**4. ¿Por qué RESET fue la vuelta atrás correcta para db_files y no lo habría sido para processes? Cita la línea de tu PFILE que lo demuestra.**

RESET fue correcto para db_files porque permitió eliminar el valor específico que habíamos añadido al SPFILE y recuperar el valor predeterminado de Oracle. No habría sido adecuado eliminar de la misma manera el parámetro processes, porque en el PFILE generado desde memoria aparece configurado expresamente con el valor 200.

La línea que lo demuestra es la 118 de `20261124T190609Z_02-init_desde_memoria.ora`:

`processes=200`

**5. Tras el reinicio sin estado guardado, ¿qué error obtuvo C##OPS_RO y por qué la instancia decía «Database opened»?**

C##OPS_RO obtuvo ORA-01109 porque FREEPDB1 estaba montada, pero todavía no estaba abierta. La instancia podía indicar Database opened porque la CDB estaba abierta, aunque eso no significaba que todas sus PDB estuvieran disponibles para aceptar conexiones.

### 9.1.1. Partes D-E · Servicios, sesiones y diccionario

**6. ¿Qué SID, SPID y evento tenía la sesión de la aplicación en tu ejecución? ¿Qué te dicen MODULE, ACTION y CLIENT_IDENTIFIER que no te diría USERNAME?**

La sesión de APP_ACADEMIA tenía SID 209, SERIAL# 21712 y SPID 6395. El evento de espera era `PL/SQL lock timer`.

MODULE identificaba `matriculas`, ACTION indicaba `cierre-periodo` y CLIENT_IDENTIFIER mostraba `ana.garcia@ucam`.

Estos campos permiten conocer qué funcionalidad está ejecutando la aplicación, qué operación concreta realiza y a qué usuario o petición corresponde. USERNAME solamente identifica la cuenta de base de datos.

**7. Tras CANCEL SQL, ¿cuántas transacciones abiertas tenía la aplicación? ¿Y tras KILL SESSION? ¿En qué estado quedó la fila 101 y por qué?**

Después de CANCEL SQL seguía habiendo 1 transacción pendiente, porque esta sentencia cancela la llamada SQL, pero no termina la sesión ni confirma o revierte toda la transacción. Después de KILL SESSION quedaron 0 transacciones abiertas porque Oracle terminó la sesión y revirtió la transacción pendiente. La fila 101 quedó en estado ACTIVO porque se deshizo la modificación que estaba sin confirmar.

**8. ¿Qué valor tiene common_user_prefix en tu imagen? ¿Qué implica para el nombre de una cuenta común?**

El valor de common_user_prefix es `C##`. Esto significa que las cuentas comunes creadas en el contenedor raíz deben comenzar con ese prefijo. Un ejemplo es C##OPS_RO.

**9. Completa con tus cifras la tabla de las tres miradas (ALL_TABLES, DBA_USERS, CDB_USERS, V$DATAFILE) y explica una diferencia.**

Los resultados de mi ejecución fueron los siguientes:

| Consulta | C##OPS_RO en CDB$ROOT | C##OPS_RO en FREEPDB1 | APP_ACADEMIA |
|---|---:|---:|---:|
| USER_TABLES | 0 | 0 | 0 |
| ALL_TABLES de ADMIN_ACADEMIA | 0 | 0 | 1 |
| ALL_USERS | 37 | 47 | 47 |
| DBA_USERS | 37 | 47 | ORA-00942 |
| CDB_USERS | CON_ID 1: 37; CON_ID 3: 47 | CON_ID 3: 47 | ORA-00942 |
| V$DATAFILE | 17 | 10 | ORA-00942 |

La diferencia se debe a los privilegios y al contenedor desde el que se realiza la consulta. C##OPS_RO desde la raíz puede consultar información de distintos contenedores, mientras que desde FREEPDB1 su visibilidad queda limitada a esa PDB. APP_ACADEMIA tiene permisos para acceder a las tablas que necesita la aplicación, pero no tiene acceso a las vistas administrativas del diccionario.

**10. Con tu salida de 04-deltas: ¿cuántas lecturas lógicas por recorrido y cuánto DB time costó la carga? ¿Qué indica la relación entre DB time y DB CPU?**

En mi última ejecución se obtuvieron 52.881 lecturas lógicas en total, aproximadamente 5.288 por recorrido. El DB time fue de 0,23 segundos y el DB CPU también fue de 0,23 segundos. Al coincidir ambos valores con el redondeo mostrado, se observa que prácticamente todo el tiempo de base de datos se dedicó a CPU, con un peso muy reducido de las esperas.

### 9.1.2. Partes F-G · Espacio y acceso

**11. Da las tres medidas (asignado, libre, máximo) de TBS_ACADEMIA_HIST antes de la carga y explica cuál usarías para alertar.**

Antes de la carga, TBS_ACADEMIA_HIST tenía:

- Espacio asignado: 10 MB.
- Espacio libre: 3,9 MB.
- Tamaño máximo: 40 MB.

Para establecer alertas utilizaría el porcentaje ocupado respecto al máximo alcanzable, porque el tablespace puede crecer automáticamente. En mi ejecución la ocupación inicial era del 15,16 % del máximo. Posteriormente se configuraron los umbrales de aviso al 80 % y crítico al 95 %.

**12. ¿Quién insertó y quién «pagó» en el ORA-01950? ¿Por qué ampliar el tablespace no habría resuelto el ORA-01536?**

En la primera prueba quien insertó fue SYS, pero el segmento pertenecía a CARGA_HIST, que era el usuario que necesitaba cuota. En la carga reanudable, APP_ACADEMIA lanzó la operación, pero el propietario del segmento seguía siendo CARGA_HIST.

Ampliar el tablespace no habría solucionado el ORA-01536 porque el problema era la cuota asignada al propietario del segmento y no la falta de espacio físico. Por eso se amplió la cuota de CARGA_HIST a 30 MB.

**13. ¿Cuánto tiempo estuvo suspendida la carga reanudable y qué evidencia de ello dejó Oracle en el alert log?**

La carga estuvo suspendida aproximadamente 15 segundos. La evidencia muestra que comenzó la suspensión a las 19:56:02 y que la operación terminó a las 19:56:17. Oracle registró en el alert log el mensaje `statement in resumable session 'carga-historico' was suspended due to` y posteriormente `was resumed`.

Además, DBA_RESUMABLE mostraba la sesión en estado SUSPENDED, con un timeout de 180 segundos y el error ORA-01536. Después de ampliar la cuota de CARGA_HIST a 30 MB, la carga pudo continuar y terminó con 20.000 filas.

**14. Antes y después del SHRINK: filas, bloques y cuota consumida. ¿Por qué un DELETE no devolvió el espacio?**

Los valores obtenidos fueron:

| Momento | Filas | Bloques | Espacio ocupado |
|---|---:|---:|---:|
| Antes del DELETE | 20.000 | 2.944 | 23 MB |
| Después del DELETE | 2.000 | 2.944 | 23 MB |
| Después de SHRINK SPACE | 2.000 | 304 | 2,4 MB |

DELETE no devolvió el espacio porque eliminó las filas, pero no redujo la marca de agua alta del segmento. SHRINK SPACE compactó el segmento y permitió recuperar el espacio sobrante. La cuota consumida también bajó hasta aproximadamente 2,4 MB.

**15. ¿Qué valores tenía tu perfil DEFAULT? Justifica dos de los límites de PRF_PERSONAS para una persona de secretaría.**

En mi ejecución, el perfil DEFAULT tenía estos valores:

| Parámetro | Valor |
|---|---|
| FAILED_LOGIN_ATTEMPTS | 10 |
| INACTIVE_ACCOUNT_TIME | 365 |
| PASSWORD_GRACE_TIME | 7 |
| PASSWORD_LIFE_TIME | 180 |
| PASSWORD_LOCK_TIME | 1 |
| PASSWORD_REUSE_MAX | UNLIMITED |
| PASSWORD_REUSE_TIME | UNLIMITED |
| PASSWORD_ROLLOVER_TIME | 0 |
| PASSWORD_VERIFY_FUNCTION | NULL |

El perfil PRF_PERSONAS establece tres intentos fallidos y un bloqueo de un minuto en este laboratorio. Esto permite limitar los intentos de acceso incorrectos y bloquear temporalmente una cuenta cuando se supera el límite. También establece una duración de contraseña de 90 días y utiliza ora12c_verify_function para comprobar su complejidad.

**16. ¿Por qué Ana pudo leer ACA_MATRICULAS si nadie se la concedió por nombre? ¿Qué error obtuvo al cambiar el nombre de un alumno?**

Ana pudo consultar ACA_MATRICULAS porque recibió el rol ROL_SECRETARIA_ACADEMIA, que incluye ROL_LECTURA_ACADEMIA. Este último tiene el privilegio `SELECT ANY TABLE ON SCHEMA ADMIN_ACADEMIA`, que permite leer todas las tablas del esquema sin tener que conceder cada una individualmente.

Al intentar cambiar el nombre de un alumno obtuvo ORA-41900 porque solamente tenía permiso para actualizar la columna ESTADO.

### 9.1.3. Partes H-I · Objetos, diagnóstico y guardia

**17. ¿Qué objetos se invalidaron en cada uno de los tres cambios de columna y por qué no se invalidó nada con la columna nueva?**

Al añadir la columna TELEFONO no se invalidó ningún objeto porque ninguna vista ni función dependía de ella.

Al ampliar EMAIL_INSTITUCIONAL se invalidó V_CONTACTO_LAB6, porque era la única vista que utilizaba esa columna.

Al ampliar NOMBRES se invalidaron V_ACTIVOS_LAB6 y F_TOTAL_ACTIVOS_LAB6 por su dependencia de esa columna y de la vista. V_CONTACTO_LAB6 seguía inválida desde el cambio anterior.

La primera llamada a la función provocó su recompilación automática. Posteriormente, UTL_RECOMP permitió recompilar el resto de objetos del esquema. Al terminar, todos los objetos estaban VALID.

**18. Según tus advisors, ¿mejoraría el DB time duplicar la SGA? ¿Y por debajo de qué tamaño la PGA tendría sobreasignaciones?**

No mejoraría el DB time duplicar la SGA, porque el SGA Advisor mantenía el factor estimado de DB time en 1 incluso con el doble de memoria.

En el PGA Advisor aparecían sobreasignaciones con tamaños de 128 MB y 256 MB. Con 384 MB el contador estimado de sobreasignaciones era cero. Por tanto, los tamaños inferiores a 384 MB producirían sobreasignaciones según las estimaciones.

**19. ¿Cuántas lecturas lógicas necesitó la consulta de la aplicación según la traza (o tkprof)? ¿Qué línea de la traza lo dice?**

La consulta necesitó 247 lecturas lógicas para devolver una fila. Esto se puede comprobar en la línea FETCH de la traza, donde aparece `cr=247` y `r=1`. También aparece en el informe tkprof, en la columna query.

**20. Para cada incidente de la guardia: evidencia clave, intervención y validación (una línea por cada uno).**

- INC-601: Ana esperaba por un bloqueo de fila provocado por APP_ACADEMIA, SID 211. Se identificó la sesión bloqueadora y se ejecutó `ALTER SYSTEM KILL SESSION '211,61287' IMMEDIATE`. Después se comprobó que el estudiante 101 seguía en estado ACTIVO y que las sesiones implicadas ya no aparecían.
- INC-602: el diagnóstico mostró que academia_app no estaba arrancado y el listener no lo anunciaba. Se guardó el estado de FREEPDB1 y se registró el servicio en el listener. Aunque START_SERVICE devolvió ORA-44305 porque el servicio ya estaba arrancado en ese momento, las comprobaciones posteriores mostraron ARRANCADO=SI, el listener indicó READY y la aplicación pudo consultar 17.600 estudiantes.
- INC-603: APP_ACADEMIA aparecía en estado LOCKED y con perfil DEFAULT, por un bloqueo manual. Se ejecutó `ALTER USER APP_ACADEMIA ACCOUNT UNLOCK` y se comprobó que la cuenta quedó OPEN y que la aplicación volvió a consultar los 17.600 estudiantes.

---

## 10. Simulacro de examen 1Z0-182

| Pregunta | Respuesta | Justificación |
|---|---|---|
| S1 | B — MMON | Supervisa las métricas y genera alertas de umbral de espacio. |
| S2 | C | Los cambios DEFERRED se aplican a las sesiones que se conecten a partir de ese momento. |
| S3 | B — CREATE PFILE FROM MEMORY | Genera un PFILE a partir de los parámetros en memoria. |
| S4 | B y C | FORCE permite forzar la apertura en el modo solicitado y cerrar y volver a abrir la PDB también permite cambiar a READ WRITE. |
| S5 | C — DBA_PDB_SAVED_STATES | Muestra los estados guardados de las PDB. |
| S6 | B — ORA-01035 | Un usuario sin RESTRICTED SESSION no puede entrar en una PDB abierta en modo restringido. |
| S7 | A — DBMS_SERVICE | Gestiona la creación y el arranque de servicios. |
| S8 | B — PADDR = ADDR | Relaciona una sesión con su proceso servidor. |
| S9 | C | CANCEL SQL cancela la llamada en curso, pero deja abierta la transacción pendiente. |
| S10 | C — PUBLIC | Una conexión como SYSOPER muestra PUBLIC en SHOW USER. |
| S11 | B — V$CON_SYSMETRIC | Muestra métricas a nivel de contenedor. |
| S12 | A y C | DB time suma el tiempo de CPU de sesiones de primer plano y sus esperas no Idle. |
| S13 | B — HR | La cuota necesaria corresponde al propietario del segmento. |
| S14 | A y C | No se conceden cuotas sobre tablespaces UNDO ni TEMPORARY. |
| S15 | A y C | La sentencia se suspende hasta el timeout y la suspensión se puede consultar en DBA_RESUMABLE. |
| S16 | B | SHRINK SPACE requiere ENABLE ROW MOVEMENT y gestión ASSM. |
| S17 | B — LOCKED(TIMED) | Es el estado de bloqueo automático temporal tras superar los intentos permitidos. |
| S18 | B | La revocación de un privilegio de sistema concedido con ADMIN OPTION no se propaga en cascada. |
| S19 | A y B | MOVE sin UPDATE INDEXES y ALTER INDEX UNUSABLE dejan el índice inservible. |
| S20 | B — DBMS_MONITOR.SESSION_TRACE_ENABLE | Activa la traza de otra sesión mediante SID y SERIAL#. |
| S21 | C — DIAGNOSTIC_DEST | Define la raíz del ADR. |
| S22 | C | Primero hay que identificar al bloqueador mediante BLOCKING_SESSION y averiguar qué está haciendo. |
