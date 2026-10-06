# Respuestas del Laboratorio 3 - Instalación del entorno Oracle

## Docker

### 1. ¿Qué diferencia hay entre una imagen y un contenedor?
Una imagen es una plantilla de solo lectura; un contenedor es una instancia en ejecución creada a partir de ella. En el ejercicio G3 descargué la imagen `alpine:3.20` y en G4 creé a partir de ella el contenedor `prueba`. De una misma imagen se pueden crear varios contenedores independientes, como `prueba` y `prueba2`, que no comparten nada entre sí. En G2, `hello-world` fue otro contenedor, creado desde otra imagen.

### 2. En G5 `nota.txt` desapareció y en G6 no. ¿Por qué?
En G5 escribí `nota.txt` en `/tmp`, dentro del sistema de archivos del contenedor `prueba`. Esa capa de escritura pertenece al contenedor, así que al hacer `docker rm prueba` se borró con él, y `prueba2` nació limpio. En G6 guardé el archivo en `/datos`, que era el volumen `datos-prueba`: un volumen vive fuera de cualquier contenedor, por eso el dato siguió ahí cuando abrí un contenedor nuevo.

### 3. Diferencia entre `docker ps` y `docker ps -a`, y qué significa `Exited (0)`
`docker ps` solo lista los contenedores en ejecución; `docker ps -a` lista también los parados. En G2 el contenedor de `hello-world` solo salía con `-a`, porque ya había terminado. `Exited (0)` indica que el proceso acabó por sí mismo y sin error, porque el código de salida 0 significa "todo correcto".

### 4. En `-p 8181:8181`, ¿cuál es el puerto de mi equipo y cuál el del contenedor? ¿Y con `-p 80:8080` en nginx?
El formato es `-p equipo:contenedor`, así que el primer número es el de mi equipo y el segundo el del contenedor. En G7 usé `8088:80` en lugar de 8080 porque el 8080 de mi equipo ya lo ocupaba el contenedor `oralab-26ai`. Con `-p 80:8080` en nginx, el puerto 80 de mi equipo apuntaría al 8080 del contenedor, pero nginx escucha dentro en el 80, así que no respondería nadie.

### 5. ¿Por qué Oracle sigue en marcha y `hello-world` termina solo?
Un contenedor vive mientras viva su proceso principal. En el de Oracle ese proceso es un servidor que se queda esperando conexiones, así que el contenedor sigue `Up (healthy)`. `hello-world` ejecuta un programa que imprime un mensaje y termina, y el contenedor termina con él.

### 6. ¿Qué es el digest de una imagen y por qué lo registramos si usamos `:latest`?
El digest es una huella criptográfica (SHA-256) del contenido exacto de la imagen; el mío empieza por `sha256:f988b0c0`. La etiqueta `:latest` es móvil: Oracle puede apuntarla a otra versión mañana, pero el digest no cambia. Registrarlo deja constancia de la versión exacta instalada y permite que otra persona compruebe que tiene la misma.

### 7. ¿Qué comando borraría los datos de Oracle? ¿Por qué `docker rm oralab-26ai` no lo hace?
Los datos están en el volumen `oralab-26ai-data`, que monté con `-v` en el script 05. Se borran con `docker volume rm oralab-26ai-data`. `docker rm oralab-26ai` elimina solo el contenedor; el volumen sigue existiendo y se podría reutilizar al crear otro contenedor con el mismo `-v`.

## Git, organización y evidencia

### 8. ¿Por qué se hace dentro del repositorio con Issue, branch y Pull Request?
Porque la instalación es parte del proyecto y debe quedar trazable: el Issue explica qué se hace y por qué, la branch aísla el trabajo sin tocar `main`, y el Pull Request permite que un compañero lo revise antes de fusionarlo. Así, scripts, evidencias y decisiones quedan versionados y reproducibles, en vez de dispersos en una carpeta aparte que nadie revisa.

### 9. Diferencia entre `source 00-config.sh` y `bash 00-config.sh`
`bash 00-config.sh` ejecuta el archivo en un proceso hijo, y las variables que define desaparecen cuando ese proceso termina. `source` lo ejecuta en la terminal actual, así que `CONT_NAME`, `EVID` o la función `ts` quedan disponibles para los comandos siguientes. Por eso usamos `source`: lo que necesitamos de ese archivo son justamente las constantes.

### 10. Partes del nombre `20260915T091230Z_02-docker.script.log`
`20260915` es la fecha (15 de septiembre de 2026); `T` separa fecha y hora; `091230` es la hora, 09:12:30; `Z` indica que está en UTC. `02` es el número de paso del laboratorio y `docker` el tema. `.script` indica que se generó grabando la terminal y `.log` es el tipo de archivo. Así los nombres se ordenan cronológicamente y se sabe qué paso prueba cada evidencia.

### 11. ¿Para qué sirve `.gitattributes` y qué error evita?
Define reglas de Git por tipo de archivo; aquí fuerza finales de línea LF en `.sh`, `.sql` y `.md`. Evita que los archivos creados en Windows lleven CRLF, que en Linux rompe scripts con errores como `$'\r': command not found` y llena los diffs de ruido. En mi caso Git me avisó con `CRLF will be replaced by LF` al añadir un log de evidencia: esa regla estaba actuando.

### 12. ¿Por qué merge commit y no Squash and merge?
Squash fusionaría todos los commits de la branch en uno solo. Con el merge commit se conservan los commits individuales, uno por cada Parte del laboratorio, así que el historial de `main` muestra paso a paso cómo se construyó el entorno y se puede revisar o revertir cada parte por separado.

