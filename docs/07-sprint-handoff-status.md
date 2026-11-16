# Documento de Entrega y Estado de Desarrollo: Sprint 2 y Sprint 3 — VIGÍA

**Proyecto:** VIGÍA (CivicApp) — Aplicación Móvil de Auditoría y Reporte Vial Ciudadano  
**Universidad Icesi — Aplicaciones Móviles (Prof. Domiciano Rincón)**  
**Arquitectura:** Clean Architecture + BLoC + Supabase + GetIt  
**Rama de integración:** `develop` (cada HU entra con su rama `feat/hu-XX-…` y un merge commit)  
**Fecha de corte:** 14 de noviembre de 2026  
**Progreso Sprint 2:** 17 de 17 historias completadas (100 % en código; falta validarlas en un dispositivo).

---

## 1. Resumen Ejecutivo de lo Realizado

En el primer bloque se construyó el **núcleo de generación de contenido de VIGÍA**: el asistente guiado de 5 pasos (*Report Wizard*) para registrar incidentes viales con georreferenciación GPS real, evidencia fotográfica y prevención de reportes duplicados, así como la pantalla de inspección detallada del reporte.

En el segundo bloque se construyó la **exploración territorial**: el shell con las pestañas Mapa y Mi perfil, el mapa de la ciudad con marcadores por gravedad, el permiso de ubicación al abrir, la recuperación de un permiso bloqueado, la sugerencia automática de dirección (Nominatim), el selector de punto en el mapa del Paso 1 y el modo invitado sin cuenta.

### Historias de Usuario Completadas del Sprint 2 (100% Funcionales y Probadas)

