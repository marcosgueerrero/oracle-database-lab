# Lab 5: respuestas

## Parte A y B
- Backup lab4-final: paso 6 = ninguno (los datafiles de negocio ya están dentro del volumen; en el de lab3 había 0 FUERA por el enlace de dbs, y ahora están en FREE/FREEPDB1).
- bfr CLIENTE = 100000/1517 = 66; PEDIDO = 1000000/5320 = 188. PEDIDO cabe ~3 veces más filas por bloque porque su fila mide 32 bytes frente a 102.
- El banco ejecuta cada sentencia dos veces y mide la segunda: la primera incluye el análisis (parse) y el calentamiento de la caché.
- Prueba del banco: búsqueda por PK = 4 lecturas lógicas (3 de índice + 1 de tabla).

## Parte D
- Único: 1486 -> 3 lecturas y ORA-00001/ORA-03301 impiden el duplicado. Compuesto: skip scan 144 frente a 105 con país+ciudad. Q7: 15 -> 7 -> 3 (cubriente, sin SORT).
- Funcional Q1: 1486 -> 4. Parcial Q12: 246 frente a 239 lecturas, pero 54 hojas frente a 2933.
- Bitmap Q14: 4073 -> 528; bitmap de región 114 hojas frente a 1954 del B-tree. IOT 3 lecturas; clúster hash 1, pero la limpieza por rango lee 2770.
- IX_PED_CLI_FEC_CUB ocupa 40 MB, casi como la tabla (41,6 MB): solo compensa por ser Q7 la consulta más frecuente.
- D1: B. D2: A y C.
- Reto Q9: la consulta ya cuesta solo 5 lecturas lógicas con IX_PED_FECHA (INDEX FULL SCAN DESCENDING + STOPKEY). Un cubriente con todas las columnas costaría unos 40 MB más (la tabla ocupa 41,6 MB) y más bloques por INSERT para ahorrar a lo sumo 20 lecturas: decisión, NO.

## Parte C
- IX_PED_CLIENTE: altura 3, 2216 hojas, fo real 370, fo máximo 543, llenado 90 %. Con 1e9 filas: altura 4 (5 lecturas).
- Búsqueda por PK: 4 lecturas (3 índice + 1 tabla); pidiendo solo id_pedido, 3.
- PK_CLIENTE: raíz con 186 entradas + hijo izquierdo = 187 hojas; hoja con 578 entradas y 8 bytes libres (claves crecientes, divisiones 90/10).
- ROWID de la hoja: 00 00 03 1b 00 00 = bloque 795 (0x31B), ranura 0; sin número de archivo porque el tablespace es BIGFILE.
- Mapas de PK_PEDIDO (99,9 %) e IX_PED_CLIENTE (89,7 %): uniformes, sin patrón cola.
- C1: C. C2: C.

## Parte E
- CF: PK_PEDIDO e IX_PED_FECHA 5220 (bloques 5320, bueno); IX_PED_CLIENTE 999041 e IX_PED_IMPORTE 998078 (filas 1000000, malo). El LAG calculado coincide con el diccionario. REBUILD no lo mejora: es propiedad de la tabla.
- Curva (tabla entera 5232): CF malo cruza entre 0,5 % (4875) y 1 % (9920); el optimizador cambia a recorrido completo en el 0,2 %; CF bueno solo pierde al 100 % (7875).
- Teoría: k/r < 1/188 = 0,53 % (lecturas lógicas) y 0,11 % con disco (c_sec/c_aleat = 1/5). Los tres puntos difieren porque el optimizador asume que la lectura aleatoria es más cara y las lecturas lógicas no lo reflejan.
- E1: B.

## Parte F
- Regla 1: 1486 -> 4. Regla 2: 5285 -> 323. Regla 3: 5232 -> 106 (el plan muestra filter(TO_NUMBER("CODIGO_POSTAL")=30001)). Regla 5: 1486 -> 6 (BITMAP OR o UNION).
- Regla 4: '%ez' recorrido completo (1523); 'Gonz%' usa el índice pero lee 2024 > 1523: sargable no significa que el índice compense (2,1 % con CF malo supera el punto de equilibrio).
- Q11: 5232 en ambas versiones; el recorrido completo es lo correcto (un año = un tercio de los pedidos).
- F1: B. F2: A y C.
- Reto de revisión: la consulta rota y la reescrita devuelven ambas 981 filas. La rota realiza TABLE ACCESS FULL CLIENTE y consume 1487 lecturas lógicas; la reescrita consume 986, una reducción de 501 lecturas (aproximadamente el 33,7 %). El plan reescrito utiliza IX_CLI_TELEFONO e IX_CLI_APELLIDOS, con UNION-ALL y HASH UNIQUE. Los tiempos observados fueron 24,5 ms y 8,1 ms, respectivamente, aunque para comparar el trabajo realizado priorizo las lecturas lógicas. Los dos índices de prueba se eliminan al terminar.
  - Evidencia: `20261025T111212Z_05-reto-revision.script.log`, etiquetas `revision rota` y `revision reescrita`.
  - Comentario de revisión: la reescritura reduce el trabajo medido y conserva el recuento de resultados. El plan también muestra el trabajo de eliminación de duplicados; no basta con comprobar que aparecen índices.
