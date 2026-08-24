# Product Requirements Document

## 1. Product vision

Construir un portal de clientes que centralice los servicios prestados a cada cuenta y permita a los clientes entender de forma clara:

- qué servicios tienen contratados;
- cuál es su estado actual;
- qué actividad están realizando;
- cuánto trabajo están ejecutando;
- qué resultados están obteniendo;
- qué parte de esa actividad ha sido evaluada como correcta o incorrecta;
- qué incidencias existen;
- qué elementos requieren intervención humana;
- qué documentación y conocimiento están asociados a cada servicio.

La plataforma debe servir simultáneamente como herramienta operativa interna y como portal para clientes, mostrando diferentes capacidades según usuario, rol, organización, servicio y configuración de autogestión.

La plataforma también incorporará un CRM exclusivamente interno que cubra el ciclo comercial desde lead hasta cliente y conecte posteriormente la relación comercial con las cuentas, organizaciones y servicios del portal.

### Frontera del producto

La plataforma no ejecuta necesariamente los servicios que representa.

Los servicios pueden ejecutarse mediante sistemas externos como agentes, n8n, servicios de telefonía, chatbots u otras integraciones.

La plataforma actúa como capa común de:

- gestión;
- observabilidad;
- colaboración;
- supervisión;
- feedback;
- documentación;
- control;
- trazabilidad.

Los sistemas externos intercambiarán información con la plataforma mediante una API privada.

---

## 2. Problem

Los servicios prestados a un cliente pueden operar actualmente mediante sistemas independientes, lo que fragmenta la información entre automatizaciones, agentes, buzones, conversaciones, llamadas, bases de datos, documentación y herramientas internas.

Esta fragmentación genera varios problemas.

### Para el cliente

El cliente no dispone necesariamente de un único lugar donde pueda:

- comprobar qué servicios tiene activos;
- entender si están funcionando;
- consultar su actividad;
- conocer su volumen de uso;
- analizar resultados;
- detectar errores;
- revisar interacciones;
- proporcionar feedback;
- consultar o modificar documentación;
- intervenir cuando una acción necesita supervisión.

### Para el equipo interno

El proveedor carece de una interfaz compartida desde la que pueda:

- administrar clientes y organizaciones;
- supervisar diferentes servicios;
- detectar problemas operativos;
- recoger feedback estructurado;
- convertir feedback en trabajo de mejora;
- controlar qué puede autogestionar cada cliente;
- gestionar documentación y conocimiento;
- mantener trazabilidad;
- relacionar la actividad operativa con la relación comercial.

### Problema comercial adicional

La gestión comercial anterior a la contratación está separada de la posterior operación del cliente.

La plataforma debe permitir un ciclo continuo:

`Lead → Oportunidad → Cliente → Organización → Servicios → Operación`

---

## 3. Target users

### 3.1 Usuarios internos

#### Superadmin

Usuario con privilegios globales sobre la plataforma.

#### Dirección / Administrador global

Usuario interno con acceso transversal según los permisos asignados a su rol.

#### Comercial

Responsable de leads, oportunidades, contactos y relación comercial.

Por defecto:

- puede acceder al CRM;
- puede consultar información general de las cuentas;
- puede consultar los servicios contratados y su estado general;
- no puede consultar contenido operativo sensible como emails, conversaciones, transcripciones, documentación sensible o feedback detallado.

Podrán concederse excepciones explícitas.

#### Account Manager

Responsable de la gestión operativa de las cuentas asignadas.

Por defecto puede acceder en sus cuentas asignadas a:

- dashboards;
- métricas;
- actividad;
- interacciones;
- feedback;
- tareas;
- incidencias;
- documentación.

No dispone por defecto de privilegios globales de seguridad o administración.

#### Técnico

Responsable de servicios, organizaciones o cuentas asignadas.

Dentro de su alcance asignado puede acceder a la información operativa necesaria para diagnosticar y resolver problemas.

No dispone por defecto de acceso al pipeline comercial completo.

### 3.2 Usuarios cliente

#### Administrador de cuenta

Máximo nivel administrativo del lado cliente.

Puede administrar las organizaciones de su cuenta y utilizar las funcionalidades habilitadas por el proveedor.

#### Administrador de organización

Puede administrar una organización concreta, pero no otras organizaciones de la misma cuenta salvo que se le conceda acceso explícitamente.

#### Usuario operativo

Puede utilizar las funcionalidades de los servicios a los que tenga acceso, pero no administra por defecto organizaciones, usuarios ni permisos.

### 3.3 Sistemas externos

Las integraciones internas son consumidores no humanos de la plataforma.

Podrán registrar y consultar información mediante la API privada según las credenciales y capacidades que tengan concedidas.

---

## 4. Jobs and primary use cases

### 4.1 Cliente

El cliente necesita poder:

