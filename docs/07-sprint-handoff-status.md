# Documento de Entrega y Estado de Desarrollo: Sprint 2 y Sprint 3 — VIGÍA

**Proyecto:** VIGÍA (CivicApp) — Aplicación Móvil de Auditoría y Reporte Vial Ciudadano  
**Universidad Icesi — Aplicaciones Móviles (Prof. Domiciano Rincón)**  
**Arquitectura:** Clean Architecture + BLoC + Supabase + GetIt  
**Rama de trabajo:** `feat/sprint2-report-creation` (próxima a mergear en `develop`)  
**Fecha de corte:** Noviembre 2026  
**Progreso Sprint 2:** ~50% completado (Flujo nuclear de creación de reportes e inspección de detalle)

---

## 1. Resumen Ejecutivo de lo Realizado

En este bloque de desarrollo se construyó el **núcleo de generación de contenido de VIGÍA**: el asistente guiado de 5 pasos (*Report Wizard*) para registrar incidentes viales con georreferenciación GPS real, evidencia fotográfica y prevención preventiva de reportes duplicados, así como la pantalla de auditoría e inspección detallada del reporte.

### Historias de Usuario Completadas del Sprint 2 (100% Funcionales y Probadas)

| Historia de Usuario | Título | Qué hace / Comportamiento implementado |
|---|---|---|
| **HU-06** | Iniciar un Reporte | Botón de acción rápida en el dashboard cívico. Protección con diálogo modal contra descarte accidental de datos si el usuario intenta salir con un borrador iniciado. |
| **HU-07 (MVP)** | Paso 1: Ubicación y Nomenclatura Vial | Lectura del chip GPS real (`geolocator`), cálculo de distancia Haversine a 51 ciudades colombianas (ej. Popayán, Cali), formulario de **nomenclatura vial colombiana estándar** (Tipo de vía + Vía principal + Cruce + Predio/Número opcional) con alternativa de **Punto de referencia**. Validación de caja de coordenadas nacionales (RN-12). |
| **HU-08** | Paso 2: Clasificación y Gravedad | Selección entre las 7 tipologías oficiales en español con íconos vectoriales específicos de Material Design (sin emojis). Selector de gravedad de 4 niveles (`Baja`, `Media`, `Alta`, `Crítica`) bajo la norma de diseño *Shape + Color + Text* (RN-01). |
| **HU-09** | Paso 2.1: Detección Preventiva de Daños Cercanos | Consulta en tiempo real a Supabase filtrando reportes activos de la misma categoría en un radio de **150 metros**. Si hay coincidencias, despliega un modal con foto y distancia para permitirle al ciudadano **apoyar el reporte existente (+50 XP)** o continuar con un reporte nuevo. |
| **HU-10** | Paso 3: Evidencia Fotográfica | Selector de fotos integrado con `image_picker` (cámara o galería de archivos), soporte de 0 a 3 fotos (RN-02), compresión automática a 1920x1920 con calidad 80, subida con nombres únicos UUID al bucket `incident-evidence` de Supabase Storage. |
| **HU-11** | Paso 4: Descripción y Dimensiones | Formulario validado con título (5–180 caracteres), descripción detallada del riesgo vial (mínimo 10 caracteres) y dimensiones estimadas opcionales. |
| **HU-12** | Paso 5: Revisión, Código #VIG y Publicación | Tarjeta de resumen de datos, generación del código cívico único `#VIG-XXXX`, inserción en las tablas `road_incident` e `incident_photo` y **abono atómico de +100 XP** al perfil del usuario (RN-08). |
| **HU-14** | Inspección del Detalle del Reporte | Pantalla completa (`IncidentDetailScreen`) que consulta por UUID o código `#VIG-XXXX`: carrusel de fotos con badge `1/N`, sello de rango cívico del autor (`RankSeal`), estado del reporte, coordenadas y botón para sumar apoyos cívicos. |

---

## 2. Mapa de Archivos del Proyecto (Dónde vive el código)

Para que el equipo pueda auditar, extender o revisar la implementación, los archivos se organizaron estrictamente por capas siguiendo Clean Architecture:

