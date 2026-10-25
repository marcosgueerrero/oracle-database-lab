# Lab 5: respuestas

## Parte A y B
- Backup lab4-final: paso 6 = ninguno (los datafiles de negocio ya están dentro del volumen; en el de lab3 había 0 FUERA por el enlace de dbs, y ahora están en FREE/FREEPDB1).
- bfr CLIENTE = 100000/1517 = 66; PEDIDO = 1000000/5320 = 188. PEDIDO cabe ~3 veces más filas por bloque porque su fila mide 32 bytes frente a 102.
- El banco ejecuta cada sentencia dos veces y mide la segunda: la primera incluye el análisis (parse) y el calentamiento de la caché.
- Prueba del banco: búsqueda por PK = 4 lecturas lógicas (3 de índice + 1 de tabla).