1. comprobar rápidamente el estado de sus servicios;
2. saber qué actividad están realizando;
3. entender el volumen de trabajo ejecutado;
4. distinguir resultados técnicos, operativos y evaluaciones humanas;
5. investigar métricas accediendo a las interacciones que las explican;
6. revisar conversaciones, emails y llamadas;
7. marcar resultados como correctos o incorrectos;
8. proponer una respuesta correcta cuando una respuesta sea incorrecta;
9. añadir comentarios;
10. participar en acciones supervisadas cuando tenga permisos;
11. revisar tareas pendientes;
12. consultar incidencias;
13. consultar y modificar documentación según permisos;
14. gestionar usuarios cuando tenga capacidad para hacerlo;
15. consultar información desde móvil para supervisión y acciones rápidas.

### 4.2 Equipo interno

El equipo interno necesita poder:

1. gestionar leads y oportunidades;
2. convertir oportunidades ganadas en clientes;
3. configurar cuentas y organizaciones;
4. activar servicios;
5. configurar instancias;
6. controlar niveles de autogestión;
7. asignar usuarios y permisos;
8. supervisar actividad;
9. investigar resultados;
10. gestionar feedback;
11. convertir feedback en tareas de mejora;
12. gestionar documentación y conocimiento;
13. gestionar incidencias;
14. diagnosticar problemas;
15. impersonar usuarios cliente cuando tenga permiso;
16. acceder a trazabilidad interna;
17. finalizar o archivar servicios;
18. configurar qué información se muestra al cliente.

---

## 5. Product principles

### 5.1 Transparencia operativa

El portal debe permitir que el cliente entienda qué está ocurriendo con sus servicios sin necesitar acceder a las herramientas técnicas que los ejecutan.

### 5.2 No presentar incertidumbre como certeza

La plataforma debe distinguir entre:

- valor cero;
- ausencia de datos;
- datos incompletos;
- datos desactualizados;
- error.

La plataforma no debe inventar valores faltantes.

### 5.3 Separar dimensiones de resultado

No debe existir una única métrica universal de "éxito".

Cuando corresponda se distinguirán:

- estado técnico;
- resultado operativo;
- evaluación humana.

### 5.4 Configuración controlada

El cliente puede disponer de distintos niveles de autogestión, pero el proveedor conserva la capacidad de limitar qué acciones están disponibles.

### 5.5 Extensibilidad mediante tipos de servicio

Los tipos de servicio se desarrollarán explícitamente.

No existirá en el MVP un constructor genérico no-code de servicios.

Cada tipo podrá permitir múltiples instancias configurables.

### 5.6 Interfaz para humanos, eventos para sistemas

Las integraciones pueden trabajar con eventos granulares.

El cliente debe ver actividades comprensibles, no logs técnicos.

### 5.7 API como interfaz de integración

Las principales operaciones del dominio deberán poder realizarse mediante una API privada para integraciones desarrolladas por el equipo técnico.

### 5.8 Historial y trazabilidad

Las acciones operativas relevantes deben conservar el contexto suficiente para poder entender qué ocurrió posteriormente.

---

## 6. User journeys

### 6.1 De oportunidad a cliente

`Oportunidad → Ganada → Conversión asistida → Cuenta → Organización → Servicios → Instancias → Usuarios → Activación del portal`

Al marcar una oportunidad como ganada se inicia un proceso asistido que permite revisar los datos antes de activar el portal.

### 6.2 Supervisión diaria

`Login → Selección de cuenta/organización → Overview → Estado + métricas + pendientes → Servicio → Detalle`

### 6.3 Investigación de una métrica

`Dashboard → Métrica → Drill-down → Histórico filtrado → Interacción → Detalle`

### 6.4 Feedback

`Interacción → Evaluación → Corrección/comentario → Feedback → Posible tarea → Resolución`

### 6.5 Acción supervisada

`Sistema externo genera acción → Portal la registra como pendiente → Usuario autorizado revisa → Edita/aprueba/rechaza → Sistema externo continúa`

Si expira el plazo de revisión:

`Pendiente → Expirada / requiere atención`

No se ejecuta automáticamente.

### 6.6 Gestión documental

`Documento → Borrador → Cambio propuesto → Aprobación → Publicación → Evento de sincronización → Confirmación externa`

Publicación y sincronización son estados diferentes.

### 6.7 Incidencia

`Detección automática o manual → Incidencia → Información interna + información pública → Actualizaciones → Resolución`

### 6.8 Finalización de servicio

`Servicio activo → Cancelación inmediata o programada → Fecha efectiva → Finalizado → Política de acceso histórico`

---

## 7. Functional requirements

### Accounts, organizations and users

**FR-001** La plataforma deberá permitir crear y gestionar cuentas comerciales.

**FR-002** Una cuenta deberá poder contener una o más organizaciones.

**FR-003** La plataforma deberá permitir usuarios con acceso a nivel de cuenta y usuarios con acceso limitado a organizaciones concretas.

**FR-004** Un usuario podrá tener acceso a más de una organización cuando sus permisos lo autoricen.

**FR-005** El acceso a una organización no deberá conceder automáticamente acceso a otras organizaciones de la misma cuenta.

**FR-006** La plataforma deberá incluir los roles internos base: Superadmin, Dirección/Administrador global, Comercial, Account Manager y Técnico.

**FR-007** La plataforma deberá incluir los roles cliente base: Administrador de cuenta, Administrador de organización y Usuario operativo.

