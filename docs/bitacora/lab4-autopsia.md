# Autopsia de la instancia FREE (Lab 4, Parte N)

| # | Sección | Evidencia (valor exacto) | Riesgo | Acción | Prioridad |
|---|---|---|---|---|---|
| 1 | 1 y 4 | ARCHIVELOG, db_recovery_file_dest vacío, 17 archived logs = 2895 MB en disco | Alto: los archivados crecen sin límite y pueden llenar el disco, parando la base | Configurar FRA con db_recovery_file_dest_size y política de borrado (Lab 5) | Alta |
| 2 | 4 | 2 control files en la misma carpeta; 3 grupos de redo con 1 miembro | Alto: punto único de fallo | Multiplexar en otro disco (Lab 5) | Alta |
| 3 | Parte J | ADR (/opt/oracle/diag, 29 MB, 215 trazas) en la capa del contenedor | Medio: se pierde el alert log al recrear el contenedor | diagnostic_dest persistente o logs centralizados | Media |
| 4 | 6 | ALTURA_MAX vacía en ADMIN_CLINICA, FINTECH, LOGISTICA, RETAIL | Medio: el optimizador sin estadísticas elige planes a ciegas | DBMS_STATS.GATHER_SCHEMA_STATS en esos esquemas | Media |
| 5 | 10 | ORA-1013 a las 06:10 UTC: "opidrv aborting process J002 as a result of ORA-1013", con "Time drifted forward" justo antes y después | Bajo: un job abortado por un salto del reloj del contenedor | Sin acción sobre la base; vigilar si se repite (suspensión de WSL) | Baja |
| 6 | 6 | CF_CERCANO_A_FILAS = 2 en ADMIN_ACADEMIA | Bajo: índices caros para rangos | Analizar en el Lab 5 | Baja |
| 7 | 1 | FORCE_LOGGING = YES, FLASHBACK = NO | Bajo: más redo; sin flashback no hay vuelta atrás rápida | Documentar; valorar en Lab 5 | Baja |
| 8 | 9 | Parámetro oculto _instance_recovery_bloom_filter_size modificado | Bajo: viene de la imagen | Documentar | Baja |
| 9 | 10 | ORA-00800 x4 | Bajo: ruido conocido del contenedor | Excluir de alertas | Baja |
| 10 | 10 | ORA-959 (10:51 UTC): DROP TABLESPACE IF EXISTS tbs_lab4 del script 13, confirmado en el alert log | Ninguno: provocado por el laboratorio | Ninguna | n/a |
| 11 | 10 | ORA-65025 x1 | Ninguno: provocado por la Parte I (DROP de PDB abierta) | Ninguna | n/a |

## Resumen para un jefe no técnico
La base funciona y no tiene cuentas con privilegios excesivos. El mayor riesgo es que guarda copias de sus cambios sin límite de espacio y con un único punto de fallo en sus archivos de control y registro. Conviene configurar espacio para esas copias y duplicar esos archivos antes de que ocurra un fallo.
