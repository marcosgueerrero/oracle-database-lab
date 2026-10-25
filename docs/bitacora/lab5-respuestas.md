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
- Reto Q9: <completar con la medida de 03-reto-q9 y la decisión con dos números>.