**FR-008** Los roles deberán actuar como plantillas de permisos y admitir capacidades y excepciones.

**FR-009** Los permisos deberán poder heredarse desde niveles superiores y sobrescribirse mediante excepciones explícitas.

**FR-010** Los usuarios internos restringidos deberán poder limitarse a cuentas, organizaciones o servicios asignados.

**FR-011** Los administradores cliente autorizados podrán invitar usuarios cuando la configuración de autogestión lo permita.

### Authentication and impersonation

**FR-012** Todos los usuarios deberán utilizar cuentas individuales.

**FR-013** La plataforma deberá exigir MFA a los usuarios internos.

**FR-014** Una organización cliente deberá poder exigir MFA a sus usuarios.

**FR-015** Los perfiles internos autorizados deberán poder impersonar usuarios cliente.

**FR-016** Una sesión de impersonación deberá permitir las mismas operaciones que el usuario impersonado pueda realizar.

**FR-017** La plataforma deberá registrar el actor interno real de todas las acciones realizadas durante una sesión de impersonación.

**FR-018** La notificación al cliente sobre impersonaciones deberá ser configurable por organización.

### Services and instances

**FR-019** La plataforma deberá soportar tipos de servicio predefinidos desarrollados específicamente.

**FR-020** El MVP deberá incluir como mínimo los tipos Email Assistant, Chatbot y Voice Assistant.

**FR-021** Una organización deberá poder tener más de una instancia del mismo tipo de servicio.

**FR-022** Las instancias deberán poder configurarse independientemente cuando el tipo de servicio lo permita.

**FR-023** La posibilidad de que un cliente cree nuevas instancias deberá depender de las capacidades habilitadas para su cuenta o servicio.

**FR-024** La plataforma deberá mantener separado el estado contractual del estado operativo de un servicio.

**FR-025** La plataforma deberá mantener un estado de salud de cada instancia.

**FR-026** El estado de salud deberá poder derivarse de señales automáticas y permitir intervención manual del equipo interno.

**FR-027** La plataforma deberá permitir finalizar un servicio inmediatamente o programar una fecha efectiva de finalización.

**FR-028** La visibilidad histórica del servicio finalizado para el cliente deberá ser configurable por servicio.

### Autonomy and supervised actions

**FR-029** Una instancia deberá poder operar en modo autónomo o supervisado cuando el tipo de servicio soporte ambos modos.

**FR-030** En modo supervisado deberán poder configurarse por permisos las capacidades de ver, editar, aprobar y rechazar una acción.

**FR-031** Las acciones supervisadas deberán poder tener una fecha límite de revisión.

**FR-032** Una acción supervisada vencida no deberá ejecutarse automáticamente.

**FR-033** Una acción vencida deberá quedar identificada como expirada o requiriendo atención.

### Activity and events

**FR-034** Las integraciones deberán poder registrar eventos operativos granulares.

**FR-035** La plataforma deberá poder transformar eventos granulares en actividades visibles comprensibles para usuarios humanos.

**FR-036** El portal no deberá exponer logs técnicos internos como actividad normal del cliente.

**FR-037** El detalle de una actividad deberá permitir consultar la información relevante subyacente cuando el usuario tenga permiso.

### Email Assistant

**FR-038** El Email Assistant deberá mostrar un histórico de emails procesados.

**FR-039** El detalle de un email deberá poder mostrar el email entrante completo.

**FR-040** El detalle deberá indicar la decisión de responder o no responder cuando la integración la proporcione.

**FR-041** El detalle deberá mostrar la respuesta generada cuando exista.

**FR-042** El detalle deberá mostrar la respuesta finalmente enviada cuando exista.

**FR-043** El detalle deberá poder mostrar estado técnico, resultado operativo y evaluación humana por separado.

### Chatbot

**FR-044** El Chatbot deberá mostrar un listado de conversaciones.

**FR-045** La vista de conversación deberá mostrar los mensajes que componen la conversación.

**FR-046** La plataforma deberá identificar las respuestas generadas por el chatbot.

**FR-047** La conversación deberá admitir evaluación global y evaluación de respuestas concretas.

### Voice Assistant

**FR-048** El Voice Assistant deberá mostrar un listado de llamadas.

**FR-049** La llamada deberá mostrar fecha, duración y datos básicos disponibles.

**FR-050** La llamada deberá mostrar la transcripción disponible.

**FR-051** La transcripción deberá poder dividirse en turnos o segmentos identificables.

**FR-052** La llamada deberá admitir evaluación global y evaluación de segmentos concretos.

### Metrics and dashboards

**FR-053** La plataforma deberá ofrecer dashboards a nivel de cuenta, organización, servicio e instancia cuando existan datos compatibles.

**FR-054** El dashboard principal deberá combinar estado operativo y elementos que requieren atención.

**FR-055** El proveedor deberá poder configurar qué widgets se muestran.

**FR-056** Cada tipo de servicio deberá poder definir una configuración de dashboard por defecto.

**FR-057** Una instancia deberá poder sobrescribir la configuración de dashboard definida por su tipo.

**FR-058** El cliente no podrá configurar libremente los widgets del dashboard en el MVP.

