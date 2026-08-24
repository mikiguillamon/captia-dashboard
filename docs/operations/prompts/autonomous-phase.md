# Prompt: autonomous phase execution

La especificacion y el plan de la fase [N] estan aprobados.

Ejecuta la fase de forma autonoma.
No comiences la fase siguiente.

Reglas:

1. Usa GSD como lifecycle orchestrator.
2. Respeta AGENTS.md y las fuentes de verdad.
3. No vuelvas a investigar decisiones ya documentadas.
4. No preguntes por detalles locales o reversibles.
5. Escala unicamente las decisiones cubiertas por AUTONOMY_POLICY.md.
6. Ejecuta tests durante la implementacion.
7. No debilites tests para hacerlos pasar.
8. Mantiene documentacion sincronizada cuando cambie una decision duradera.
9. Si encuentras un bug relacionado y necesario para completar la fase, corrigelo.
10. Si descubres deuda no necesaria para la fase, registrala pero no amplíes alcance.
11. Antes de terminar, ejecuta verificacion y review apropiados.
12. No empieces la siguiente fase.

Cuando termines, dame unicamente el checkpoint humano definido para final de fase.
