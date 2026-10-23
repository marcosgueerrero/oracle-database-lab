SELECT s.sid, s.serial#, s.username, p.spid,
       ROUND(p.pga_used_mem/1048576,1) AS pga_usada_mb
  FROM v$session s JOIN v$process p ON p.addr = s.paddr
 WHERE s.type = 'USER' AND s.status = 'ACTIVE'
   AND s.username = 'SYS';
