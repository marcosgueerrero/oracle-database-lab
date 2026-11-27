
# Laboratorio 7 · Respuestas · E030

## Parte B · C01 · Más sesiones no es más rendimiento

1. Con 1 sesión obtuve 6,9 llamadas/s y p95 de 155,5 ms; con 2 sesiones, 12,8 llamadas/s y p95 de 190 ms; con 8 sesiones, 10,1 llamadas/s y p95 de 1253,5 ms. Recomiendo 2 sesiones porque ofrecen el mayor rendimiento sin disparar la latencia. Evidencia: `20261127T114306Z_C01_provocar.txt`, `20261127T114430Z_C01_solucionar.txt`.

2. Con 8 sesiones domina `resmgr:cpu quantum`, con 234 muestras (73,1 %). Esto indica que las sesiones esperan su turno para utilizar CPU debido a la limitación de recursos de Oracle Free, que dispone de 2 CPU visibles. Evidencia: `20261127T114348Z_C01_diagnosticar.txt`.

3. La ley de Little (N = X · R) dio aproximadamente 1,0 con 1 sesión, 2,0 con 2 y 7,8 con 8. El número de sesiones activas crece con la concurrencia, pero aumentar las sesiones no implica aumentar proporcionalmente el rendimiento. Evidencia: `20261127T114433Z_C01_observar.txt`.

## Parte C · C03 · Literales y análisis completos

1. Con literales se realizaron 5000 análisis completos y se tardaron 3250 ms. Con variables de enlace se realizaron 28 análisis completos y se tardaron 140 ms; con `CURSOR_SHARING=FORCE`, también hubo 28 análisis completos y el tiempo fue de 200 ms. Evidencia: `20261127T114622Z_C03_provocar.txt`, `20261127T114626Z_C03_solucionar.txt`.

2. `CURSOR_SHARING=FORCE` es un puente porque transforma literales automáticamente, pero no sustituye a programar correctamente con variables de enlace. En `V$SQL`, la firma `FORCE_MATCHING_SIGNATURE` permite identificar sentencias que pueden compartir una misma estructura aunque tengan literales diferentes. Evidencia: `20261127T114625Z_C03_diagnosticar.txt`, `20261127T114629Z_C03_observar.txt`.

## Parte C · C04 · El informe que se desborda a TEMP

1. Antes se escribieron y leyeron 5456 bloques TEMP, aproximadamente 42,6 MB, con una pasada ONE PASS y un tiempo de 3230 ms. El disparador de LOGON configuraba `workarea_size_policy=MANUAL` y `sort_area_size=1048576`. Tras eliminarlo, el informe completo tardó 840 ms y no utilizó TEMP. Evidencia: `20261127T114740Z_C04_provocar.txt`, `20261127T114744Z_C04_solucionar.txt`.

2. El TOP 100 solo necesita ordenar 100 filas y cabe en memoria, mientras que el informe completo procesa un millón de filas y necesita mucha más memoria para ordenar. Con la gestión automática de áreas de trabajo se evita el desbordamiento observado. Evidencia: `20261127T114746Z_C04_observar.txt`.

## Parte D · C07 · EXPLAIN PLAN frente al plan real

1. El predicado problemático era `filter(TO_NUMBER("CODIGO_POSTAL")=:B1)`. El programa enviaba un bind NUMBER mientras que la columna era VARCHAR2, por lo que Oracle convertía la columna y no podía utilizar correctamente el índice. Evidencia: `20261127T114945Z_C07_diagnosticar.txt`.

2. V1 realizó 5227 lecturas lógicas por ejecución y tuvo un p95 de 58,1 ms. V2, con el tipo de bind corregido, utilizó el índice, redujo las lecturas a 95 y el p95 a 2,5 ms. `EXPLAIN PLAN` no reprodujo el bind real de la aplicación. Evidencia: `20261127T114943Z_C07_provocar.txt`, `20261127T114946Z_C07_solucionar.txt`.

## Parte D · C08 · E-Rows frente a A-Rows

