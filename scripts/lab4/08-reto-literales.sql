ALTER SESSION SET CONTAINER = FREEPDB1;
SET LINESIZE 170 PAGESIZE 100
COLUMN force_matching_signature FORMAT 99999999999999999999
COLUMN ejemplo FORMAT A80
SELECT force_matching_signature, COUNT(*) AS cursores, SUM(executions) AS ejecuciones,
       MIN(SUBSTR(sql_text, 1, 80)) AS ejemplo
  FROM v$sql
 WHERE force_matching_signature <> 0
 GROUP BY force_matching_signature
HAVING COUNT(*) > 50
 ORDER BY cursores DESC;
EXIT