**FR-059** Los dashboards deberán permitir seleccionar periodos temporales.

**FR-060** Los dashboards deberán poder comparar un periodo con el periodo inmediatamente anterior equivalente.

**FR-061** Las variaciones de ratios deberán distinguir correctamente entre porcentaje relativo y puntos porcentuales.

**FR-062** Las métricas con datos subyacentes consultables deberán permitir drill-down hacia el histórico filtrado correspondiente.

**FR-063** Las métricas agregadas deberán combinar únicamente dimensiones semánticamente compatibles.

**FR-064** La plataforma deberá distinguir estado técnico, resultado operativo y evaluación humana.

**FR-065** La satisfacción humana deberá calcularse exclusivamente sobre elementos evaluados.

**FR-066** Cuando se muestre satisfacción humana deberá mostrarse también la cobertura de evaluación.

### Data freshness

**FR-067** Las vistas operativas deberán mostrar la fecha u hora de última actualización cuando sea relevante.

**FR-068** La plataforma deberá poder indicar que una integración está sincronizada, desactualizada o sin datos recientes.

**FR-069** Las métricas deberán mostrar una advertencia cuando los datos puedan estar incompletos por problemas de frescura.

**FR-070** Los umbrales de frescura deberán poder definirse por tipo de servicio.

**FR-071** Una instancia deberá poder sobrescribir el umbral de frescura definido por su tipo.

### History and search

**FR-072** La plataforma deberá disponer de históricos cronológicos de actividad.

**FR-073** El histórico deberá permitir búsqueda y filtros.

**FR-074** Los filtros comunes deberán poder incluir, cuando sean aplicables: periodo, organización, servicio, instancia, estado técnico, resultado operativo, evaluación humana, presencia de feedback, presencia de incidencia y texto o identificador.

**FR-075** Los tipos de servicio podrán añadir filtros específicos.

### Feedback and improvement

**FR-076** Una interacción deberá poder recibir evaluación global.

**FR-077** Las partes identificables de una interacción deberán poder recibir evaluaciones individuales cuando el tipo de servicio lo permita.

**FR-078** Una evaluación deberá poder marcarse como correcta o incorrecta.

**FR-079** Una evaluación incorrecta deberá permitir registrar una corrección propuesta.

**FR-080** Una evaluación deberá permitir registrar comentarios.

**FR-081** Una evaluación podrá generar una tarea.

**FR-082** La plataforma deberá permitir gestionar un workflow de mejora posterior al feedback.

**FR-083** La plataforma no deberá modificar directamente prompts, modelos, workflows o configuración técnica de agentes en el MVP.

### Tasks

**FR-084** La plataforma deberá disponer de tareas operativas básicas.

**FR-085** Una tarea deberá poder incluir al menos título, descripción, origen, responsable, estado, comentarios y fechas básicas.

**FR-086** Una tarea podrá originarse desde feedback, incidencias u otras acciones operativas soportadas.

### Incidents

**FR-087** Las incidencias deberán poder crearse manualmente.

**FR-088** Las integraciones deberán poder crear o actualizar incidencias automáticamente.

**FR-089** Una incidencia deberá disponer de información interna e información visible al cliente diferenciadas.

**FR-090** El equipo interno deberá poder decidir qué información de una incidencia se expone al cliente.

**FR-091** Una incidencia deberá disponer de un estado y poder marcarse como resuelta.

### Documentation and knowledge

**FR-092** La plataforma deberá incluir un editor visual capaz de trabajar con contenido representable en Markdown.

**FR-093** Los documentos deberán distinguir entre documentación para humanos y conocimiento destinado a servicios.

**FR-094** La documentación deberá poder existir a diferentes niveles de la jerarquía.

**FR-095** Las instancias deberán poder heredar documentación de niveles superiores.

**FR-096** Un documento específico deberá poder declarar explícitamente que sustituye a un documento heredado.

**FR-097** La plataforma no deberá inferir automáticamente contradicciones semánticas entre documentos.

**FR-098** Los documentos deberán disponer de versiones publicadas.

**FR-099** El historial de versiones deberá permitir identificar autor y fecha.

**FR-100** Deberá poder restaurarse una versión publicada anterior.

**FR-101** Un borrador no deberá sustituir a la versión publicada hasta su aprobación.

**FR-102** Los workflows de aprobación documental deberán ser configurables por organización o servicio.

**FR-103** La publicación de un documento y su sincronización con sistemas externos deberán representarse como estados diferentes.

**FR-104** Cuando se publique conocimiento destinado a un servicio, la plataforma deberá emitir o exponer un evento consumible por integraciones.

**FR-105** Los sistemas externos deberán poder confirmar el resultado de una sincronización.

**FR-106** Una sincronización fallida deberá poder reintentarse automáticamente.

**FR-107** Un fallo persistente de sincronización deberá quedar visible y poder generar una incidencia.

### Deletion and retention

**FR-108** La plataforma deberá permitir políticas de retención configurables.

**FR-109** Deberá existir una política de retención por defecto y posibilidad de excepciones.

**FR-110** La eliminación solicitada por clientes deberá realizarse mediante un workflow de solicitud, revisión y resolución.

