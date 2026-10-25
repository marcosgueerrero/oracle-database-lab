ALTER SESSION SET CONTAINER = FREEPDB1;
SET SERVEROUTPUT ON FORMAT WRAPPED
CREATE INDEX tiendasur.ix_cli_telefono ON tiendasur.cliente (telefono);
CREATE INDEX tiendasur.ix_cli_apellidos ON tiendasur.cliente (apellidos);
EXEC lab_tools.medir.consulta('revision rota', q'[SELECT * FROM tiendasur.cliente WHERE SUBSTR(telefono, 1, 3) = '600' OR UPPER(apellidos) = 'GIL']')
EXEC lab_tools.medir.consulta('revision reescrita', q'[SELECT * FROM tiendasur.cliente WHERE telefono LIKE '600%' UNION SELECT * FROM tiendasur.cliente WHERE apellidos = 'Gil']')
DROP INDEX tiendasur.ix_cli_telefono;
DROP INDEX tiendasur.ix_cli_apellidos;
EXIT
