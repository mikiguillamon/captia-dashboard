# Arquitectura

## Estado

Arquitectura base aprobada para el MVP. Los estados concretos, permisos atómicos, retención y KPIs específicos siguen abiertos según el PRD.

## Contexto del sistema

Captia es el portal operativo y de cliente para servicios normalmente ejecutados por sistemas externos. Centraliza observabilidad, colaboración, documentación, control y trazabilidad mediante una API privada y un portal para personas.

La infraestructura del MVP será autoalojada. No se adoptan SaaS ni servicios operativos externos salvo necesidad extrema, aprobación explícita y posibilidad de autoalojamiento.

## Componentes y responsabilidades

La aplicación es un monolito modular, desplegado como una unidad, con límites explícitos entre estos módulos:

- Identidad y sesiones.
- Autorización y tenancy.
- CRM y aprovisionamiento.
- Catálogo de servicios e instancias.
- Operación: interacciones, actividad, acciones supervisadas, tareas e incidencias.
- Eventos, proyecciones, métricas y frescura.
- Documentación, conocimiento y sincronización.
- Notificaciones, exportaciones y auditoría.

Los módulos se comunican mediante interfaces internas explícitas. Ningún módulo usa las tablas de otro como contrato.

## Modelo de datos

La jerarquía base es `Cuenta → Organización → Servicio → Instancia de servicio`. Los usuarios reciben roles, asignaciones de ámbito y excepciones; el acceso a una organización no concede acceso a las demás de una cuenta.

Estado contractual, estado operativo y estado de salud son dimensiones separadas. Interacciones, eventos, evaluaciones, feedback, tareas, incidencias y versiones documentales conservan el contexto de origen necesario para su trazabilidad.

## Persistencia y aislamiento

PostgreSQL autoalojado es la persistencia principal, compartida entre clientes. Cada registro de cliente lleva el ámbito de Cuenta u Organización requerido. La aplicación aplica la autorización de forma centralizada y PostgreSQL aporta una segunda barrera mediante políticas de seguridad por fila. Workers e integraciones deben establecer el mismo contexto de ámbito y no pueden eludir esas políticas.

Captia custodia el contenido sensible necesario para vistas y trazabilidad, incluidos emails, conversaciones, transcripciones y documentos. Los datos operativos y los objetos de contenido se separan para aplicar acceso, cifrado y retención. Los plazos y el tratamiento de eliminación no se presuponen.

## Interfaces y contratos

Las integraciones administradas por el equipo usan una API privada, versionada y validada en el límite de entrada. Todo evento operativo aceptado tiene versión de contrato, identidad de integración, contexto de ámbito, fecha de origen y clave de idempotencia cuando exista. Eventos inválidos no afectan las vistas normales; los utilizables pero incompletos se marcan como tales.

Publicar conocimiento y confirmar su sincronización externa son estados distintos. Captia no presume que una acción externa se haya ejecutado sin confirmación del sistema que la realiza.

## Eventos y trabajo asíncrono

Los eventos operativos se conservan en un ledger canónico, inmutable, versionado e idempotente. Proyecciones derivadas alimentan actividad legible, interacciones, métricas, frescura e incidencias. Esto no es event sourcing completo: cada módulo conserva sus propias entidades de comando.

El trabajo asíncrono usa un outbox transaccional y trabajos persistidos en PostgreSQL: proyecciones, reintentos, notificaciones e incidencias. La interfaz interna de trabajos permitirá sustituir la implementación si el volumen lo exige y se aprueba. El objetivo es reflejar un evento aceptado en las vistas operativas en 30 segundos.

## Autenticación y autorización

Captia implementa identidad nativa y autoalojada: credenciales, recuperación, sesiones y MFA. MFA será obligatorio para usuarios internos y exigible por cada organización cliente. No habrá IdP ni proveedor externo en el MVP.

Autenticación e identidad no conceden permisos. La autorización evalúa el ámbito y las capacidades en cada acción. La impersonación usa el alcance del usuario cliente, pero registra actor interno real, usuario impersonado y acción resultante; esa auditoría solo es visible al personal interno autorizado.

## Integraciones, observabilidad y seguridad

Los sistemas externos de Email Assistant, Chatbot y Voice Assistant se limitan a consumir la API privada, emitir eventos y confirmar sincronizaciones. Captia no modifica prompts, modelos o workflows de esos sistemas en el MVP.

El sistema diferencia cero, ausencia, dato incompleto, dato desactualizado y error. Los fallos persistentes son diagnosticables y pueden generar incidencias. La actividad de cliente se expresa en lenguaje humano y solo revela detalle subyacente cuando el usuario tiene permiso.

Las fronteras de seguridad prioritarias son identidad, ámbito, API privada, contenido sensible, exportaciones, auditoría e impersonación. Toda exportación hereda los permisos del portal.

## Resiliencia y pruebas

El MVP tiene RPO aproximado de una hora y RTO de hasta 24 horas, sin SLA contractual. Durante una caída, acciones supervisadas pueden quedar bloqueadas y nunca se ejecutan por vencimiento.

Las pruebas críticas cubrirán aislamiento de tenants, autorización, MFA, impersonación, idempotencia, métricas, frescura, publicación/sincronización y borrado controlado. Los cambios de seguridad requieren revisión explícita.

## Riesgos y restricciones

- La identidad nativa aumenta la responsabilidad de seguridad del producto.
- El aislamiento compartido exige pruebas rigurosas de aplicación y base.
- La cola en PostgreSQL se reevaluará si no cumple los objetivos de volumen o latencia.
- Retención, permisos atómicos, estados y métricas específicas siguen siendo decisiones abiertas.

## ADR relacionados

- [ADR 0001: Monolito modular](adr/ADR-0001-monolito-modular.md)
- [ADR 0002: Multi-tenancy y autorización](adr/ADR-0002-multitenancy-y-autorizacion.md)
- [ADR 0003: Identidad nativa autoalojada](adr/ADR-0003-identidad-nativa-autoalojada.md)
- [ADR 0004: Ledger de eventos y proyecciones](adr/ADR-0004-ledger-de-eventos-y-proyecciones.md)
- [ADR 0005: Outbox y trabajos persistidos](adr/ADR-0005-outbox-y-trabajos-persistidos.md)
- [ADR 0006: Custodia de contenido sensible](adr/ADR-0006-custodia-de-contenido-sensible.md)
- [ADR 0007: Infraestructura autoalojada](adr/ADR-0007-infraestructura-autoalojada.md)