**FR-111** Una solicitud de eliminación deberá poder aprobarse o rechazarse.

**FR-112** La auditoría podrá conservar constancia de la eliminación sin conservar necesariamente el contenido eliminado.

### Notifications

**FR-113** La plataforma deberá disponer de notificaciones internas.

**FR-114** La plataforma deberá poder enviar notificaciones por email.

**FR-115** Cada usuario deberá poder configurar preferencias de notificación por categoría dentro de los límites definidos por la plataforma.

**FR-116** La plataforma podrá definir categorías de notificación obligatorias que no puedan desactivarse.

### CRM

**FR-117** El CRM interno deberá gestionar leads.

**FR-118** El CRM deberá gestionar contactos.

**FR-119** El CRM deberá gestionar cuentas.

**FR-120** El CRM deberá gestionar oportunidades comerciales.

**FR-121** El CRM deberá disponer de pipeline con etapas configurables.

**FR-122** Una oportunidad deberá poder almacenar responsable, importe estimado, probabilidad y fecha estimada de cierre.

**FR-123** El CRM deberá permitir notas, actividades y tareas.

**FR-124** El CRM deberá mantener histórico de la actividad comercial registrada.

**FR-125** Al marcar una oportunidad como ganada, la plataforma deberá iniciar una conversión asistida.

**FR-126** La conversión asistida deberá permitir revisar la cuenta, crear o confirmar organizaciones, seleccionar servicios, crear instancias iniciales, configurar permisos e invitar usuarios antes de activar el portal.

### API and integrations

**FR-127** La plataforma deberá disponer de una API privada para integraciones desarrolladas o administradas por el equipo técnico.

**FR-128** Las principales operaciones del dominio disponibles en interfaz deberán poder exponerse mediante API.

**FR-129** La API no será una API pública para clientes en el MVP.

**FR-130** La plataforma deberá conservar los eventos fundamentales recibidos cuando sean necesarios para reconstruir la actividad.

**FR-131** La plataforma deberá calcular métricas comunes a partir de eventos cuando sea posible.

**FR-132** Las integraciones podrán proporcionar métricas específicas de un tipo de servicio.

**FR-133** La plataforma deberá evitar contabilizar dos veces eventos duplicados cuando puedan identificarse inequívocamente.

**FR-134** Los datos incompletos pero utilizables deberán poder registrarse identificando la información afectada como incompleta.

**FR-135** Los datos inválidos que no puedan procesarse no deberán contaminar métricas ni históricos normales.

**FR-136** Los errores persistentes de integración deberán poder generar incidencias.

### Exports

**FR-137** Los usuarios autorizados deberán poder exportar información a la que ya tengan acceso.

**FR-138** Las interacciones y métricas deberán poder exportarse en formatos tabulares como CSV cuando sean compatibles.

**FR-139** La documentación deberá poder exportarse en Markdown.

**FR-140** El MVP no incluirá una exportación integral de toda la cuenta.

---

## 8. Non-functional requirements

**NFR-001** El aislamiento de datos deberá impedir que un usuario acceda a cuentas u organizaciones para las que no tenga permiso.

**NFR-002** MFA deberá ser obligatorio para todos los usuarios internos.

**NFR-003** La plataforma deberá permitir exigir MFA a todos los usuarios de una organización cliente.

**NFR-004** Todas las sesiones de impersonación deberán registrar el actor real, usuario impersonado y acciones ejecutadas.

**NFR-005** La auditoría de seguridad y administración será visible únicamente para usuarios internos autorizados.

**NFR-006** Una vez que un evento haya sido recibido correctamente por la plataforma, deberá estar disponible para las vistas operativas correspondientes en un máximo objetivo de 30 segundos, excluyendo la latencia anterior del sistema externo.

**NFR-007** La plataforma no deberá representar datos desactualizados como si fueran actuales cuando conozca que existe un problema de sincronización.

**NFR-008** La plataforma deberá disponer de mecanismos de recuperación que permitan un RPO objetivo aproximado de una hora.

**NFR-009** Ante un fallo grave que requiera recuperación completa, el RTO aceptado para el MVP será de hasta 24 horas.

**NFR-010** El MVP no tendrá un SLA contractual formal de disponibilidad.

**NFR-011** La plataforma deberá conservar suficiente trazabilidad para diferenciar acciones realizadas directamente por clientes de acciones realizadas mediante impersonación.

**NFR-012** Los fallos persistentes de sincronización no podrán quedar silenciosos.

**NFR-013** El sistema deberá tratar de forma diferenciada cero, dato ausente, dato incompleto, dato desactualizado y error.

**NFR-014** El portal móvil deberá permitir supervisión y acciones rápidas definidas en UX Requirements, sin exigir paridad completa con todas las funciones administrativas de escritorio.

**NFR-015** La plataforma deberá admitir nuevos tipos de servicio mediante desarrollo específico sin requerir rediseñar el modelo base de cuentas, organizaciones, servicios e instancias.

---

## 9. UX requirements

### 9.1 Home

La pantalla inicial deberá combinar:

- estado general;
- métricas principales;
- actividad;
- incidencias;
- tareas;
- elementos pendientes de revisión.