| Historia de Usuario | Título | Qué hace / Comportamiento implementado |
|---|---|---|
| **HU-06** | Iniciar un Reporte | Botón flotante **"Reportar daño"** en el shell (pestañas Mapa y Mi perfil). Protección con diálogo modal contra descarte accidental de datos si el usuario intenta salir con un borrador iniciado. |
| **HU-07 (MVP)** | Paso 1: Ubicación y Nomenclatura Vial | Lectura del chip GPS real (`geolocator`), cálculo de distancia Haversine a 51 ciudades colombianas (ej. Popayán, Cali), formulario de **nomenclatura vial colombiana estándar** (Tipo de vía + Vía principal + Cruce + Predio/Número opcional) con alternativa de **Punto de referencia**. Validación de caja de coordenadas nacionales (RN-12). |
| **HU-08** | Paso 2: Clasificación y Gravedad | Selección entre las 7 tipologías oficiales en español con íconos vectoriales específicos de Material Design (sin emojis). Selector de gravedad de 4 niveles (`Baja`, `Media`, `Alta`, `Crítica`) bajo la norma de diseño *Shape + Color + Text* (RN-01). |
| **HU-09** | Paso 2.1: Detección Preventiva de Daños Cercanos | Consulta en tiempo real a Supabase filtrando reportes activos de la misma categoría en un radio de **150 metros**. Si hay coincidencias, despliega un modal con foto y distancia para permitirle al ciudadano **apoyar el reporte existente (+50 XP)** o continuar con un reporte nuevo. |
| **HU-10** | Paso 3: Evidencia Fotográfica | Selector de fotos integrado con `image_picker` (cámara o galería de archivos), soporte de 0 a 3 fotos (RN-02), compresión automática a 1920x1920 con calidad 80, subida con nombres únicos UUID al bucket `incident-evidence` de Supabase Storage. |
| **HU-11** | Paso 4: Descripción y Dimensiones | Formulario validado con título (5–180 caracteres), descripción detallada del riesgo vial (mínimo 10 caracteres) y dimensiones estimadas opcionales. |
| **HU-12** | Paso 5: Revisión, Código #VIG y Publicación | Tarjeta de resumen de datos, generación del código cívico único `#VIG-XXXX`, inserción en las tablas `road_incident` e `incident_photo` y **abono atómico de +100 XP** al perfil del usuario (RN-08). |
| **HU-14** | Inspección del Detalle del Reporte | Pantalla completa (`IncidentDetailScreen`) que consulta por UUID o código `#VIG-XXXX`: carrusel de fotos con badge `1/N`, sello de rango cívico del autor (`RankSeal`), estado del reporte, coordenadas y barra de validación comunitaria (0 a 10 apoyos). El botón para apoyar llega con HU-15 (Sprint 3). |
| **HU-13 (MVP)** | Mapa de la Ciudad con Marcadores | Shell con pestañas **Mapa** y **Mi perfil**. `flutter_map` con teselas de OpenStreetMap (oscurecidas en tema oscuro), centrado en la ciudad del perfil, con un marcador por reporte cuya **forma y color indican la gravedad** y que abre el detalle. Botón **"Centrar en mi ubicación"**. El mapa recarga los marcadores al publicar un reporte. |
| **HU-03** | Permiso de Ubicación al Abrir | El mapa pide el permiso en su primera carga y se centra en el ciudadano si lo concede. Si lo niega, la app no se bloquea: se queda en la vista de la ciudad y el botón "Centrar en mi ubicación" reemplaza el banner "Activar ubicación". |
| **HU-28** | Geocodificación Directa | "Confirmar ubicación" convierte la dirección escrita en un punto cuando el punto no es decisión del ciudadano. El GPS y el punto marcado en el mapa mandan y la dirección nunca los reemplaza; el centro de la ciudad (ahora tomado del catálogo de 51 ciudades, ya no de 6 escritas a mano) y el punto de otra dirección sí se buscan. Antes de buscar, la dirección se reescribe como la nombra OpenStreetMap: `Cra`, `Cl`, `Av`, `Kr`… pasan a `Carrera`, `Calle`, `Avenida`…; `6N` a `6 Norte`; `No.`/`Nº` equivalen a `#`; `Cra 9 5-45` (sin `#`) también se entiende. Prueba con 7 direcciones de Popayán, Cali y Pasto: 0 m de error cuando OpenStreetMap tiene el número, 200–340 m sobre la calle correcta si no. El Paso 1 queda abierto tras la búsqueda (dos toques: buscar, luego continuar). Cinco resultados con su mensaje y su siguiente paso: encontrada, solo la calle ("Ajustar en el mapa"), no encontrada, formato no entendido y servicio caído ("Reintentar"), todos con salida al mapa. La tarjeta de coordenadas dice de dónde viene el punto (GPS, mapa, según la dirección, centro de la ciudad). |
| **HU-29** | Recuperar un Permiso Bloqueado (KI-01) | Si el permiso de ubicación está bloqueado, los tres botones de GPS (registro, mapa y Paso 1) abren el modal **"Ubicación bloqueada"** con **"Abrir ajustes"**. |
| **HU-26** | Sugerencia Automática de Dirección | Al abrir el asistente con GPS, al usar "Centrar en mi ubicación" o al confirmar un punto en el mapa, se consulta **Nominatim** (OpenStreetMap) y se rellenan tipo de vía, vía principal, cruce, número y barrio. El cruce sale de la placa ("5-37") o de una esquina cercana. Anillo de carga y "Buscando…" mientras llega; si falla o queda incompleta, un aviso pide escribirla a mano. Todo sigue editable. |
| **HU-27** | Selector de Punto en el Mapa (Paso 1) | El botón **"Seleccionar ubicación"** cambia el formulario por un mapa **dentro del mismo Paso 1** (el encabezado "Paso 1 de 5" se mantiene). El mapa llena el alto libre de la pantalla, el ciudadano lo mueve bajo un pin fijo y toca **"Confirmar punto"**: se toman esas coordenadas, se detecta su ciudad y se sugiere su dirección. "Volver" regresa sin cambios. |
| **HU-19** | Feed Comunitario de Incidentes | Tercera pestaña **"Comunidad"** del shell: los reportes de la ciudad activa, del más reciente al más antiguo, de 20 en 20 al hacer scroll, con *pull-to-refresh*. La ciudad es la del mapa (también la que cambia el selector de HU-21). Cada tarjeta muestra la foto (o el ícono de la categoría si no hay), el código `#VIG`, la gravedad (forma + color + texto), el barrio, el título, el autor con su sello de rango, apoyos, comentarios, estado y fecha, y la distancia solo si se conoce la ubicación; toda la tarjeta abre el detalle. Si falla la recarga, la lista se queda con un aviso y "Reintentar"; si falla una página, aparece "Reintentar" bajo la lista; una ciudad sin reportes invita a publicar el primero. Funciona también para el invitado. |
| **HU-21** | Selector Asistido de Ciudad | Botón con la ciudad del mapa (arriba a la izquierda) que abre un sheet **"Cambiar ciudad"**: búsqueda sin tildes ni mayúsculas por ciudad o departamento (hasta 8 resultados), hasta 3 ciudades recientes (guardadas en el dispositivo) y chips rápidos (Bogotá, Medellín, Cali, Barranquilla, Bucaramanga). Al elegir, un ciudadano guarda `last_city` en su perfil y el mapa abre ahí en la siguiente sesión; un invitado solo cambia la ciudad que ve. |
| **HU-22** | Modo Invitado (Sin Cuenta) | **"Explorar sin cuenta"** en el login abre el shell sin sesión. El invitado ve el mapa y el detalle de los reportes (políticas `anon` de `schema.sql`); el mapa abre en la ciudad cubierta más cercana al GPS, o en Cali sin GPS. **"Reportar daño"** sigue visible y abre el modal **"Necesitas iniciar sesión"** (Ahora no · Crear cuenta · Iniciar sesión) sin abrir el asistente. **"Mi perfil"** muestra una invitación a iniciar sesión y oculta "Cerrar sesión". |