```text
lib/
├── features/reports/
│   ├── domain/                         # LÓGICA PURA DART (Sin dependencias externas)
│   │   ├── entities/
│   │   │   ├── incident.dart           # Entidad principal del reporte y enums (Severity, Status)
│   │   │   ├── incident_category.dart  # Categorías de daño y nombres oficiales en español
│   │   │   ├── incident_photo.dart     # Evidencia fotográfica asociada
│   │   │   ├── nearby_incident.dart    # Modelo liviano para duplicados en radio de 150m
│   │   │   └── picked_photo.dart       # Abstracción desacoplada de la cámara/galería
│   │   ├── repositories/               # Contratos abstractos
│   │   │   ├── category_repository.dart
│   │   │   ├── incident_repository.dart
│   │   │   └── photo_picker_repository.dart
│   │   ├── usecases/                   # Casos de uso atómicos (1 responsabilidad)
│   │   │   ├── create_incident_usecase.dart       # Valida, sube fotos, persiste y suma +100 XP
│   │   │   ├── endorse_incident_usecase.dart      # Registra apoyo a reporte existente
│   │   │   ├── get_categories_usecase.dart        # Carga taxonomía de daños
│   │   │   ├── get_incident_by_id_usecase.dart    # Carga detalle por ID o código #VIG
│   │   │   ├── get_nearby_incidents_usecase.dart  # Consulta duplicados a 150m
│   │   │   └── pick_photo_usecase.dart            # Solicita foto al dispositivo
│   │   └── validators/
│   │       └── report_validators.dart  # Validaciones de coordenadas Colombia, textos y fotos
│   │
│   ├── data/                           # PERSISTENCIA & SERVICIOS EXTERNOS (Supabase/SDKs)
│   │   ├── datasources/
│   │   │   ├── category_remote_data_source.dart   # Query a tabla incident_category
│   │   │   ├── incident_remote_data_source.dart   # PostgREST a road_incident e incident_photo
│   │   │   ├── photo_picker_data_source.dart      # image_picker con compresión
│   │   │   └── photo_storage_data_source.dart     # Supabase Storage bucket incident-evidence
│   │   ├── models/
│   │   │   ├── incident_category_model.dart
│   │   │   ├── incident_model.dart                # Serialización JSON snake_case <-> camelCase
│   │   │   └── incident_photo_model.dart
│   │   └── repositories/
│   │       ├── category_repository_impl.dart
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
│           ├── location_pin_picker.dart           # Paso 1: GPS y nomenclatura colombiana
│           ├── nearby_incidents_modal.dart        # Paso 2.1: Alerta modal de duplicados
│           ├── photo_evidence_box.dart            # Paso 3: Caja de fotos con preview y eliminación
│           ├── severity_chip_selector.dart        # Paso 2: Selector minimalista de 4 gravedades
│           └── wizard_progress_header.dart        # Cabecera con barra de progreso y botón salir
│
├── core/
│   ├── constants/app_routes.dart       # Rutas '/report-wizard' y '/report-detail'
│   └── di/injection_container.dart     # Registro de dependencias en GetIt
│
└── data model/
    ├── schema.sql                      # DDL de base de datos
    └── migrations/
        └── 003_spanish_categories_and_storage.sql # Bucket y categorías en español
```

---

## 3. Lo que queda pendiente del Sprint 2 (Para el resto del equipo)

El Sprint 2 abarca tanto la **creación de reportes** (que ya dejamos lista al 100%) como la **exploración territorial ciudadana**. Lo que el equipo debe construir a continuación es:

### Historias de Usuario Pendientes de Sprint 2

1. **HU-03: Solicitud de Permisos de Ubicación al Ingresar a la App**
   - *Objetivo:* Pedir permiso de geolocalización al abrir la vista principal del mapa. Si el usuario lo deniega, no bloquear la app: centrar en su última ciudad registrada (`last_city`) y mostrar un banner no intrusivo *"Activar ubicación"*.
2. **HU-13: Visualización de Incidentes en el Mapa Cartográfico**
   - *Objetivo:* Pantalla principal con mapa interactivo (`flutter_map` con OpenStreetMap o Google Maps) que renderice los reportes de la ciudad con marcadores por color/forma según la categoría y gravedad.
3. **HU-19: Feed Comunitario de Incidentes**
   - *Objetivo:* Pestaña de listado/feed cronológico de reportes con paginación infinita (bloques de 20 elementos), tarjetas de reporte con foto, estado, distancia y soporte para refrescar con *Pull-to-refresh*.
4. **HU-21: Selector Asistido de Ciudad (Smart City Switcher)**
   - *Objetivo:* Modal con buscador fuzzy para cambiar la ciudad activa entre los municipios soportados de Colombia sin tener que reiniciar la sesión.
5. **HU-22: Modo de Navegación Invitado (Sin Cuenta)**
   - *Objetivo:* Permitir que un usuario explore el mapa y el feed sin iniciar sesión. Si intenta publicar un reporte (HU-06) o votar, abrir modal de inicio de sesión/registro.
6. **Refinamientos de Geolocalización (Añadidas al Backlog de Sprint 2):**
   - **HU-26:** Geocodificación inversa asistida con OpenStreetMap (Nominatim) para autorrellenar calle/carrera al presionar "Mi GPS".
   - **HU-27:** Widget de mapa interactivo en el Paso 1 para mover un pin manualmente.
   - **HU-28:** Geocodificación directa (convertir dirección escrita a coordenadas estimadas).

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
2. Ejecutar la migración SQL `data model/migrations/003_spanish_categories_and_storage.sql` en el SQL Editor de Supabase si usan un entorno nuevo (crea el bucket `incident-evidence` y asegura nombres en español).

### Verificación Automatizada (100% Verde)
Ejecutar en la terminal:
```bash
dart run tool/check.dart
```
Debe arrojar:
- `Architecture guards: OK`
- `flutter analyze: No issues found!`
- `flutter test: 178 tests passed!`

### Prueba Manual Paso a Paso (en Windows o Móvil)
1. Ejecutar la app: `flutter run -d windows` (o tu emulador/dispositivo Android).
2. Iniciar sesión o registrar un usuario (ej. en Popayán o Cali).
3. En la pantalla principal, presionar el botón de acción rápida **"Reportar daño vial"**.
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
