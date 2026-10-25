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