---

## 2. Mapa de Archivos del Proyecto (Dónde vive el código)

Para que el equipo pueda auditar, extender o revisar la implementación, los archivos se organizaron estrictamente por capas siguiendo Clean Architecture:

```text
lib/
├── features/explore/                   # SHELL, MAPA, SELECTOR DE CIUDAD Y FEED (HU-13, HU-03, HU-22, HU-21, HU-19)
│   ├── domain/                         # Selector de ciudad (HU-21)
│   │   ├── entities/city_options.dart          # Catálogo, recientes y atajos del selector
│   │   ├── repositories/recent_cities_repository.dart
│   │   └── usecases/                           # get_city_options · search_cities · switch_city
│   ├── data/                           # Ciudades recientes guardadas en el dispositivo (shared_preferences)
│   │   ├── datasources/recent_cities_local_data_source.dart
│   │   └── repositories/recent_cities_repository_impl.dart
│   └── ui/
│       ├── bloc/map_bloc.dart          # Ciudad, marcadores, "Centrar en mi ubicación" y cambio de ciudad
│       ├── bloc/city_switcher_*.dart   # Búsqueda del selector de ciudad (HU-21)
│       ├── bloc/feed_*.dart            # Feed: eventos, estado y Bloc (HU-19)
│       ├── pages/map_page.dart         # Pestaña Mapa (flutter_map + OpenStreetMap)
│       ├── pages/feed_page.dart        # Pestaña Comunidad: lista, scroll infinito, refresh (HU-19)
│       ├── screens/home_screen.dart    # Shell: 3 pestañas, "Reportar daño", modal del invitado y reenvío de la ciudad al feed
│       └── widgets/
│           ├── incident_map_marker.dart        # Marcador con forma y color de gravedad
│           ├── city_switcher_sheet.dart        # Sheet "Cambiar ciudad" (HU-21)
│           └── feed_incident_card.dart         # Tarjeta de reporte del feed (HU-19)
│
├── features/dashboard/ui/              # MI PERFIL (resumen, invitación al invitado)
│   ├── bloc/profile_bloc.dart          # Estados success · guest · signedOut
│   └── pages/profile_page.dart
│
├── features/reports/
│   ├── domain/                         # LÓGICA PURA DART (Sin dependencias externas)
│   │   ├── entities/
│   │   │   ├── incident.dart           # Entidad principal del reporte y enums (Severity, Status)
│   │   │   ├── incident_category.dart  # Categorías de daño y nombres oficiales en español
│   │   │   ├── incident_photo.dart     # Evidencia fotográfica asociada
│   │   │   ├── incident_marker.dart    # Marcador liviano para el mapa
│   │   │   ├── feed_incident.dart      # Resumen de un reporte para la tarjeta del feed (HU-19)
│   │   │   ├── nearby_incident.dart    # Modelo liviano para duplicados en radio de 150m
│   │   │   ├── geocoded_place.dart     # Respuesta de Nominatim traducida al dominio
│   │   │   ├── suggested_address.dart  # Dirección sugerida (vía, cruce, placa, barrio)
│   │   │   └── picked_photo.dart       # Abstracción desacoplada de la cámara/galería
│   │   ├── repositories/               # Contratos abstractos
│   │   │   ├── category_repository.dart
│   │   │   ├── geocoding_repository.dart
│   │   │   ├── incident_repository.dart
│   │   │   └── photo_picker_repository.dart
│   │   ├── usecases/                   # Casos de uso atómicos (1 responsabilidad)
│   │   │   ├── create_incident_usecase.dart       # Valida, sube fotos, persiste y suma +100 XP
│   │   │   ├── endorse_incident_usecase.dart      # Registra apoyo a reporte existente
│   │   │   ├── get_categories_usecase.dart        # Carga taxonomía de daños
│   │   │   ├── geocode_address_usecase.dart       # Dirección escrita -> punto, con centro de ciudad de respaldo (HU-28)
│   │   │   ├── get_city_center_usecase.dart       # Centro de una ciudad del catálogo (HU-28)
│   │   │   ├── get_city_feed_usecase.dart         # Una página del feed: tamaño de página y "hay más" (HU-19)
│   │   │   ├── get_city_map_usecase.dart          # Ciudad del mapa y sus reportes (last_city, o GPS para el invitado)
│   │   │   ├── get_current_location_usecase.dart  # Posición GPS del dispositivo
│   │   │   ├── get_incident_by_id_usecase.dart    # Carga detalle por ID o código #VIG
│   │   │   ├── get_nearby_incidents_usecase.dart  # Consulta duplicados a 150m
│   │   │   ├── pick_photo_usecase.dart            # Solicita foto al dispositivo
│   │   │   └── suggest_address_usecase.dart       # Sugiere la dirección de un punto (HU-26)
│   │   └── validators/
│   │       ├── address_normalizer.dart  # Reescribe la dirección como la nombra OpenStreetMap (HU-28)
│   │       └── report_validators.dart  # Validaciones de coordenadas Colombia, textos y fotos
│   │
│   ├── data/                           # PERSISTENCIA & SERVICIOS EXTERNOS (Supabase/SDKs)
│   │   ├── datasources/
│   │   │   ├── category_remote_data_source.dart   # Query a tabla incident_category
│   │   │   ├── incident_remote_data_source.dart   # PostgREST a road_incident e incident_photo
│   │   │   ├── nominatim_data_source.dart         # Geocodificación inversa (1 consulta/s, User-Agent)
│   │   │   ├── photo_picker_data_source.dart      # image_picker con compresión
│   │   │   └── photo_storage_data_source.dart     # Supabase Storage bucket incident-evidence
│   │   ├── models/
│   │   │   ├── feed_incident_model.dart           # Fila del feed (consulta anidada) <-> entidad
│   │   │   ├── incident_category_model.dart
│   │   │   ├── incident_model.dart                # Serialización JSON snake_case <-> camelCase
│   │   │   └── incident_photo_model.dart
│   │   └── repositories/
│   │       ├── category_repository_impl.dart
│   │       ├── geocoding_repository_impl.dart
│   │       ├── incident_repository_impl.dart
│   │       └── photo_picker_repository_impl.dart
│   │
│   └── ui/                             # CAPA DE PRESENTACIÓN (BLoC & Widgets Flutter)
│       ├── bloc/
│       │   ├── incident_detail_bloc.dart          # Estado y eventos de la pantalla de detalle
│       │   ├── report_wizard_bloc.dart            # Orquestador del asistente de 5 pasos
│       │   ├── report_wizard_event.dart
│       │   └── report_wizard_state.dart
│       ├── screens/
│       │   ├── incident_detail_screen.dart        # Vista de auditoría (HU-14)
│       │   └── report_wizard_screen.dart          # Contenedor del Wizard de 5 pasos (HU-06 a HU-12)
│       └── widgets/
│           ├── location_pin_picker.dart           # Paso 1: coordenadas y nomenclatura colombiana
│           ├── map_point_selector.dart            # Paso 1: mapa con pin fijo y "Confirmar punto" (HU-27)
│           ├── nearby_incidents_modal.dart        # Paso 2.1: Alerta modal de duplicados
│           ├── photo_evidence_box.dart            # Paso 3: Caja de fotos con preview y eliminación
│           ├── severity_chip_selector.dart        # Paso 2: Selector minimalista de 4 gravedades
│           └── wizard_progress_header.dart        # Cabecera con barra de progreso y botón salir
│
├── core/
│   ├── constants/app_routes.dart       # Rutas con su BlocProvider ('/home', '/report-wizard', '/report-detail'…)
│   ├── di/injection_container.dart     # Registro de dependencias en GetIt
│   └── widgets/
│       ├── location_blocked_dialog.dart   # Modal "Ubicación bloqueada" (HU-29)
│       └── sign_in_required_dialog.dart   # Modal "Necesitas iniciar sesión" (HU-22)
│
└── data model/
    ├── schema.sql                      # DDL de base de datos
    └── migrations/
        └── 003_spanish_categories_and_storage_bucket.sql # Bucket y categorías en español
```

