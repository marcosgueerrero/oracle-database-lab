He leído la política de uso de IA de la asignatura.

# Declaración de uso de IA · Lab 6 · E030

## Entrada 1
- **Herramienta:** ChatGPT (OpenAI, GPT-6).
- **Prompt (literal, copiado tal cual):**
  tengo que realizar una tarea de clase, quiero que me la hagas y me digas paso a paso lo que tengo que hacer
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
  Comandos Bash usados en la preparación inicial:

      find ~ -type d -name "repo-kit" 2>/dev/null
      ls -la ~
      ls -la /mnt/c/Users/mguer/Downloads/P2_Lab6_v1.3_Estudiante/repo-kit
      mkdir -p scripts/lab6
      mkdir -p docs/plantillas
      mkdir -p docs/bitacora/lab6
- **Dónde lo usé (parte, script o pregunta):** Parte A, preparación inicial del Laboratorio 6 y configuración del repositorio.
- **Propósito (para qué lo necesitaba):** Localizar el material proporcionado por el profesor, comprobar la estructura del repositorio e incorporar los archivos necesarios para realizar la práctica.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** El comando find busca la carpeta repo-kit dentro de mi directorio personal. Los comandos ls muestran el contenido de las carpetas para comprobar qué archivos hay. Los comandos mkdir crean las carpetas necesarias para organizar los scripts, las plantillas y las evidencias del Laboratorio 6.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):** Pendiente de generar y guardar el registro de ejecución de la preparación inicial en docs/bitacora/lab6/evidencia/script/. Se añadirá la ruta exacta cuando se genere la evidencia.

## Entrada 2
- **Herramienta:** ChatGPT (OpenAI, GPT-6).
- **Prompt (literal, copiado tal cual):**
  necesito mas fluidez, dame las instrucciones de que tengo que seguir haciendo hasta completar la tarea en vez de en una en una e ir comprobando una en una, de 3 en 3 e ir comprobando o algo asi
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
  Comandos Bash para ejecutar:
  bash scripts/ops/ro.sh scripts/ops/turno.sql
  bash scripts/ops/ro.sh scripts/lab6/01-automatizacion.sql freepdb1
- **Dónde lo usé (parte, script o pregunta):** Parte B, lista de turno y automatización de Oracle.
- **Propósito (para qué lo necesitaba):** Comprobar el estado de la instancia, las PDB, los errores ORA, las sesiones, los tablespaces y los procesos automáticos de mantenimiento.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** El primer comando ejecuta consultas de solo lectura para revisar el estado general de Oracle. El segundo consulta las tareas automáticas, las ventanas de mantenimiento, los umbrales de espacio, la configuración AWR y los trabajos del Scheduler.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):**
  docs/bitacora/lab6/evidencia/script/20261124T185039Z_01-turno.script.log
  docs/bitacora/lab6/evidencia/script/20261124T185105Z_01-automatizacion.script.log
  docs/bitacora/lab6/evidencia/spool/20261124T185108Z_01-automatizacion.spool.log

## Entrada 3
- **Herramienta:** ChatGPT (OpenAI, GPT-6).
- **Prompt (literal, copiado tal cual):**
  seguimos
- **Código recibido (el fragmento, o la ruta del archivo donde está):**
  Comandos Bash para ejecutar los scripts:
  scripts/lab6/04-tres-miradas.sh
  scripts/lab6/04-diccionario.sql
  scripts/lab6/04-deltas.sql
- **Dónde lo usé (parte, script o pregunta):** Parte E, diccionario y medición de actividad.
- **Propósito (para qué lo necesitaba):** Realizar los ejercicios de la Parte E y obtener las evidencias correspondientes.
- **Qué hace (con mis palabras; línea a línea si es SQL corto):** Los scripts comparan lo que pueden consultar tres identidades diferentes, examinan las vistas y sinónimos del diccionario y miden el coste de una carga de consultas mediante dos fotografías de las estadísticas de Oracle.
- **Evidencia de ejecución (archivo de docs/bitacora/lab6/evidencia con mi cabecera):**
  Evidencias de los ejercicios E.1, E.2 y E.3 en docs/bitacora/lab6/evidencia/script/ y docs/bitacora/lab6/evidencia/spool/.