## Parte G · Optimización y ciclo de vida de índices (V005)

### Medidas de escritura

Evidencia: `20261025T111300Z_06-indices.script.log`, escenarios `hoy`, `compañero` y `V005`. Cada prueba procesa 2000 filas.

| Escenario | Índices en PEDIDO | Lecturas lógicas del INSERT | Bloques modificados del INSERT | Bloques modificados por fila | Redo del INSERT |
|---|---:|---:|---:|---:|---:|
| Inicial | 4 | 30399 | 20248 | 10,1 | 2549 KB |
| Propuesta del compañero | 9 | 60566 | 40310 | 20,2 | 4981 KB |
| V005 | 5 | 34386 | 24214 | 12,1 | 3144 KB |

La propuesta de 9 índices casi duplica los bloques modificados por INSERT respecto al estado inicial. V005 reduce los bloques modificados de 40310 a 24214 frente a esa propuesta, aproximadamente un 39,9 %. Sin embargo, frente a los 4 índices iniciales, V005 aumenta los bloques modificados de 20248 a 24214, aproximadamente un 19,6 %. No es una mejora gratuita: se acepta más mantenimiento para atender las consultas seleccionadas y garantizar la unicidad del DNI en CLIENTE.

### Decisiones del protocolo

- Necesidad: en la carga observada, IX_PED_CP, IX_PED_CLI_FEC, IX_PED_ESTADO e IX_PED_FECHA registran uso; IX_PED_CANAL, IX_PED_CLIENTE, IX_PED_FEC_CLI e IX_PED_IMPORTE no lo registran. Esta conclusión se limita a las consultas ejecutadas durante el laboratorio, no demuestra ausencia de uso en cualquier carga futura.
- IX_PED_CP se conserva: Q3 devuelve 102 filas con 106 lecturas lógicas, usando ese índice.
- IX_PED_FECHA se conserva: lo usan Q2 (336 lecturas), Q8 (735) y Q9 (18) en esta ejecución.
- IX_PED_CLI_FEC_CUB se incorpora para cubrir Q7. En la evidencia de la Parte D, Q7 pasa de 15 lecturas con el índice simple a 7 con el compuesto y 3 con el cubriente. El índice comienza por ID_CLIENTE y sustituye al índice simple IX_PED_CLIENTE, que queda redundante.
- IX_PED_PENDIENTES se incorpora para Q12: en la Parte D, el parcial tiene 54 hojas frente a 2933 del índice de estado y fecha, con 239 frente a 246 lecturas. Se justifica principalmente por su menor tamaño, no por una gran reducción de lecturas en esa comparación.
- UX_CLI_DNI se incorpora en CLIENTE: en la Parte D, la búsqueda por DNI pasa de 1486 a 3 lecturas y el intento de duplicado provoca ORA-00001. Además de acelerar la búsqueda, garantiza la unicidad.
- IX_PED_CANAL se rechaza: no registra uso en la carga observada y su selectividad media es del 33,333 % por valor.
- IX_PED_ESTADO no se conserva como índice simple: aunque Q12 lo utiliza en la propuesta (147 lecturas), la decisión final es un índice parcial para pendientes. No afirmo que el parcial sea más rápido que ese índice simple: son alternativas que deben valorarse también por tamaño y mantenimiento.
- IX_PED_FEC_CLI se rechaza: no registra uso en la carga observada; las consultas por fecha medidas ya utilizan IX_PED_FECHA.
- IX_PED_IMPORTE se elimina: no registra uso en la carga observada. Antes se prueba como INVISIBLE y Q2 mantiene 336 lecturas, el mismo valor que antes. Esa prueba solo acredita que Q2 no empeora; en producción habría que observar una carga representativa durante más tiempo.

Evidencias adicionales: `20261025T110512Z_03-tipos-indice.script.log` y `20261025T111324Z_06-V005__indices_tiendasur.spool.log`.

### Contrapartidas de V005

| Operación sobre 2000 filas | Bloques modificados iniciales | Propuesta del compañero | V005 |
|---|---:|---:|---:|
| UPDATE de estado | 4023 | 12071 | 16105 |
| UPDATE de importe | 12073 | 12074 | 12083 |
| DELETE | 20178 | 40291 | 20185 |