---

## 3. Lo que queda pendiente del Sprint 2 (Para el resto del equipo)

Las 17 historias del Sprint 2 están implementadas. Lo que queda no es una historia nueva, sino validar en un dispositivo real:

1. **Feed y geocodificación contra Supabase y Nominatim reales.** Los tests usan dobles; la consulta anidada del feed y la búsqueda de direcciones no se han probado en un teléfono.
2. **Precisión de la geocodificación (HU-28).** Depende de qué tan bien esté mapeada cada ciudad en OpenStreetMap. Se probó con 7 direcciones, casi todas céntricas. Conviene probar barrios periféricos y otras ciudades.
3. **Límites conocidos de HU-28:** `Carrera 9 con Calle 5` no se entiende (y lo dice); el radio de 25 km es un supuesto; si el ciudadano fija el punto con el GPS y luego escribe una dirección de otro lugar, el punto no se mueve (se corrige con el mapa).

**Regla para lo que venga:** toda acción que necesite cuenta (apoyar, comentar, seguir) debe abrir `showSignInRequiredDialog` cuando el usuario es invitado (`ProfileStatus.guest`), igual que "Reportar daño".

---

## 4. Panorama del Sprint 3 (Para referencia del equipo)

*Nota: Todas las historias de usuario completas del Sprint 3 están documentadas en detalle en `docs/06-sprint-3-backlog.md`.*

