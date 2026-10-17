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
3. **Unificación Geográfica (Bogotá vs. Cali):** El prototipo utilizaba datos de prueba en ambas ciudades. La arquitectura formal define soporte para **ciudades principales de Colombia** (ver sección 4.4).
4. **Umbral de Validación Comunitaria:** La meta formal es **10 apoyos (upvotes)** según RN-08 y RN-10 (el prototipo mostraba textos variables como "Meta: 60" o "40+ firmas" por fines ilustrativos).
5. **Formulario del Wizard:** En la implementación del wizard se incluyen los campos exigidos por el modelo relacional: título, descripción, tipo y severidad (*Baja, Media, Alta, Crítica*).
6. **Escala de Gamificación en Dashboard:** Rige la escala formal de RN-09: Nivel 1 (0-999 XP), Nivel 2 (1,000-2,499 XP), Nivel 3 (2,500-3,999 XP), Nivel 4 (4,000+ XP).
7. **Catálogo de Insignias:** Rigen las 5 insignias maestras del catálogo (`PRIMER_PASO_CIVICO`, `VOZ_ACTIVA`, `CAZADOR_DE_BACHES`, `REPORTE_DE_ALTO_IMPACTO`, `GUARDIAN_COMUNITARIO`).
8. **Métricas del Dashboard:** Se implementan las 4 métricas calculables del modelo: *Reportes Creados*, *Upvotes Recibidos*, *Upvotes Otorgados* y *Comentarios Realizados*.
9. **Roles en Feed y Comentarios:** El sistema opera bajo el rol de **Ciudadano** (con niveles honoríficos de gamificación). Textos de "veedores" en UI corresponden a "apoyos" o "ciudadanos respaldando".

---

## 4.3. Decisiones sobre Autenticación, Onboarding y Notificaciones

### A. Autenticación Básica Local y Onboarding Basado en Permisos
* **Enfoque Actual (100% Login Local):** 
  - La implementación se centra exclusivamente en **autenticación nativa (Correo electrónico + Contraseña hasheada + Nombre completo)**.
  - Esto garantiza el cumplimiento estricto y verificable del enunciado académico, permite generar usuarios de prueba controlados para evaluación y elimina problemas de dependencias externas.
* **Compatibilidad Futura con Login Social (Google / Apple):**
  - La base de datos deja habilitada la columna `proveedor_auth VARCHAR(30) NOT NULL DEFAULT 'LOCAL'` (valores admitidos: `'LOCAL'`, `'GOOGLE'`, `'APPLE'`) y `hash_contrasena NULL` en la tabla `usuario`.
  - Esto permite que en el futuro la adición de botones de login social sea puramente una extensión visual/cliente sin requerir migraciones estructurales de base de datos.
* **Onboarding Mínimo Necesario y Permisos de Ubicación (GPS en tiempo de uso):**
  - **No se exige escribir barrio ni comuna de residencia en el registro:** Forzar campos de texto o dropdowns de miles de barrios introduce fricción innecesaria y limita al usuario (alguien puede reportar baches camino al trabajo o a la universidad fuera de su barrio residencial).
  - **Ubicación bajo permiso en tiempo de ejecución ("When in use"):** Al abrir la app por primera vez, se solicita el permiso estándar del sistema operativo para acceder a la ubicación mientras la app esté abierta.
* **Plan de Mitigación ante Permiso de Ubicación Denegado:**
  - **Principio clave:** *Bajo ninguna circunstancia se bloquea la aplicación si el usuario rechaza compartir su ubicación*.
  - **Estrategia en 3 Niveles:**
    1. *Nivel 1 (Permiso Concedido):* El mapa y el feed se centran automáticamente en las coordenadas GPS en vivo del dispositivo móvil.
    2. *Nivel 2 (Permiso Denegado / Sin GPS en emulador):* La aplicación muestra un banner informativo no invasivo (*"Ubicación desactivada: explorando ciudad predeterminada"*) y centra el mapa en las coordenadas de la ciudad de referencia (`ciudad_preferida` en perfil o un selector de ciudad rápida en el header: *Cali | Bogotá | Medellín | Barranquilla*).
    3. *Nivel 3 (Creación de Reportes sin GPS):* En el Paso 1 del Wizard, el usuario puede mover manualmente el pin en el mapa o buscar la dirección aproximada mediante una barra de búsqueda de texto georreferenciada.
* **Flujo Post-Autenticación:**
  - Tras registrarse o iniciar sesión, el usuario es redirigido directamente a la **Pantalla de Resumen de Perfil (Dashboard Cívico)** cumpliendo el enunciado, donde visualiza su avatar, nivel cívico inicial (*Observador Urbano*), XP y estadísticas personales.

### B. Módulo de Notificaciones: Persistencia Relacional y Criterios Push
* **Aclaración sobre Servicios Push (Firebase / FCM):**
  - El uso de FCM no es obligatorio ni un requisito del proyecto. Fue citado como el estándar de transporte de la industria, pero **la arquitectura central de VIGÍA se apoya en una tabla relacional interna (`notificacion`) en PostgreSQL**.
* **¿Por qué la tabla `notificacion` es la solución adecuada?**
  - VIGÍA es una plataforma asíncrona: un bache publicado hoy puede recibir apoyos, fotos de seguimiento o soluciones días después.
  - La tabla `notificacion` alimenta el **Centro de Alertas / Campanita** de la app con estado `leida = FALSE / TRUE`.