El UPDATE de estado es más caro con V005: el diseño final incluye ESTADO en el índice cubriente y utiliza ESTADO en la expresión de la columna virtual del índice parcial. El UPDATE de importe mantiene un coste de bloques parecido al inicial, pero el redo pasa de 1472 a 1586 KB. El DELETE queda prácticamente al nivel inicial en bloques modificados y por debajo de la propuesta del compañero.

La decisión final no busca minimizar cada operación por separado: equilibra las consultas seleccionadas, las restricciones de negocio, el espacio y el coste de escritura. No se debe afirmar que V005 acelera todas las operaciones.

## Parte H · Divisiones de hoja, patrón cola y remedios

### Claves aleatorias, crecientes y REVERSE

Evidencia: `20261025T111922Z_07a-crecimiento.script.log`. Se realizan 200000 inserciones en cada tabla.

| Patrón | Divisiones de hoja | Divisiones 90/10 | Hojas finales | Entradas medias por hoja |
|---|---:|---:|---:|---:|
| Claves aleatorias | 595 | 0 | 596 | 336 |
| Claves crecientes | 398 | 398 | 399 | 501 |
| Claves crecientes con REVERSE | 511 | 0 | 512 | 391 |

En el índice de claves crecientes, todas las divisiones observadas son 90/10: las inserciones avanzan por el extremo derecho y las hojas anteriores quedan densamente ocupadas. El resultado es el menor número de hojas y la mayor media de entradas por hoja de los tres casos.

Las claves aleatorias provocan divisiones de tipo 50/50 en lugar de 90/10 y dejan una ocupación menos compacta: 596 hojas y 336 entradas por hoja. Este resultado no demuestra por sí solo una degradación que requiera mantenimiento; responde al patrón de inserción.

REVERSE redistribuye las claves crecientes y evita las divisiones 90/10 en esta prueba, pero tiene una contrapartida importante para los rangos: la consulta medida pasa de 4 lecturas con INDEX RANGE SCAN en el índice normal a 878 lecturas con TABLE ACCESS FULL en la tabla con índice REVERSE. La prueba muestra el coste para rangos; no mide directamente una mejora de concurrencia entre sesiones.

### Diagnóstico del patrón cola

Evidencia: `20261025T111922Z_07b-patron-cola.script.log`.

Tras insertar 200000 mensajes, borrar los 150000 más antiguos e insertar otros 50000, quedan 100000 mensajes vivos, con claves entre 150001 y 250000.

La consulta del siguiente mensaje consume 287 lecturas lógicas en IX_COLA, frente a 2 en el índice sano usado como referencia. INDEX_STATS muestra altura 2, 486 hojas y 89903 entradas borradas de 189903 entradas registradas, aproximadamente el 47 %.

Las 189903 entradas registradas no son mensajes vivos: incluyen las 89903 entradas borradas. La diferencia es 100000, que coincide con el recuento de mensajes vivos. El problema observado es el recorrido inicial por hojas sin entradas vivas tras los borrados de las claves antiguas.

### Remedios medidos y decisión

Evidencia: `20261025T111922Z_07c-remedios.script.log`.

| Estado | Hojas | Entradas borradas | Segmento (MB) | Lecturas del siguiente mensaje |
|---|---:|---:|---:|---:|
| Cola degradada | 486 | 89903 | 4 | 287 |
| Tras COALESCE | 201 | 0 | 4 | 2 |
| Tras SHRINK SPACE | 201 | 0 | 1,69 | 2 |
| Tras REBUILD ONLINE | 223 | 0 | 2 | 2 |

Los remedios se aplicaron de forma secuencial, por lo que las filas muestran el estado después de cada paso, no tres experimentos independientes desde la misma cola degradada.

COALESCE basta para resolver el problema de lecturas observado: pasa de 287 a 2 y elimina las entradas borradas registradas, pero el segmento sigue ocupando 4 MB.

SHRINK SPACE conserva las 2 lecturas y reduce el segmento a 1,69 MB. En esta prueba aporta recuperación de espacio, no una mejora adicional de la consulta.

REBUILD ONLINE deja 223 hojas y un segmento de 2 MB, sin mejorar las 2 lecturas ya alcanzadas. Por tanto, no lo elegiría como primera intervención para este caso: no demuestra un beneficio adicional frente a los pasos anteriores.

Mi decisión sería aplicar COALESCE para corregir el recorrido degradado medido y valorar SHRINK SPACE si también interesa devolver espacio al tablespace. Si el patrón de inserción y borrado continúa, revisaría el diseño y la posibilidad de particionar por fecha, en lugar de asumir que una reconstrucción periódica soluciona la causa.

Al finalizar, el registro confirma que se elimina el esquema de pruebas LAB5_PRUEBAS.
