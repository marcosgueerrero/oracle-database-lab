# Lab 2 — Preguntas de comprobación

1. Un Issue sin criterios de aceptación es un problema porque, aunque la descripción parezca clara, nadie sabe objetivamente cuándo el trabajo está "terminado". Sin checklist verificable, el criterio de "hecho" queda a la interpretación personal de cada uno.

2. "Refs #N" solo crea una referencia cruzada visible en el Issue, que permanece abierto. "Closes #N" (o Fixes/Resolves) cierra automáticamente el Issue, pero solo en el momento en que el commit o PR que lo contiene llega a main.

3. Git rechaza el push con el error "GH006: Protected branch update failed". No es un fallo del sistema: es la protección de main funcionando exactamente como se configuró, para forzar que todo cambio pase por un Pull Request.

4. El riesgo es aprobar sin comprobar que el cambio realmente resuelve el problema, sin verificar seguridad, legibilidad o si introduce errores. Es un "rubber-stamping" que anula el propósito del code review.

5. No hace falta abrir un PR nuevo. Como el PR está vinculado a la branch, cualquier nuevo commit que se haga push sobre esa misma branch se añade automáticamente al PR existente.

6. Merge commit conserva todos los commits de la branch más un commit de fusión. Squash and merge combina todos los commits en uno solo. Rebase and merge reaplica los commits sin crear un commit de fusión. Para una branch con commits "wip", "fix", "fix2", "ok ya" usaría Squash and merge, porque esos commits no aportan valor individual y conviene dejar un historial limpio en main.

7. Borrar la branch solo elimina el puntero que ya no hace falta; los commits ya integrados permanecen en el historial de main gracias a la estrategia de fusión utilizada.

8. Como mínimo debe contener: qué hace el cambio (Summary), por qué se hace (Related Issue), cómo probarlo (Testing), y qué archivos cambian (Changes).

9. Le falta indicar qué está mal exactamente, por qué importa y qué se propone hacer al respecto. Reescrito: "issue (blocking): esta validación no comprueba si la tabla está vacía; propongo añadir un chequeo de count(*) = 0 antes de continuar."

10. Que main "esté protegida" significa que GitHub impide técnicamente el push directo sin excepciones. Que el equipo "se ponga de acuerdo" es solo una norma de comportamiento que depende de la disciplina de cada persona y puede romperse por error o urgencia.

11. Ejemplo de issue: (blocking): "issue (blocking): esta consulta no filtra por usuario y expondría datos de otros clientes." Ejemplo de nitpick: (if-minor): "nitpick (if-minor): esta variable podría llamarse de forma más descriptiva, pero no es crítico."

12. feat!: dispara una versión MAJOR (por ejemplo de 2.1.0 a 3.0.0), porque el símbolo ! indica un cambio que rompe la compatibilidad con versiones anteriores.

13. Abrir un Draft PR desde el primer commit estructural permite validar el enfoque general con los compañeros antes de invertir horas en la lógica detallada, evitando la falacia del coste hundido si el diseño inicial resulta equivocado. Aunque parezca más lento al principio, ahorra tiempo total al equipo.