* **Criterio de Notificaciones (Push vs. In-App Exclusivas):**
  - **Notificaciones Prioritarias / Accionables (Candidatas a Push en dispositivo):**
    1. *Validación Comunitaria:* "¡Tu reporte alcanzó 10 apoyos y fue validado por la comunidad! (+500 XP)".
    2. *Propuesta de Cierre / Solución:* "Un ciudadano aportó evidencia fotográfica de reparación en tu reporte. Toca para verificar."
  - **Notificaciones In-App Exclusivas (Baja prioridad / Silenciosas en campanita):**
    1. *Nuevos apoyos individuales (+1 upvote):* Se acumulan en el contador sin interrumpir al usuario.
    2. *Nuevos comentarios de debate vecinal en reportes seguidos.*
    3. *Hitos de Gamificación (Subida de rango / Insignia):* Se presentan mediante un modal / banner de celebración dentro de la app en la sesión activa.
* **Hoja de Ruta de Implementación:**
  - **Fase de Arquitectura (Actual):** Modelo relacional definido con tabla `notificacion` y tipos estructurados.
  - **Fase de Funcionalidad (Sprint de Notificaciones):** Lógica del backend para insertar registros ante eventos y vista de la bandeja en el cliente móvil.
  - **Integración Push Externa:** Funcionalidad complementaria opcional a evaluar al final del desarrollo.

---

## 4.4. Decisiones de Modelo de Datos y Mejoras Resueltas

### A. Mecanismo y Diseño de Cierre de Reportes (`RESUELTO`)
* **Diferenciación entre Comentario Normal y Propuesta de Resolución:**
  - Para evitar que una propuesta de reparación se confunda con un comentario de opinión, la UI del Detalle del Reporte incluye un botón específico: **"Reportar como Reparado / Resuelto"**.
  - Este botón despliega un **Modal de Resolución Cívica** que exige obligatoriamente:
    1. Una (1) fotografía reciente de la vía reparada/pavimentada (almacenada en `foto_comentario`).
    2. Un comentario descriptivo de la intervención realizada.
  - En la base de datos, el registro en la tabla `comentario` se clasifica con `tipo_comentario = 'PROPUESTA_RESOLUCION'`.
* **Renderizado Visual en el Hilo de Discusión:**
  - Las propuestas de resolución se muestran con una tarjeta destacada (borde verde, insignia *"Propuesta de Solución"* y foto de la obra).
* **Flujo de Aprobación Cruzada:**
  1. *Si el autor original propone la resolución:* El reporte pasa automáticamente a estado `RESUELTO`.
  2. *Si un vecino (ciudadano no autor) propone la resolución:*
     - El autor del reporte recibe una notificación prioritaria con los botones **[Aceptar Solución]** o **[Rechazar]**.
     - **Salvaguarda comunitaria (Autor ausente):** Si el autor no responde, o si otros ciudadanos respaldan la solución, cada apoyo suma al campo `votos_confirmacion` de ese comentario. Al alcanzar **3 votos de confirmación**, el sistema actualiza automáticamente el reporte a `RESUELTO`.
  3. *Recompensa cívica:* Se otorgan **+50 XP** al usuario que propuso la solución verificada.

### B. Alcance Geográfico: Criterio Urbano Nacional (DANE)
* **Descarte de "Piloto Exclusivo en Cali":**
  - Dado que la aplicación es un prototipo funcional/académico, restringirla rígidamente a Cali limitaría las pruebas y la escalabilidad del proyecto.
* **Criterio Formal de Inclusión Geográfica:**
  - VIGÍA cubre las **ciudades urbanas principales de Colombia**, delimitadas por el estándar demográfico del **DANE**:
    1. **Las 32 Capitales de Departamento** (Cali, Bogotá, Medellín, Barranquilla, Bucaramanga, Cartagena, Manizales, Pereira, Pasto, etc.).
    2. **Municipios y Ciudades No Capitales con Población Urbana > 100.000 habitantes** o pertenecientes a áreas metropolitanas consolidadas:
       - Valle del Cauca: Palmira, Tuluá, Buenaventura, Cartago, Jamundí.
       - Antioquia: Bello, Itagüí, Envigado, Rionegro.
       - Atlántico: Soledad, Malambo.
       - Santander: Floridablanca, Girón, Piedecuesta, Barrancabermeja.
       - Cundinamarca: Soacha, Chía, Zipaquirá.
* **Delimitación y Exclusiones:**
  - Se excluyen expresamente autopistas nacionales interdepartamentales (concesiones ANI) y vías terciarias rurales (trochas sin nomenclatura ni barrios).
  - Coordenadas geográficas validadas dentro del Bounding Box continental de Colombia (Latitud: -4.2° a 13.5°, Longitud: -79.0° a -66.8°).

### C. Integridad de Evidencia Fotográfica Principal
* Se implementa un **índice único parcial** en PostgreSQL:
  ```sql
  CREATE UNIQUE INDEX idx_foto_principal_unica 
  ON foto_reporte (id_reporte) 
  WHERE es_principal = TRUE;
  ```
  Esto garantiza a nivel de base de datos que jamás existan dos fotografías marcadas simultáneamente como principales para el mismo reporte.