1. Antes de crear las estadísticas extendidas, la estimación era de 3 filas frente a 56 reales en el acceso a CLIENTE. Después, la estimación pasó a 50 frente a 56. La primera divergencia importante aparecía en el acceso a CLIENTE, donde se aplicaba el filtro de comunidad. Evidencia: `20261127T114951Z_C08_entender.txt`, `20261127T114954Z_C08_solucionar.txt`.

2. El optimizador multiplicaba las selectividades de ciudad y comunidad como si fueran independientes. Al existir correlación entre ambas columnas, esa suposición infravaloraba las filas. Las estadísticas extendidas permitieron representar mejor esa relación. Evidencia: `20261127T114953Z_C08_diagnosticar.txt`.

## Parte E · C12 · Estadísticas obsoletas

1. Las estadísticas indicaban 100 filas, mientras que la tabla tenía 200100 reales. Antes se utilizaba NESTED LOOPS con 212326 buffers; después de recoger estadísticas se utilizó HASH JOIN con 5907 buffers. Evidencia: `20261127T115135Z_C12_provocar.txt`, `20261127T115139Z_C12_solucionar.txt`.

2. La tarea automática no había actualizado todavía las estadísticas porque la tabla no había alcanzado necesariamente el momento de mantenimiento. El proceso de carga debe recoger las estadísticas al terminar la carga, cuando los datos ya representan el nuevo estado. Evidencia: `20261127T115142Z_C12_observar.txt`.

## Parte E · C13 · El ciclo de estadísticas con red

1. Se recogieron estadísticas pendientes con `PUBLISH=FALSE`, se probaron mediante `OPTIMIZER_USE_PENDING_STATISTICS=TRUE` y se publicaron después de comprobar las estimaciones. Se restauraron las estadísticas anteriores y se bloquearon para probar el comportamiento del bloqueo. Las vistas y procedimientos de DBMS_STATS permitieron comprobar el estado de las estadísticas pendientes y publicadas. Evidencia: `20261127T115154Z_C13_solucionar.txt`, `20261127T115201Z_C13_observar.txt`.

2. Al intentar recoger estadísticas bloqueadas apareció `ORA-20005`. Si es necesario recogerlas, primero hay que desbloquearlas con `DBMS_STATS.UNLOCK_TABLE_STATS`, realizar la recogida y volver a bloquearlas cuando corresponda. Evidencia: `20261127T115201Z_C13_observar.txt`.

## Parte E · C14 · El índice invisible

1. Antes, el panel necesitaba 5305 lecturas por apertura. Se creó el índice compuesto como INVISIBLE y se probó únicamente en una sesión con `OPTIMIZER_USE_INVISIBLE_INDEXES=TRUE`; después se hizo visible. El panel pasó a unas 118 lecturas por apertura. Evidencia: `20261127T115203Z_C14_provocar.txt`, `20261127T115209Z_C14_solucionar.txt`.

2. El redo pasó de 9008 KB sin el índice a 10403 KB con el índice. Esto demuestra que mantener un índice tiene un coste adicional en las operaciones de escritura, aunque mejore las consultas de lectura. Evidencia: `20261127T115215Z_C14_observar.txt`.

## Parte F · C17 · INC-604 con AWR, ASH y ADDM

1. El SLI fue la latencia p95 de las búsquedas y el SLO establecido era p95 inferior a 20 ms. Antes, el p95 fue de 86,7 ms; después de la corrección, 0,97 ms. Se utilizaron las instantáneas AWR 288 y 289. Evidencia: `20261127T115857Z_C17_provocar.txt`, `20261127T120106Z_C17_validar.txt`.

2. ASH mostró actividad en CPU y esperas `resmgr:cpu quantum`; AWR identificó las sentencias con mayor consumo y ADDM señaló el peso de SQL y la limitación de CPU. El problema principal era la conversión de tipo que impedía utilizar el índice. El único cambio aplicado fue corregir el tipo del parámetro de búsqueda a VARCHAR2. Evidencia: `20261127T115901Z_C17_diagnosticar.txt`, `20261127T115902Z_C17_solucionar.txt`.

## Parte F · C18 · SQL Plan Management

1. El lunes se utilizó el plan hash 1767728868, con 194 lecturas por ejecución. El martes cambió al plan hash 2571571058, con 5227 lecturas. Con la línea base se recuperó el plan del lunes, con unas 190 lecturas por ejecución. Evidencia: `20261127T120117Z_C18_provocar.txt`, `20261127T120122Z_C18_solucionar.txt`.

