ALTER SESSION SET CONTAINER = FREEPDB1;
SELECT MIN(n) AS minimo, ROUND(AVG(n),1) AS media, MAX(n) AS maximo FROM (
  SELECT COUNT(*) AS n FROM tiendasur.pedido
  GROUP BY DBMS_ROWID.ROWID_BLOCK_NUMBER(ROWID,'BIGFILE'));
SELECT num_rows, blocks, ROUND(num_rows/blocks,1) AS num_rows_entre_blocks
  FROM dba_tables WHERE owner='TIENDASUR' AND table_name='PEDIDO';
EXIT