La home debe responder rápidamente:

1. ¿Está funcionando todo?
2. ¿Qué ha ocurrido?
3. ¿Qué resultados se están obteniendo?
4. ¿Hay algo que requiera atención?

### 9.2 Navegación

La navegación utilizará un modelo híbrido.

Contexto global:

`Cuenta / Organización`

Navegación local:

- Overview
- Actividad
- Servicios
- Documentación
- Tareas
- Incidencias
- Usuarios

Los usuarios internos deberán disponer de un mecanismo de búsqueda o cambio rápido de cliente.

### 9.3 Métricas

Las métricas deberán:

- indicar claramente la dimensión que representan;
- separar estado técnico, resultado operativo y evaluación humana;
- indicar cobertura cuando se muestre satisfacción humana;
- indicar posible falta de frescura;
- permitir drill-down cuando existan datos subyacentes consultables.

### 9.4 Actividad

La actividad visible deberá utilizar lenguaje comprensible para el usuario.

No se mostrarán por defecto nombres de eventos técnicos, stack traces ni detalles de infraestructura.

### 9.5 Interacciones

Las vistas de interacción deberán permitir pasar de un resumen a suficiente detalle para comprender qué ocurrió.

### 9.6 Incidencias

La vista cliente deberá mostrar únicamente información pública de una incidencia.

Las notas técnicas internas deberán permanecer separadas.

### 9.7 Documentación

Los documentos deberán visualizarse como contenido web legible, aunque su formato subyacente sea compatible con Markdown.

### 9.8 Móvil

La experiencia móvil deberá priorizar:

- estado general;
- KPIs;
- actividad reciente;
- incidencias;
- notificaciones;
- revisión de interacciones;
- feedback;
- aprobación, edición o rechazo de acciones supervisadas;
- tareas;
- consulta de documentación.

CRM completo, configuración avanzada, gestión extensa de permisos y administración compleja podrán estar orientados a escritorio.

---

## 10. Acceptance criteria

**AC-001** Una cuenta con tres organizaciones permite que un usuario de cuenta acceda a las tres mientras un usuario de organización accede únicamente a la organización asignada.

**AC-002** Una organización puede tener dos instancias del mismo tipo de servicio y mantener actividad, métricas y configuración separadas.

**AC-003** Un usuario Comercial sin excepciones no puede acceder al contenido de emails, chats o transcripciones de clientes.

**AC-004** Un Técnico asignado a una única cuenta no puede consultar información operativa de otra cuenta.

**AC-005** Un usuario interno no puede autenticarse sin completar MFA.

**AC-006** Una organización que active MFA obligatorio impide el acceso de sus usuarios hasta completar MFA.

**AC-007** Una acción realizada durante impersonación registra al empleado interno como actor real.

**AC-008** Un Email Assistant permite consultar email entrante, decisión del agente, respuesta generada y respuesta enviada cuando existan.

**AC-009** Una conversación de chatbot permite evaluar tanto la conversación completa como una respuesta concreta.

**AC-010** Una llamada permite evaluar globalmente la llamada y un segmento identificable de la transcripción.

**AC-011** Una evaluación incorrecta permite registrar una corrección y un comentario.

**AC-012** Un feedback puede convertirse en una tarea y conservar referencia a su origen.

**AC-013** Una acción supervisada puede ser editada, aprobada o rechazada cuando el usuario tenga las capacidades correspondientes.

**AC-014** Una acción supervisada vencida no se ejecuta automáticamente.

**AC-015** El dashboard distingue entre éxito técnico, resultado operativo y evaluación humana cuando las tres dimensiones estén disponibles.

**AC-016** Si 100 de 1.000 interacciones han sido evaluadas y 90 son satisfactorias, la interfaz muestra 90 % de satisfacción y 10 % de cobertura, sin clasificar las 900 restantes.

**AC-017** Al seleccionar una métrica con drill-down, el histórico se abre con los filtros que explican la cifra seleccionada.

**AC-018** Si una integración deja de proporcionar datos por encima de su umbral configurado, el portal indica que la información puede estar desactualizada.

**AC-019** Un documento publicado y todavía no sincronizado muestra estados diferentes para publicación y sincronización.

**AC-020** Un documento heredado puede ser sustituido explícitamente por otro documento en un nivel inferior.

**AC-021** Restaurar una versión documental anterior no elimina el historial de versiones existentes.

**AC-022** Un fallo persistente de sincronización puede producir una incidencia visible para el equipo interno.

**AC-023** Una incidencia contiene información interna separada de la información visible al cliente.

**AC-024** Una solicitud de eliminación de cliente no elimina inmediatamente el contenido sin pasar por el workflow configurado.

**AC-025** Un evento duplicado con identificador inequívoco no incrementa dos veces las métricas asociadas.

**AC-026** Un evento inválido rechazado no modifica las métricas normales.

**AC-027** Un evento incompleto utilizable puede registrarse sin presentar los campos ausentes como valores reales.

**AC-028** Al marcar una oportunidad como ganada se inicia el proceso de conversión asistida y el portal no se activa hasta completar las decisiones requeridas por ese flujo.

