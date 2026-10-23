ALTER SESSION SET CONTAINER = FREEPDB1;
ALTER SYSTEM SET db_create_file_dest='/opt/oracle/oradata/FREE/FREEPDB1' SCOPE=BOTH;
SELECT name, value FROM v$parameter WHERE name = 'db_create_file_dest';
EXIT