2. La evolución analizó el plan alternativo, pero no lo aceptó porque su rendimiento era peor que el de la línea base. Para evitar que vuelva a ocurrir, hay que conservar estadísticas representativas, especialmente el histograma de ESTADO, y revisar las futuras recogidas de estadísticas. Evidencia: `20261127T120123Z_C18_validar.txt`, `20261127T120125Z_C18_observar.txt`.

## Parte G · Incidente 1 · INC-605

- **Síntoma (con números):** El informe de cestas abandonadas se ralentizó después de una carga de 180000 filas. Las estadísticas reflejaban inicialmente 100 filas frente a 180100 reales.
- **Playbook y pasos seguidos (herramientas y vistas):** PB-3 y RB-2. Se revisaron `t6 estad CESTA`, las estadísticas de la tabla y las modificaciones pendientes.
- **Causa raíz:** Las estadísticas estaban bloqueadas y desactualizadas, por lo que la tarea automática no podía actualizarlas.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** `DBMS_STATS.UNLOCK_TABLE_STATS`, `DBMS_STATS.GATHER_TABLE_STATS` y `DBMS_STATS.LOCK_TABLE_STATS`. Se actualizaron antes de volver a bloquearlas.
- **Verificación (archivo de evidencia con todo OK):** `docs/bitacora/lab7/evidencia/incidentes/20261127T123121Z_INC-605_verificar.txt`.
- **Prevención (qué evitaría que se repita):** Recoger estadísticas después de las cargas importantes y comprobar que no estén bloqueadas con datos obsoletos.

## Parte G · Incidente 2 · INC-606

- **Síntoma (con números):** La búsqueda por código postal utilizaba un índice que no estaba disponible para el optimizador.
- **Playbook y pasos seguidos (herramientas y vistas):** Se siguió RB-3 y se revisó `t6 indices PEDIDO`.
- **Causa raíz:** El índice `IX_T6_PED_CP` estaba en estado UNUSABLE, aunque era visible.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** `ALTER INDEX T6.IX_T6_PED_CP REBUILD ONLINE;`. Se reconstruyó el índice para devolverlo a estado utilizable sin tener que recrearlo.
- **Verificación (archivo de evidencia con todo OK):** `docs/bitacora/lab7/evidencia/incidentes/20261127T123342Z_INC-606_verificar.txt`.
- **Prevención (qué evitaría que se repita):** Comprobar periódicamente el estado de los índices y verificar su disponibilidad después de operaciones de mantenimiento.

## Parte G · Incidente 3 · INC-610

- **Síntoma (con números):** Varias consultas cambiaron de plan a la vez porque `optimizer_index_cost_adj` tenía el valor 3000 en FREEPDB1.
- **Playbook y pasos seguidos (herramientas y vistas):** Se siguieron las pistas de PB-3 y se consultaron `V$SYSTEM_PARAMETER` y `V$SPPARAMETER`.
- **Causa raíz:** El parámetro del optimizador estaba modificado y persistido en el SPFILE de la PDB.
- **Arreglo aplicado (órdenes exactas) y por qué ese:** `ALTER SYSTEM RESET optimizer_index_cost_adj SCOPE=BOTH SID='*';`. Se eliminó el valor persistente para recuperar el valor predeterminado.
- **Verificación (archivo de evidencia con todo OK):** `docs/bitacora/lab7/evidencia/incidentes/20261127T123801Z_INC-610_verificar.txt`.
- **Prevención (qué evitaría que se repita):** Revisar los parámetros modificados de la PDB y documentar los cambios de configuración del optimizador.

## Parte H · Reflexión

1. Considero que la corrección de C07 fue una de las mejoras con mejor relación entre beneficio y riesgo. Corregir el tipo del bind permitió pasar de 5227 a 95 lecturas por ejecución y reducir el p95 de 58,1 a 2,5 ms, sin añadir un índice nuevo ni modificar globalmente la configuración de Oracle.

2. No he incluido un caso no evaluable porque no tengo documentada aquí la ejecución de uno adicional.