**AC-029** Un servicio puede programarse para finalizar en una fecha futura sin dejar de operar antes de esa fecha.

**AC-030** Tras finalizar un servicio, la visibilidad histórica del cliente depende de la configuración elegida para ese servicio.

**AC-031** Un usuario puede configurar preferencias de email para categorías configurables sin poder desactivar las categorías definidas como obligatorias.

**AC-032** Un usuario solo puede exportar datos que ya tiene permiso para consultar dentro del portal.

**AC-033** Desde móvil un usuario autorizado puede consultar estado, actividad, incidencias y ejecutar acciones rápidas soportadas.

**AC-034** Los dashboards de una instancia pueden sobrescribir la configuración de widgets definida por su tipo de servicio.

**AC-035** Un usuario cliente no puede modificar libremente el layout de widgets del dashboard en el MVP.

---

## 11. Explicitly out of scope

Queda explícitamente fuera del MVP:

- constructor visual de tipos de servicio;
- constructor de agentes;
- edición de prompts;
- configuración de modelos LLM;
- edición de workflows n8n;
- SSO empresarial;
- API pública para clientes;
- white-label;
- registro público;
- autoprovisionamiento público;
- facturación;
- pagos;
- suscripciones;
- presupuestos;
- facturas;
- marketing automation;
- campañas;
- newsletters;
- lead scoring avanzado;
- secuencias comerciales;
- forecasting comercial avanzado;
- BI avanzado;
- constructor de dashboards para clientes;
- gestor de proyectos completo;
- subtareas y dependencias complejas;
- Gantt;
- sprints;
- motor avanzado de reglas de alertas;
- edición documental colaborativa equivalente a Google Docs;
- reproducción de audio de llamadas;
- análisis emocional;
- análisis IA adicional no definido;
- exportación integral de toda una cuenta;
- SLA contractual;
- canal alternativo de aprobación cuando el portal está caído;
- modificación automática del comportamiento de agentes a partir de feedback;
- sincronización directa del conocimiento por parte del propio portal con cada agente.

---

## 12. Constraints

1. El MVP se utilizará inicialmente por el equipo interno y clientes reales, no se lanzará como SaaS público.
2. Los tipos de servicio se desarrollarán explícitamente.
3. Las instancias de esos tipos sí podrán ser configurables.
4. La API será privada y utilizada por integraciones administradas por el equipo técnico.
5. Los servicios pueden ejecutarse completamente fuera de la plataforma.
6. La latencia total de extremo a extremo depende también de sistemas externos.
7. La plataforma no garantiza que un servicio externo haya ejecutado una acción hasta recibir confirmación adecuada.
8. Los datos operativos pueden contener información sensible.
9. El MVP acepta un RTO de hasta 24 horas.
10. Durante una caída del portal, las acciones supervisadas pueden quedar bloqueadas hasta la recuperación.
11. El CRM forma parte del producto, pero no debe expandirse hacia un CRM de marketing generalista dentro del MVP.

---

## 13. Risks

### RISK-001: Scope excesivo

El MVP combina portal cliente, observabilidad, colaboración, documentación, permisos, CRM e integraciones.

Mitigación de producto:

Dividir la implementación en entregas internas aunque exista un único PRD rector.

### RISK-002: CRM creciendo hasta convertirse en un producto independiente

El CRM puede absorber desarrollo en funcionalidades no relacionadas con el objetivo principal.

Mitigación:

Mantener fuera del MVP marketing automation, campañas, forecasting avanzado y funcionalidades equivalentes.

### RISK-003: Complejidad del modelo de permisos

Roles, herencia, excepciones, organizaciones y servicios pueden generar una matriz difícil de administrar.

Mitigación:

Mantener roles funcionales predefinidos como modelo principal y utilizar excepciones solo cuando sea necesario.

### RISK-004: Dependencia de integraciones externas

La plataforma puede funcionar correctamente mientras recibe información incompleta o tardía.

Mitigación:

Mostrar frescura, estado de sincronización y advertencias explícitas.

### RISK-005: Métricas engañosas

Mezclar dimensiones distintas podría producir conclusiones incorrectas.

Mitigación:

Separar estado técnico, resultado operativo y evaluación humana.

### RISK-006: Sesgo por baja cobertura de evaluación

Una tasa de satisfacción calculada sobre pocas evaluaciones puede interpretarse como representativa.

Mitigación:

Mostrar siempre satisfacción junto con cobertura.

### RISK-007: Portal dentro del camino crítico

Las acciones supervisadas dependen de la disponibilidad del portal.

Mitigación aceptada para el MVP:

Las acciones pueden permanecer bloqueadas durante una indisponibilidad de hasta el RTO definido.

### RISK-008: Impersonación con privilegios elevados

Los usuarios internos autorizados pueden actuar con las mismas capacidades que el usuario cliente.

Mitigación:

Registrar actor real y todas las acciones realizadas durante impersonación.

### RISK-009: Información sensible

Emails, chats y transcripciones pueden contener información sensible.

Mitigación:

Aislamiento por cuenta/organización, control de acceso, MFA, auditoría y políticas de retención.