El **Sprint 3** se enfoca en la **interacción social ciudadana, gamificación y cumplimiento de requisitos académicos**:
- **Interacción comunitaria con reportes:**
  - **HU-15:** Apoyar reportes de otros ciudadanos (*Upvote* / Endoso cívico).
  - **HU-16:** Seguimiento a la validación comunitaria (barra de 0 a 10 apoyos para elevar a prioritario).
  - **HU-17:** Hilo de discusión cívica (comentarios en reportes con foto opcional de evolución).
  - **HU-18:** Edición y retiro de reportes propios.
  - **HU-20:** Búsqueda avanzada, filtros por gravedad/categoría y ordenamiento.
- **Auditoría cívica y cierre:**
  - **HU-25 (RN-11):** Propuesta de resolución ciudadana (subir evidencia de que la vía fue reparada) y verificación comunitaria.
- **Perfil, gamificación y privacidad:**
  - **HU-01 / HU-02 / HU-04:** Configuración de privacidad, permisos del dispositivo y edición de perfil.
  - **HU-05 / HU-23:** Avatar cívico y panel de impacto (medallas ganadas, XP total, reportes resueltos).
- **Requisito Académico Obligatorio (Prof. Domiciano Rincón):**
  - **HU-24: Notificaciones Push para al menos 2 eventos** (ej. "Tu reporte recibió 5 apoyos", "El bache que reportaste cambió a estado En Revisión" o "Nuevo daño crítico en tu barrio").

---

## 5. Guía de Pruebas de Humo (Smoke Test) para los Compañeros

Para que cualquier integrante del equipo pueda verificar localmente que todo funciona:

### Requisitos previos
1. Tener el archivo `.env` en la raíz con:
   ```env
   SUPABASE_URL=https://tu-proyecto.supabase.co
   SUPABASE_ANON_KEY=tu-clave-publica-anon
   ```
2. Ejecutar la migración SQL `data model/migrations/003_spanish_categories_and_storage_bucket.sql` en el SQL Editor de Supabase si usan un entorno nuevo (crea el bucket `incident-evidence` y asegura nombres en español).

### Verificación Automatizada (100% Verde)
Ejecutar en la terminal:
```bash
dart run tool/check.dart
```
Debe arrojar:
- `Architecture guards: OK`
- `flutter analyze: No issues found!`
- `flutter test: 454 tests passed!`