## Seguridad

### 13. Las cuatro capas de la estrategia de contraseñas
Capa 1: `.gitignore` indica a Git que ignore `config/.env` y `backups/`. Capa 2: `config/.env.example` es una plantilla versionada con valores de ejemplo, sin secretos. Capa 3: `config/.env` es el archivo real, solo local, con las contraseñas verdaderas. Capa 4: los scripts leen las contraseñas con `set -a; source config/.env; set +a` y las usan como variables, sin escribirlas a mano. Si me salto la primera, un simple `git add .` subiría `config/.env` y la contraseña quedaría para siempre en el historial.

### 14. ¿Por qué no escribir la contraseña directamente en `docker run`?
Aunque el script no se suba a Git, la contraseña escrita a mano queda en el historial de la terminal (`~/.bash_history`), es visible en la lista de procesos mientras se ejecuta y acabaría en las evidencias grabadas con `tee` o `script`. Leyéndola desde `$ORACLE_PWD`, el valor literal nunca se teclea ni se imprime, y además compruebo con `grep -c -F "$ORACLE_PWD"` que no está en ningún log.

### 15. Si descubro mi contraseña en un commit ya publicado, ¿basta borrarla en un commit nuevo?
No: el commit antiguo sigue en el historial y cualquiera puede recuperarla con `git log -p`. Lo primero es **cambiar la contraseña** (considerarla comprometida); después, reescribir el historial para eliminarla (por ejemplo con `git filter-repo` o BFG), forzar el push y avisar al equipo para que actualicen sus copias.

## Oracle y herramientas

### 16. ¿Por qué no usamos `SPOOL` ni `@archivo.sql` con sqlplus dentro del contenedor?
Porque ese sqlplus se ejecuta dentro del contenedor: `SPOOL` escribiría el archivo en el sistema de archivos del contenedor (efímero, fuera del repositorio) y `@archivo.sql` buscaría el archivo allí, no en mi equipo. En su lugar mando el SQL por la entrada estándar con `docker exec -i ... sqlplus ... < archivo.sql | tee evidencia.log`, de modo que la evidencia se guarda en mi repositorio. `SPOOL` sí lo usé en SQLcl (evidencia 10), que corre en mi equipo.

### 17. ¿Qué hace `WHENEVER SQLERROR EXIT SQL.SQLCODE` y qué pasaría sin ella?
Hace que SQL*Plus termine en cuanto una sentencia falla y devuelva el código del error de Oracle. Con eso mi script `08` puede detectar el fallo y parar. Sin esa línea, sqlplus seguiría ejecutando el resto del archivo y terminaría con código 0, así que la migración parecería correcta aunque hubiera dejado la base a medias, por ejemplo con un usuario creado sin su tablespace.

### 18. ¿Qué es una migración y por qué no se editan V000 y V001 una vez aplicadas?
Una migración es un script SQL numerado y versionado que cambia la base de forma ordenada y reproducible. Una vez aplicadas, la base ya las ejecutó: si edito `V000`, la base real no cambia pero el archivo sí, y mis compañeros acabarían con esquemas distintos. Los cambios nuevos van en otra migración (`V002`, etc.). Además no son idempotentes: relanzar `V000` falla porque los tablespaces y usuarios ya existen.

### 19. ¿Por qué `FREEPDB1` y no `FREE` ni un SID?
`FREEPDB1` es el servicio de la base conectable (PDB), la base de trabajo donde viven mis usuarios y esquemas; con `SHOW CON_NAME` comprobé que estaba en `FREEPDB1`. `FREE` es el contenedor raíz (CDB), reservado a la administración del motor, y un SID es el identificador antiguo de la instancia, que no distingue la PDB. Por eso en SQL Developer se rellena el campo Service name.

### 20. ¿Qué aporta SQLcl frente a SQL*Plus y por qué dominar ambas?
SQLcl, basado en Java, añade autocompletado, historial, formatos de salida legibles (`SET SQLFORMAT ansiconsole`) y conexiones guardadas (`CONNECT -save`, sin guardar la contraseña). SQL*Plus es más básico, pero viene instalado en cualquier servidor y dentro del contenedor, y es el que existe cuando no puedo instalar nada. En este laboratorio usé sqlplus vía `docker exec` para las migraciones y SQLcl para la sesión interactiva.

## Entorno de trabajo

### 21. ¿Por qué pasar de Git Bash a Ubuntu en WSL 2?
Ubuntu en WSL 2 es un Linux real, igual que el que hay en los servidores. Problemas concretos de Git Bash que desaparecen: no tiene gestor de paquetes (`apt`), así que no puedo instalar `tmux` ni `shellcheck`; y convierte automáticamente rutas como `/opt/...` o las de `-v` en rutas de Windows, lo que rompe comandos de Docker. También arrastra más problemas con finales de línea CRLF y permisos.

### 22. ¿Por qué `~/oracle-database-lab` y no `/mnt/c/...`? ¿Y bash frente a zsh?
El repositorio debe vivir en el sistema de archivos de Linux (ext4): `/mnt/c` pasa por la capa de Windows, es más lenta y no respeta los permisos de Linux; de hecho los archivos que copié desde allí aparecían como `-rwxrwxrwx`. Para los scripts usamos bash porque es el intérprete estándar (`#!/usr/bin/env bash`) y está en cualquier sistema; zsh tiene diferencias de sintaxis (arrays, expansión de variables) y un script escrito para bash, como los míos con `${!v}`, no tiene por qué funcionar igual.
