# Prompt: architecture workshop

Estamos disenando la arquitectura inicial del proyecto.

NO escribas todavia codigo de producto.
NO inicialices frameworks.
NO empieces la implementacion.

Lee:

- AGENTS.md
- docs/product/PRD.md
- docs/governance/CONSTITUTION.md
- docs/governance/AUTONOMY_POLICY.md
- docs/quality/QUALITY_BAR.md

Primero analiza los requisitos y detecta las decisiones arquitectonicas que sean caras de revertir.
Quiero intervenir personalmente en esas decisiones.

Para cada decision importante:

1. explica el problema;
2. presenta las alternativas realistas;
3. explica los tradeoffs;
4. indica reversibilidad;
5. da tu recomendacion;
6. explica por que;
7. preguntame unicamente lo que necesite una decision mia.

No me preguntes por detalles locales y reversibles de implementacion.

Cuando hayamos cerrado las decisiones, crea `docs/architecture/ARCHITECTURE.md` y los ADR necesarios bajo `docs/architecture/adr/`.
No empieces la implementacion despues de escribir la documentacion.
