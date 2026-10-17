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
3. **Unificación Geográfica (Bogotá vs. Cali):** El prototipo utilizaba datos de prueba en ambas ciudades. La arquitectura formal define soporte para **ciudades principales de Colombia con Cali como ciudad piloto** (ver sección 4.4).
4. **Umbral de Validación Comunitaria:** La meta formal es **10 apoyos (upvotes)** según RN-08 y RN-10 (el prototipo mostraba textos variables como "Meta: 60" o "40+ firmas" por fines ilustrativos).
5. **Formulario del Wizard:** En la implementación del wizard se incluyen los campos exigidos por el modelo relacional: título, descripción, tipo y severidad (*Baja, Media, Alta, Crítica*).
6. **Escala de Gamificación en Dashboard:** Rige la escala formal de RN-09: Nivel 1 (0-999 XP), Nivel 2 (1,000-2,499 XP), Nivel 3 (2,500-3,999 XP), Nivel 4 (4,000+ XP).
7. **Catálogo de Insignias:** Rigen las 5 insignias maestras del catálogo (`PRIMER_PASO_CIVICO`, `VOZ_ACTIVA`, `CAZADOR_DE_BACHES`, `REPORTE_DE_ALTO_IMPACTO`, `GUARDIAN_COMUNITARIO`).
8. **Métricas del Dashboard:** Se implementan las 4 métricas calculables del modelo: *Reportes Creados*, *Upvotes Recibidos*, *Upvotes Otorgados* y *Comentarios Realizados*.
9. **Roles en Feed y Comentarios:** El sistema opera bajo el rol de **Ciudadano** (con niveles honoríficos de gamificación). Textos de "veedores" en UI corresponden a "apoyos" o "ciudadanos respaldando".

---

## 4.3. Decisiones sobre Autenticación, Onboarding y Notificaciones

### A. Autenticación y Onboarding Mínimo
* **Prioridad Absoluta (Entrega Académica):** Autenticación nativa (Correo electrónico + Contraseña hasheada + Nombre completo). Esto garantiza el cumplimiento estricto del enunciado, facilita pruebas inmediatas en emuladores (sin lidiar con dependencias de Google Play Services o SHA-1 keystores) y asegura la calificación sin dependencias de terceros.
* **Onboarding Mínimo Necesario:** Al registrarse, además de las credenciales, el usuario selecciona su **Ciudad** y **Barrio de residencia / interés**. Esto ubica de inmediato su experiencia en el mapa y feed local.
* **Flujo Post-Autenticación:** Tras un registro o inicio de sesión exitoso, el usuario es redirigido a la **Pantalla de Resumen de Perfil (Dashboard Cívico)** donde visualiza su identidad cívica, XP inicial (0 XP o bonus de bienvenida), nivel y resumen de actividad.
* **Soporte para Social Login (Google / Apple):** Se deja el modelo de datos preparado incorporando en `usuario` el campo `proveedor_auth VARCHAR(30) NOT NULL DEFAULT 'LOCAL'` (valores admitidos: `'LOCAL'`, `'GOOGLE'`, `'APPLE'`). De este modo, la adición de botones de login social es puramente opcional en la capa de UI sin requerir alteraciones al backend ni a la base de datos.

### B. Módulo de Notificaciones: Persistencia Relacional
* **Decisión:** Implementación de la tabla relacional `notificacion` en PostgreSQL.
* **Justificación:**
  - VIGÍA es una plataforma asíncrona: los reportes reciben apoyos y comentarios horas o días después de su creación.
  - Confiar únicamente en notificaciones push del sistema operativo provocaría la pérdida irrecuperable de alertas si el usuario descarta la notificación en su móvil o si no tiene conexión al momento del envío.
  - Una tabla en BD alimenta el icono de campana (bandeja de notificaciones) en la app con control de lectura (`leida BOOLEAN`), permitiendo consultar:
    1. Notificaciones de apoyo ("Tu reporte alcanzó 10 votos y fue validado").
    2. Notificaciones de seguimiento ("Nuevo comentario con foto en un reporte que sigues").
    3. Hitos de gamificación ("¡Subiste a Nivel 3 - Guardián Vial!").
    4. Notificaciones de resolución ("Un vecino reportó que este daño fue solucionado").
  - Si en etapas posteriores se integra FCM (Firebase Cloud Messaging), el push solo será el canal de entrega hacia el dispositivo, mientras la tabla `notificacion` permanece como almacén central de estado.

### C. Rol de Moderación
* No se crea un actor "Moderador" con credenciales especiales para esta entrega. La moderación se apoya en:
  - Ventanas de tiempo estrictas de edición/eliminación (RN-03 y RN-06).
  - Inmutabilidad de comentarios tras 5 minutos.
  - Auditoría abierta: cualquier ciudadano puede inspeccionar la evidencia pública.

---

## 4.4. Decisiones de Modelo de Datos y Mejoras Resueltas

### A. Mecanismo de Cierre de Reportes (`RESUELTO`)
* **Problema:** Evitar que los reportes queden abiertos indefinidamente, pero sin permitir cierres arbitrarios o fraudulentos.
* **Solución Adoptada (Resolución Cívica con Evidencia Fotográfica y Verificación Cruzada):**
  1. Para solicitar o marcar el cierre de un reporte, es **obligatorio adjuntar una fotografía de evidencia** que demuestre la reparación de la vía, junto con un comentario explicativo.
  2. **Cierre por el Autor Original:** Si el autor del reporte sube la foto de la reparación, el estado pasa directamente a `RESUELTO`.
  3. **Cierre por un Vecino (Tercero):** Si un vecino sube la foto de reparación:
     - El autor recibe una notificación con la evidencia para confirmar la resolución con un clic.
     - Como salvaguarda ante autores inactivos, si el autor no responde o si el comentario con la foto de reparación alcanza **3 upvotes comunitarios**, el reporte se actualiza automáticamente a `RESUELTO`.
  4. **Campos en el Modelo:** Se agregan en `reporte` las columnas `fecha_resolucion TIMESTAMPTZ NULL` e `id_usuario_resolucion UUID NULL`.
  5. **Incentivo de Gamificación:** Quien proponga la resolución verificada recibe **+50 XP** cívicos.

### B. Alcance Geográfico: Colombia Urbana con Ciudad Piloto (Cali)
* **Definición del Alcance:** Plataforma cívica para **entornos urbanos de las principales ciudades de Colombia**, con **Cali como Ciudad Piloto de Lanzamiento**.
* **Justificación:**
  - Se descartan vías rurales terciarias, autopistas nacionales y carreteras intermunicipales (concesiones ANI / Invías), ya que no manejan el esquema de barrios/comunas ni la taxonomía de daños urbanos (andenes peatonales, semaforización urbana, fugas de alcantarillado).
  - El campo `ciudad` en `reporte` y `usuario` tiene por defecto `'Cali'`, pero acepta otras ciudades principales (Bogotá, Medellín, Barranquilla, Bucaramanga) sin romper la integridad relacional.
  - Se añade validación de coordenadas al polígono general de Colombia (Latitud entre -4.2° y 13.5°, Longitud entre -79.0° y -66.8°).

### C. Integridad de Evidencia Fotográfica Principal
* Se implementa un **índice único parcial** en PostgreSQL:
  ```sql
  CREATE UNIQUE INDEX idx_foto_principal_unica 
  ON foto_reporte (id_reporte) 
  WHERE es_principal = TRUE;
  ```
  Esto garantiza a nivel de base de datos que jamás existan dos fotografías marcadas simultáneamente como principales para el mismo reporte.
