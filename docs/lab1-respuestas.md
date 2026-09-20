# Preguntas de Comprobación - Laboratorio 1

### 1. ¿Cuál es la diferencia entre Working Directory, Staging Area y Local Repository?
* **Working Directory:** Es el directorio de trabajo local en el disco donde creas y editas los archivos.
* **Staging Area:** Es una zona intermedia de preparación donde seleccionas únicamente los cambios que quieres incluir en el próximo commit.
* **Local Repository:** Es la base de datos (.git) en tu ordenador donde se guardan de forma permanente los commits e historial.
* **Ejemplo:** Creas `notas.txt` en tu carpeta (Working Directory). Ejecutas `git add notas.txt` para enviarlo a la zona de preparación (Staging Area). Finalmente ejecutas `git commit -m "add notes"` y el archivo queda registrado de forma permanente en la base de datos local (Local Repository).

### 2. Si modificas un archivo pero no haces git add, ¿aparece ese cambio en tu próximo commit?
No. Git solo incluye en la foto del commit los cambios que hayan sido agregados explícitamente al Staging Area mediante `git add`. Los cambios no preparados permanecen en el Working Directory y no forman parte del historial guardado.

### 3. ¿Por qué git status no mostraba las carpetas vacías en la Parte C? ¿Qué truco usamos?
Git únicamente rastrea archivos y su contenido, no carpetas/directorios vacíos. Para solucionarlo usamos el truco de crear un archivo oculto vacío llamado `.gitkeep` dentro de cada carpeta vacía, forzando a Git a reconocer la estructura de directorios.

### 4. Explica con tus palabras qué es HEAD.
`HEAD` es un indicador o puntero en Git que señala exactamente la rama y el commit en el que te encuentras trabajando en este momento ("usted está aquí").

### 5. Diferencia entre git switch -c y mkdir. ¿Cómo se comprobó en la Parte G?
`mkdir` crea una carpeta física en el disco duro. `git switch -c` crea una rama en Git para gestionar versiones sobre los mismos archivos. Lo comprobamos ejecutando `ls docs/`: al estar en la rama `main` no veíamos `customer-search.md`, pero al cambiar a la rama `feature/customer-search` el archivo apareció inmediatamente en la misma ubicación del disco.

### 6. Durante el conflicto de la Parte H, ¿qué representaba el contenido entre <<<<<<< HEAD, ======= y >>>>>>>?
* Entre `<<<<<<< HEAD` y `=======`: El contenido que existía en la rama actual en la que estabas parado (`main`).
* Entre `=======` y `>>>>>>>`: El contenido que venía de la rama que intentabas fusionar (`feature/customer-search`).

### 7. ¿Por qué NO se debe hacer git commit --amend sobre un commit que ya se subió con git push?
Porque `--amend` reemplaza el commit existente por uno completamente nuevo con un Hash distinto (reescribe el historial). Si ya se había subido a GitHub, el historial local y el remoto diferirán, lo que causará conflictos de sincronización (`non-fast-forward`) a ti y a tus colaboradores.

### 8. Si borras por accidente la carpeta .git, ¿qué se pierde? ¿Se pierde el código fuente?
Se pierde todo el historial de commits, las ramas, la configuración remota y la capacidad de control de versiones. **No** se pierde el código fuente ni los archivos actuales del proyecto que están visibles en tu disco duro.

### 9. Diferencia entre Git y GitHub (sin usar la palabra "nube").
* **Git:** Es la herramienta de software local instalada en tu ordenador que gestiona el historial y las versiones de tu código.
* **GitHub:** Es una plataforma web en servidores remotos que aloja repositorios de Git para compartir código, respaldarlo y colaborar con otros desarrolladores.

### 10. ¿Por qué no se debe subir un archivo .env con contraseñas reales?
Porque el historial de Git es permanente e inmutable; aunque borres el archivo en un commit posterior, las claves seguirán visibles en commits antiguos. Además, cualquier persona con acceso al código o repositorios clonados podría ver tus credenciales y vulnerar los sistemas.

### 11. Error "non-fast-forward" al hacer push. ¿Qué ocurrió y qué comando ejecutar primero?
Ocurrió porque el repositorio remoto en GitHub tiene commits nuevos que no existen en tu ordenador local. Primero se debe ejecutar `git pull` para descargar e integrar esos cambios antes de poder subir los propios.

### 12. Tipos de Conventional Commit
* Añadir un índice de rendimiento a una tabla: `perf: add index to customer search table`
* Corregir una restricción mal definida: `fix: correct foreign key constraint`
* Actualizar el README: `docs: update README documentation`