### RISK-010: Crecimiento heterogéneo de servicios

Los futuros servicios pueden no compartir los conceptos específicos de los tres servicios iniciales.

Mitigación:

Mantener el modelo base centrado en servicio e instancia, no en agente IA.

---

## 14. Open decisions

Las siguientes decisiones no deben inventarse durante desarrollo sin ser revisadas:

### OD-001 Estados contractuales exactos

Definir la lista final y sus transiciones.

### OD-002 Estados operativos exactos

Definir la lista final y sus transiciones.

### OD-003 Estados de salud exactos

Definir nombres, significado y precedencia.

### OD-004 Política de retención por defecto

Definir periodos concretos para interacciones, transcripciones, auditoría, documentación y otros datos.

### OD-005 Reintentos de sincronización

Definir número de intentos, intervalos y condiciones de fallo persistente.

### OD-006 Umbrales de frescura

Definir valores por defecto para Email Assistant, Chatbot, Voice Assistant y futuros tipos.

### OD-007 Métricas específicas de cada servicio

Definir el catálogo exacto de KPIs y widgets para cada tipo inicial.

### OD-008 Permisos atómicos

Definir las capacidades concretas que componen cada rol y las operaciones que admiten excepciones.

### OD-009 Notificaciones obligatorias

Definir qué categorías no pueden ser desactivadas por el usuario.

### OD-010 Auditoría fuera de impersonación

Definir la lista exacta de cambios administrativos u operativos que deben registrarse.

### OD-011 Campos específicos de servicio

Definir campos concretos adicionales de Email Assistant, Chatbot y Voice Assistant.

### OD-012 Nomenclatura de interfaz

Definir nombres finales para roles, estados, entidades y secciones de navegación.

### OD-013 KPIs de éxito del producto

Definir objetivos cuantitativos posteriores al lanzamiento para medir:

- adopción por clientes;
- uso del portal;
- capacidad de supervisión;
- reducción de fricción operativa;
- utilidad de la transparencia ofrecida.

### OD-014 Tratamiento concreto del contenido eliminado

Definir cuándo se realiza eliminación física, anonimización u otra operación según la política aplicable.

### OD-015 Política exacta de activación del portal

Definir qué pasos del flujo asistido son obligatorios antes de considerar una cuenta activada.

---

## 15. Glossary

### Account / Cuenta

Entidad comercial que representa una relación cliente y puede contener varias organizaciones.

### Organization / Organización

Entidad operativa perteneciente a una cuenta y utilizada para agrupar usuarios, servicios e información.

### Service Type / Tipo de servicio

Clase de servicio desarrollada explícitamente por el proveedor.

Ejemplos iniciales:

- Email Assistant;
- Chatbot;
- Voice Assistant.

### Service Instance / Instancia de servicio

Implementación concreta de un tipo de servicio para una organización.

Ejemplo:

`Email Assistant / Soporte`

### Interaction / Interacción

Unidad funcional relevante de un servicio.

Ejemplos:

- email;
- conversación;
- llamada.

### Event / Evento

Registro granular emitido o recibido por una integración.

No todos los eventos son visibles directamente para el cliente.

### Activity / Actividad

Representación comprensible para humanos de uno o varios eventos operativos.

### Technical status / Estado técnico

Indica si una acción fue procesada técnicamente de forma correcta.

### Operational result / Resultado operativo

Indica si una acción consiguió el objetivo funcional definido para el servicio.

### Human evaluation / Evaluación humana

Valoración realizada por un usuario sobre la calidad o corrección de una interacción.

### Evaluation coverage / Cobertura de evaluación

Proporción de interacciones evaluadas respecto al total de interacciones elegibles.

### Feedback

Evaluación estructurada de una interacción o parte de ella.

Puede incluir:

- correcto/incorrecto;
- corrección;
- comentario.

### Task / Tarea

Unidad básica de trabajo pendiente.

### Incident / Incidencia

Problema operativo identificado manual o automáticamente.

### Documentation / Documentación

Contenido destinado principalmente a usuarios humanos.

### Knowledge / Conocimiento

Contenido publicado destinado a ser utilizado por un servicio externo.

### Published

Estado editorial que indica que una versión documental ha sido aprobada.

### Synchronized

Estado que indica que un sistema externo ha confirmado la incorporación del contenido publicado.

### Supervised mode / Modo supervisado

Modo en el que una acción necesita intervención humana antes de continuar.

### Autonomous mode / Modo autónomo

Modo en el que una acción puede continuar sin aprobación humana previa.

### Impersonation / Impersonación

Sesión en la que un usuario interno autorizado actúa utilizando las capacidades de un usuario cliente, manteniendo registrado al actor real.

### Data freshness / Frescura de datos

Indicador de cuánto tiempo ha transcurrido desde que la plataforma recibió información relevante de una integración.

### RPO

Recovery Point Objective.

Pérdida máxima de datos aceptada tras una recuperación.

Objetivo MVP: aproximadamente 1 hora.

### RTO

Recovery Time Objective.

Tiempo máximo aceptado para recuperar la plataforma tras un fallo grave.

Objetivo MVP: hasta 24 horas.