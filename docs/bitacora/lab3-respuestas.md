# Respuestas del Laboratorio 3 - Instalación del Entorno Oracle

## Sección 9: Preguntas de Verificación y Conceptos

### Docker y Contenedores
1. **¿Qué diferencia existe entre una imagen de Docker y un contenedor?**
   - *Respuesta:* Una imagen es una plantilla estática de solo lectura con el código y dependencias. Un contenedor es una instancia en ejecución de esa imagen.

2. **¿Por qué se utiliza un volumen persistente para los datos de Oracle en lugar de guardarlos dentro del contenedor?**
   - *Respuesta:* Para evitar la pérdida de datos al reiniciar o eliminar el contenedor, manteniendo la persistencia en el sistema de archivos del host.

3. **¿Qué función cumple la publicación de puertos (ej. `-p 1521:1521`)?**
   - *Respuesta:* Mapea un puerto de la máquina host hacia un puerto interno del contenedor, permitiendo la conexión desde clientes externos como SQL Developer.

4. **¿Qué significa que un contenedor reporte el estado `healthy`?**
   - *Respuesta:* Indica que el chequeo de salud (*healthcheck*) configurado ha verificado con éxito que el servicio interno (Oracle DB) está listo para aceptar conexiones.

5. **Explicación del comando `docker logs -f`:**
   - *Respuesta:* Muestra las salidas estándar e historial del contenedor de forma continua y en tiempo real (*tailing*).

6. **¿Qué diferencia hay entre `docker stop` y `docker rm`?**
   - *Respuesta:* `docker stop` detiene el proceso del contenedor sin borrarlo; `docker rm` elimina definitivamente la instancia del contenedor.

7. **¿Por qué es importante reutilizar variables de entorno (`00-config.sh`) en lugar de escribir nombres a mano en cada script?**
   - *Respuesta:* Garantiza consistencia en la nomenclatura, reduce errores humanos y facilita el mantenimiento centralizado del entorno.

### Seguridad y Configuración
8. **¿Por qué nunca se debe guardar el archivo `config/.env` en el repositorio de Git?**
   - *Respuesta:* Porque contiene credenciales y contraseñas reales que quedarían expuestas públicamente en el historial del repositorio.

9. **¿Qué función cumple la plantilla `config/.env.example`?**
   - *Respuesta:* Sirve como guía o estructura previa para que otros desarrolladores conozcan qué variables definir sin revelar claves reales.

10. **¿Para qué sirve el archivo `.gitignore`?**
    - *Respuesta:* Especifica patrones de archivos y carpetas que Git debe ignorar explícitamente para evitar subir secretos, datos pesados o temporales.

11. **¿Qué regla añade `.gitattributes` con respecto a los finales de línea?**
    - *Respuesta:* Normaliza los finales de línea (`LF` en scripts Shell/Linux) para evitar incompatibilidades de formato entre Windows y Linux.

### Arquitectura de Oracle y Negocios
12. **¿Qué es un Tablespace en Oracle Database y por qué se crean separados para cada esquema?**
    - *Respuesta:* Es una estructura lógica de almacenamiento de datos; crearlos separados mejora el aislamiento, la gestión de almacenamiento y el rendimiento.

13. **¿Cuál es la diferencia entre un usuario (esquema) y un tablespace?**
    - *Respuesta:* El usuario/esquema es el propietario lógico de las tablas y objetos; el tablespace es el espacio físico/lógico donde se guardan sus datos.

14. **¿Qué propósito tienen las migraciones `V000` y `V001`?**
    - *Respuesta:* `V000` crea los tablespaces y usuarios base; `V001` crea la estructura inicial de tablas y objetos para cada negocio.

15. **¿Por qué las migraciones SQL deben comenzar con `WHENEVER SQLERROR EXIT FAILURE`?**
    - *Respuesta:* Para abortar la ejecución inmediatamente ante cualquier error SQL, evitando que el proceso continúe en un estado corrupto o incompleto.

16. **Nombra los 5 entornos/esquemas de negocio provisionados:**
    - *Respuesta:* Academia, Clínica, Retail, Logística y Fintech.

### Herramientas y Gestión
17. **¿Qué diferencia hay entre SQL*Plus y SQLcl?**
    - *Respuesta:* SQL*Plus es la herramienta clásica de línea de comandos; SQLcl es una alternativa moderna basada en Java con autocompletado y mejor formato.

18. **¿Qué es Database Actions (ORDS) y qué ventaja ofrece?**
    - *Respuesta:* Es una interfaz web basada en navegador para administrar y consultar Oracle sin requerir instalar software cliente local.

19. **¿Por qué realizamos el trabajo en una rama `chore/...` en lugar de subirlo directo a `main`?**
    - *Respuesta:* Para aislar el desarrollo, permitir revisión mediante Pull Requests y proteger la estabilidad de la rama principal.

20. **¿Qué es una revisión con Conventional Comments en un PR?**
    - *Respuesta:* Un estándar para formatear retroalimentación en revisiones de código (ej. `nit:`, `suggestion:`, `issue:`) haciendo los comentarios claros e intencionados.

21. **¿Qué ocurre cuando realizamos `git pull origin main` tras un merge en GitHub?**
    - *Respuesta:* Descarga e integra los cambios aprobados desde el servidor remoto hacia la copia local de `main`.

22. **¿Qué verificación realiza el script `03-verify-lab.sh`?**
    - *Respuesta:* Comprueba la conectividad, estado de los contenedores, existencia de usuarios, tablespaces y la correcta aplicación de tablas de negocio.

