# Documento 4: Resoluciones de Arquitectura, Pendientes y Decisiones de Diseño

Estado al 17 de octubre de 2026 (Rama `develop`).  
Este documento consolida las decisiones arquitectónicas, de producto y de modelo de datos acordadas por el equipo, sirviendo como **fuente única de verdad** técnica ante discrepancias con los mockups del prototipo exploratorio.

---

## 4.1. Decisión Principal: Alcance de VIGÍA (100% Ciudadana)
- **Decisión adoptada: Opción A (Solo Ciudadana / Auditoría Cívica Abierta).**
- **Justificación y Rationale:**
  - VIGÍA nace como una plataforma cívica de empoderamiento ciudadano pacífico, no como un sistema de ventanilla única ni de gestión de trámites gubernamentales (PQRSD).
  - Incluir interacción directa con entidades oficiales exigiría integraciones con APIs estatales inexistentes, dependencias burocráticas y convenios institucionales que escapan al alcance de una aplicación móvil universitaria y a su filosofía de veeduría independiente.
  - El sistema centra su valor en la geolocalización de daños, el respaldo colectivo (*upvotes*), la discusión comunitaria y la visibilización cívica con métricas de impacto verificables.

---

## 4.2. Criterio de Coexistencia con el Prototipo Visual
El prototipo en Stitch / Figma es un **artefacto conceptual de diseño exploratorio**. Para optimizar los tiempos de desarrollo y priorizar el código funcional, **no es necesario rediseñar las pantallas gráficas**; la documentación técnica ([01-planteamiento](file:///c:/Universidad/Noveno%20Semestre/App%20Moviles/Proyecto%20Final%20-%20Vigia/docs/01-planteamiento-problema-solucion-actores.md), [02-arquitectura](file:///c:/Universidad/Noveno%20Semestre/App%20Moviles/Proyecto%20Final%20-%20Vigia/docs/02-arquitectura-pantallas-flujos.md), [03-reglas-de-negocio](file:///c:/Universidad/Noveno%20Semestre/App%20Moviles/Proyecto%20Final%20-%20Vigia/docs/03-reglas-de-negocio.md) y [schema.sql](file:///c:/Universidad/Noveno%20Semestre/App%20Moviles/Proyecto%20Final%20-%20Vigia/data%20model/schema.sql)) rige la implementación formal:

1. **Trazabilidad del Trámite en Detalle:** Los textos de "Oficio a Secretaría", "Radicado legal `#RAD-INF-99120`" y "Plazo legal 72h" del prototipo se interpretan e implementan como **Radicado Cívico Comunitario** (ej. `#VIG-8492`), fecha de reporte y estado de validación ciudadana.
2. **Entidades Oficiales (Alcaldía / IDU) y estado "En obra":** Se sustituyen funcionalmente por los estados del modelo: `REPORTADO`, `EN_REVISION`, `VALIDADO_COMUNIDAD` y `RESUELTO`.
3. **Unificación Geográfica (Bogotá vs. Cali):** El prototipo utilizaba datos de prueba en ambas ciudades. La arquitectura formal define soporte para el **catálogo nacional de ciudades principales de Colombia** (ver sección 4.4.B).
4. **Umbral de Validación Comunitaria:** La meta formal es **10 apoyos (upvotes)** según RN-08 y RN-10 (el prototipo mostraba textos variables como "Meta: 60" o "40+ firmas" por fines ilustrativos).
5. **Formulario del Wizard:** En la implementación del wizard se incluyen los campos exigidos por el modelo relacional: título, descripción, tipo y severidad (*Baja, Media, Alta, Crítica*).
6. **Escala de Gamificación en Dashboard:** Rige la escala formal de RN-09: Nivel 1 (0-999 XP), Nivel 2 (1,000-2,499 XP), Nivel 3 (2,500-3,999 XP), Nivel 4 (4,000+ XP).
7. **Catálogo de Insignias:** Rigen las 5 insignias maestras del catálogo (`PRIMER_PASO_CIVICO`, `VOZ_ACTIVA`, `CAZADOR_DE_BACHES`, `REPORTE_DE_ALTO_IMPACTO`, `GUARDIAN_COMUNITARIO`).
8. **Métricas del Dashboard:** Se implementan las 4 métricas calculables del modelo: *Reportes Creados*, *Upvotes Recibidos*, *Upvotes Otorgados* y *Comentarios Realizados*.
9. **Roles en Feed y Comentarios:** El sistema opera bajo el rol de **Ciudadano** (con niveles honoríficos de gamificación). Textos de "veedores" en UI corresponden a "apoyos" o "ciudadanos respaldando".

---

## 4.3. Decisiones sobre Autenticación, Onboarding y Notificaciones

### A. Autenticación Básica Local y Flujo de Ubicación / Mitigación
* **Enfoque Actual (100% Login Local):** 
  - La implementación se centra exclusivamente en **autenticación nativa (Correo electrónico + Contraseña hasheada + Nombre completo)**.
  - Esto garantiza el cumplimiento estricto y verificable del enunciado académico, permite generar usuarios de prueba controlados para evaluación y elimina problemas de dependencias externas.
* **Compatibilidad Futura con Login Social (Google / Apple):**
  - La base de datos deja habilitada la columna `proveedor_auth VARCHAR(30) NOT NULL DEFAULT 'LOCAL'` (valores admitidos: `'LOCAL'`, `'GOOGLE'`, `'APPLE'`) y `hash_contrasena NULL` en la tabla `usuario`.
  - Esto permite que en el futuro la adición de botones de login social sea puramente una extensión visual/cliente sin requerir migraciones estructurales de base de datos.
* **Toma de Datos en Registro (Onboarding Mínimo):**
  - Se solicitan únicamente: Nombre completo, Correo electrónico, Contraseña y un **selector de ciudad de referencia** (`ciudad_referencia`, ej. Cali, Bogotá, Medellín).
  - **No se pide barrio ni comuna en el registro:** evita fricción innecesaria y no restringe al usuario a reportar solo en su zona residencial.
* **Permiso de Ubicación en Tiempo de Uso ("When in use"):**
  - Al abrir la app por primera vez, el sistema operativo solicita el permiso para acceder al GPS del dispositivo mientras la app esté abierta.
* **Planes de Mitigación ante Rechazo de Ubicación y Zonas sin Cobertura:**
  - **Principio clave:** *Bajo ninguna circunstancia se bloquea la aplicación si el usuario rechaza compartir su ubicación*.
  1. *Permiso Denegado:* 
     - La app muestra un banner superior no invasivo: *"Ubicación desactivada: explorando ciudad predeterminada"*.
     - Incluye un botón interactivo: **"Activar ubicación"**, el cual vuelve a solicitar el permiso o abre directamente los ajustes del sistema operativo (`openAppSettings()`) si fue rechazado permanentemente.
     - Sitúa el mapa en la última ciudad conocida del usuario (`usuario.ultima_ciudad`, por defecto su `ciudad_referencia`).
  2. *Búsqueda por Ciudades (Disponible para todos los usuarios):*
     - En el header del mapa existe una barra/selector de ciudades del catálogo oficial.
     - **Usuario sin GPS:** Si busca otra ciudad (ej. Bogotá estando en Cali), el mapa se desplaza al centro de Bogotá y se actualiza `usuario.ultima_ciudad = 'Bogotá'`. La próxima vez que abra la app sin GPS, arrancará directamente en Bogotá.
     - **Usuario con GPS activo:** La búsqueda de otra ciudad es una navegación exploratoria temporal; contará con un botón flotante estándar: *"Centrar en mi ubicación"* para volver a su posición física en cualquier momento.
  3. *Apertura de App con GPS en zona rural / pueblo sin cobertura:*
     - Si el GPS ubica al usuario en una coordenada fuera del catálogo de ciudades urbanas, la app **no salta a pueblos desconocidos ni intenta adivinar**: mantiene en el mapa su **última ciudad urbana registrada** (`usuario.ultima_ciudad`), desplegando un aviso sutil: *"Te encuentras fuera del perímetro urbano cubierto por VIGÍA. Mostrando tu última ciudad activa"*.
  4. *Creación de Reportes sin GPS:* En el Paso 1 del Wizard, el usuario puede mover manualmente el pin en el mapa o buscar una dirección aproximada por texto.

---

### B. Módulo de Notificaciones: Matriz Formal de Eventos
* **Momento de Definición:** Se define y documenta **en esta fase de arquitectura** para que todos los módulos futuros (votos, comentarios, resolución) sepan exactamente qué evento disparar y a quién. La programación de la vista de campana se desarrollará en el sprint correspondiente.
* **Arquitectura:** Se fundamenta en la tabla relacional `notificacion` en PostgreSQL (In-App), con categorización clara entre alertas prioritarias (Push) y silenciosas (In-App).

#### Matriz Oficial de Notificaciones y Eventos del Sistema

| Código de Tipo | Evento Disparador (Trigger) | Destinatario | Canal | Título de la Notificación | Contenido / Plantilla del Mensaje |
| :--- | :--- | :--- | :--- | :--- | :--- |
| `VALIDACION_COMUNITARIA` | Reporte alcanza los 10 apoyos (*upvotes*) | Autor del reporte | **Push + In-App** | ¡Reporte Validado por la Comunidad! | Tu reporte "#{titulo}" en {barrio} ha alcanzado 10 apoyos comunitarios. ¡Has ganado +500 XP! |
| `PROPUESTA_RESOLUCION` | Un vecino publica propuesta de cierre con foto | Autor del reporte | **Push + In-App** | Propuesta de Solución Recibida | Un ciudadano aportó evidencia fotográfica de reparación en tu reporte "#{titulo}". Toca para verificar. |
| `REPORTE_RESUELTO` | Reporte pasa formalmente a estado `RESUELTO` | Autor y usuarios en `seguimiento_reporte` | **Push + In-App** | ¡Incidente Vial Solucionado! | El reporte #{radicado} en {barrio} ha sido verificado como reparado. |
| `NUEVO_COMENTARIO` | Nuevo comentario publicado en hilo | Autor y seguidores | **In-App (Silencioso)** | Nuevo comentario en reporte | {nombre_usuario} comentó en el reporte #{radicado}. |
| `NUEVO_APOYO` | Reporte recibe un nuevo upvote individual | Autor del reporte | **In-App (Silencioso)** | Nuevo apoyo recibido | Un vecino apoyó tu reporte en {barrio} (+10 XP). |
| `SUBIDA_RANGO` | Usuario supera umbral de XP de un nuevo nivel | Usuario activo | **In-App (Modal/Banner)** | ¡Ascenso de Rango Cívico! | ¡Felicitaciones! Has ascendido al rango de {nombre_rango}. |
| `NUEVA_INSIGNIA` | Usuario cumple condiciones de medalla cívica | Usuario activo | **In-App (Modal/Banner)** | ¡Nueva Insignia Desbloqueada! | Has obtenido la insignia "{nombre_insignia}". |

---

## 4.4. Decisiones de Modelo de Datos y Mejoras Resueltas

### A. Mecanismo de Cierre y Nueva Tabla `resolucion_reporte`
* **Criterio de Modelado (Por qué se separó de `comentario`):**
  - **Principio de Responsabilidad Única (SRP):** Un comentario es un mensaje conversacional libre. Una propuesta de resolución es una entidad transaccional del ciclo de vida del reporte, sujeta a auditoría, estados y quórum de votos.
  - **Evitar Anti-patrón de Columnas Nulas:** Incluir campos de cierre en `comentario` dejaría el 99% de las filas de comentarios con datos nulos.
  - **Prevención de Votos Duplicados:** Se crea la tabla relacional `confirmacion_resolucion (id_usuario, id_resolucion)` para garantizar que ningún vecino vote más de una vez por la misma propuesta.
* **Estructura Implementada:**
  - Tabla `resolucion_reporte`: vinculada a `reporte` y al usuario proponente, con `url_foto_evidencia`, `descripcion`, `estado` (`PENDIENTE`, `APROBADA_AUTOR`, `APROBADA_COMUNIDAD`, `RECHAZADA`), `votos_confirmacion` y motivo de rechazo.
  - Tabla `confirmacion_resolucion`: llave primaria compuesta `(id_usuario, id_resolucion)` para trazabilidad de quórum vecinal.
* **Experiencia en Frontend (UI):**
  - En la vista de detalle del reporte, la propuesta activa se renderiza como una **tarjeta especial fijada (*pinned card*)** al inicio del hilo de discusión con marco verde, foto de la reparación, y botones dinámicos:
    - Para el Autor: **[Aceptar Solución]** / **[Rechazar]**.
    - Para otros Ciudadanos: **[Confirmar Arreglo (+1)]**.
  - Si el autor aprueba, o si la propuesta alcanza **3 votos de confirmación comunitaria**, el reporte pasa automáticamente a `RESUELTO`.
  - Recompensa: **+50 XP** al proponente de la solución verificada.

---

### B. Catálogo Oficial de Cobertura Urbana DANE y Tabla `ciudad_cobertura`
* **Definición Inmediata del Catálogo:**  
  Se crea la tabla maestra `ciudad_cobertura` con coordenadas de centroide urbano (`latitud_centro`, `longitud_centro`) y bandera `es_capital`.
* **Criterio Demográfico DANE Oficial:**
  1. **Las 32 Capitales de Departamento:**
     - Cali, Bogotá, Medellín, Barranquilla, Cartagena, Bucaramanga, Cúcuta, Pereira, Santa Marta, Ibagué, Pasto, Manizales, Neiva, Villavicencio, Armenia, Valledupar, Montería, Sincelejo, Popayán, Tunja, Riohacha, Florencia, Quibdó, Yopal, San Andrés, Mocoa, Arauca, San José del Guaviare, Leticia, Inírida, Mitú, Puerto Carreño.
  2. **Ciudades y Municipios No Capitales con Población Urbana > 100.000 habitantes o Áreas Metropolitanas:**
     - *Valle del Cauca:* Palmira, Buenaventura, Tuluá, Cartago, Jamundí, Yumbo.
     - *Antioquia:* Bello, Itagüí, Envigado, Rionegro.
     - *Atlántico:* Soledad.
     - *Santander:* Floridablanca, Barrancabermeja.
     - *Cundinamarca:* Soacha, Chía, Zipaquirá, Facatativá.
     - *Boyacá:* Duitama, Sogamoso.
* **Exclusión Explícita:** Se excluyen autopistas interdepartamentales (concesiones ANI) y vías terciarias rurales (trochas sin nomenclatura ni barrios). Coordenadas delimitadas al Bounding Box de Colombia continental (Latitud: -4.2° a 13.5°, Longitud: -79.0° a -66.8°).

---

### C. Integridad de Evidencia Fotográfica Principal
* Se implementa un **índice único parcial** en PostgreSQL:
  ```sql
  CREATE UNIQUE INDEX idx_foto_principal_unica 
  ON foto_reporte (id_reporte) 
  WHERE es_principal = TRUE;
  ```
  Esto garantiza a nivel de base de datos que jamás existan dos fotografías marcadas simultáneamente como principales para el mismo reporte.