### Prueba Manual Paso a Paso (en Windows o Móvil)
1. Ejecutar la app: `flutter run -d windows` (o tu emulador/dispositivo Android).
2. Iniciar sesión o registrar un usuario (ej. en Popayán o Cali). La app abre en la pestaña **Mapa**: aceptar el permiso de ubicación y verificar que el mapa se centra en el equipo y muestra los marcadores de la ciudad.
3. En el shell, presionar el botón flotante **"Reportar daño"**.
4. **Paso 1 (Ubicación):**
   - Presionar **"Seleccionar ubicación"**: se abre el mapa dentro del Paso 1; mover el mapa bajo el pin y tocar **"Confirmar punto"** (o **"Centrar en mi ubicación"** para leer el GPS del equipo). Se detecta la ciudad más cercana y se sugiere la dirección.
   - En *Nomenclatura vial*, seleccionar *Tipo de vía* (ej. Carrera), ingresar *Vía principal* (`9`) y *Cruce* (`45`). Dejar *Número/predio* vacío (verificar que es opcional). Ingresar barrio (ej. `Centro`).
   - Tocar **"Confirmar ubicación"**.
5. **Paso 2 (Categoría & Gravedad):**
   - Observar las 7 tarjetas minimalistas con íconos vectoriales diferenciados.
   - Seleccionar una categoría (ej. *Hueco o bache en calzada*).
   - En *Gravedad*, seleccionar un nivel con el selector estilizado (ej. *Alta*).
   - Tocar **"Continuar"** (si no hay reportes a 150m, avanza directo; si los hay, abre el modal de prevención).
6. **Paso 3 (Evidencia):**
   - Tocar la caja de fotos para adjuntar hasta 3 fotos desde la galería o archivos.
   - Tocar **"Continuar con la descripción"**.
7. **Paso 4 (Detalles):**
   - Ingresar un título claro (ej. *"Hueco profundo en carril derecho"*).
   - Ingresar descripción detallada y dimensiones aproximadas opcionales.
   - Tocar **"Revisar reporte"**.
8. **Paso 5 (Publicación & Gamificación):**
   - Revisar la tarjeta de resumen y la insignia de **+100 XP**.
   - Tocar **"Publicar reporte (+100 XP)"**.
   - Aparecerá el diálogo con el código oficial generado (ej. `#VIG-4821`).
   - Al aceptar, el reporte queda guardado en Supabase con sus fotos y los puntos se acreditan al perfil.

### Prueba Manual de la Dirección Escrita (HU-28)
1. Abrir el asistente **sin permiso de ubicación** (o con la ubicación apagada). La tarjeta de coordenadas dice "Aproximada: centro de la ciudad".
2. En *Nomenclatura vial* escribir, por ejemplo, Carrera `9`, cruce `5`, número `45` y un barrio real de la ciudad. Tocar **"Confirmar ubicación"**.
3. El Paso 1 sigue abierto, la tarjeta cambia a "Aproximada: según la dirección" y aparece un aviso (encontrada, solo la calle o no encontrada). Tocar **"Confirmar ubicación"** otra vez: pasa al Paso 2.
4. Repetir con una dirección que no exista: el punto queda en el centro de la ciudad y el aviso ofrece **"Marcar en el mapa"**.
5. Con el modo avión: aviso de conexión con **"Reintentar"** (vuelve a buscar al reactivar la red).
6. Con el GPS activo: la dirección escrita **no** mueve el punto (la tarjeta dice "Tu ubicación (GPS)").

### Prueba Manual del Modo Invitado (HU-22)
1. Cerrar sesión desde **Mi perfil** (o abrir la app sin sesión) y, en el login, tocar **"Explorar sin cuenta"**.
2. Verificar que el mapa carga con los reportes de la ciudad más cercana (o de Cali si se niega la ubicación) y que un marcador abre el detalle.
3. Tocar **"Reportar daño"**: debe abrirse el modal **"Necesitas iniciar sesión"** y no el asistente. "Ahora no" lo cierra; "Iniciar sesión" lleva al login.
4. Ir a **Mi perfil**: debe verse la invitación "Inicia sesión para ver tu perfil", sin "Cerrar sesión".
5. Iniciar sesión desde la invitación: se llega al mapa como cualquier ciudadano.
