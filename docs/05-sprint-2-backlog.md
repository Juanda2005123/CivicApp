# Documento 5: Sprint Backlog 2 — Creación, Exploración y Catastro Cívico

**Rama:** `develop` (documentado en `docs/sprint-2-3-backlogs`)  
**Estado:** Planificado  
**Objetivo del Sprint:** Permitir a los ciudadanos explorar reportes viales en su ciudad mediante un mapa interactivo y un feed sincronizado, cambiar ágilmente de ciudad y registrar nuevos reportes con evidencia fotográfica y georreferenciación precisa a través de un asistente guiado de 5 pasos con detección preventiva de duplicados.

---

## 1. Visión General del Sprint 2

El **Sprint 2** sienta las bases de contenido de VIGÍA. Sin reportes no hay comunidad ni interacción social; por tanto, este sprint se concentra en el **ciclo de generación de reportes y exploración territorial**.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ALCANCE DEL SPRINT 2                            │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Navegación Principal y Permisos:                                    │
│    - BottomNavigationBar: Mapa, Comunidad (Feed) y Perfil.            │
│    - Gestión de permisos de ubicación al entrar al mapa (HU-03).       │
│                                                                        │
│ 2. Asistente Guiado de Publicación (Wizard de 5 pasos):                │
│    - HU-06: Lanzador del asistente y guardia contra descartes.         │
│    - HU-07: Paso 1 - Ubicación interactiva en mapa + geocodificación.  │
│    - HU-08: Paso 2 - Clasificación de daño + severidad.                │
│    - HU-09: Paso 2.1 - Detección preventiva de daños cercanos.         │
│    - HU-10: Paso 3 - Evidencia fotográfica (cámara/galería, máx 3).    │
│    - HU-11: Paso 4 - Descripción detallada y dimensiones.              │
│    - HU-12: Paso 5 - Confirmación, código #VIG-XXXX y +100 XP.         │
│                                                                        │
│ 3. Exploración Cartográfica y Comunitaria:                             │
│    - HU-13: Mapa general con marcadores temáticos por tipo de daño.    │
│    - HU-14: Pantalla de detalle de lectura del reporte.                │
│    - HU-19: Feed vertical paginado en bloques de 20 con pull-to-refresh│
│    - HU-21: Smart City Switcher (selector asistido con búsqueda difusa)│
│    - HU-22: Modo Visitante / Exploración sin cuenta.                   │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Historias de Usuario Detalladas

### HU-03: Solicitar la ubicación al entrar a la pantalla principal
**Como** usuario,  
**quiero** que la app me pida la ubicación al entrar a la pantalla principal (Mapa),  
**para** ver el mapa y el feed centrados en donde estoy.

#### Criterios de aceptación
1. **Dado que** entro a la pantalla principal (HU-13), **cuando** todavía no he respondido sobre este permiso, **entonces** se abre la solicitud del sistema para usar la ubicación mientras uso la app.
2. **Dado que** concedí el permiso, **cuando** entro al mapa (HU-13) o al feed (HU-19), **entonces** se centran en mi posición.
3. **Dado que** negué el permiso, **cuando** entro, **entonces** la app funciona sin bloquearse, usa mi última ciudad activa (`last_city`) (HU-21) y muestra un aviso con el botón *"Activar ubicación"*.
4. **Dado que** toco *"Activar ubicación"*, **cuando** el sistema lo permite, **entonces** se solicita de nuevo el permiso; si no, se abren los ajustes del sistema.
5. **Dado que** estoy fuera de las ciudades de cobertura, **cuando** entro a la pantalla principal, **entonces** se mantiene mi última ciudad activa (`last_city`) y veo un aviso que lo explica.

---

### HU-06: Iniciar un reporte
**Como** ciudadano registrado,  
**quiero** iniciar un reporte desde donde esté en la app,  
**para** registrar un daño apenas lo veo.

#### Criterios de aceptación
1. **Dado que** estoy en Mapa (HU-13) o Comunidad (HU-19), **cuando** toco *"Reportar"*, **entonces** se abre el asistente en el paso 1 (HU-07).
2. **Dado que** estoy en el asistente, **cuando** avanzo o retrocedo, **entonces** veo en qué paso voy, por ejemplo *"Paso 2 de 5"*.
3. **Dado que** ya ingresé datos, **cuando** intento salir, **entonces** la app me pide confirmar antes de descartarlos.
4. **Dado que** todavía no ingresé datos, **cuando** salgo, **entonces** vuelvo a la pantalla anterior sin confirmar nada.
5. **Dado que** no inicié sesión (HU-22), **cuando** toco *"Reportar"*, **entonces** se me invita a iniciar sesión o registrarme y no se abre el asistente.

---

### HU-07: Paso (1) - Ubicar el daño en el mapa
**Como** ciudadano registrado,  
**quiero** marcar en un mapa el punto exacto del daño,  
**para** que otras personas puedan identificar dónde está.

#### Criterios de aceptación
1. **Dado que** concedí el permiso de ubicación, **cuando** abro el paso 1 del asistente, **entonces** el mapa se centra en mi posición con una mira en el centro.
2. **Dado que** negué el permiso de ubicación, **cuando** abro el paso 1, **entonces** el mapa se centra en mi última ciudad activa (`last_city`) (HU-21), puedo mover el punto a mano y la app no se bloquea.
3. **Dado que** fijé un punto, **cuando** se consulta su dirección, **entonces** se proponen la dirección y el barrio, y puedo corregirlos.
4. **Dado que** la consulta de dirección falla, **cuando** intento continuar, **entonces** puedo escribir la dirección y el barrio a mano, y ambos son obligatorios para avanzar.
5. **Dado que** el punto está fuera del rango de Colombia (latitud -4.2° a 13.5°, longitud -79.0° a -66.8°) o fuera de las ciudades de cobertura, **cuando** intento continuar, **entonces** veo un mensaje que lo explica y no puedo avanzar.
6. **Dado que** no tengo GPS o prefiero no usarlo, **cuando** busco una dirección aproximada por texto, **entonces** el mapa se ubica en ese lugar y puedo ajustar el punto.

---

### HU-08: Paso (2) - Clasificar el daño
**Como** ciudadano registrado,  
**quiero** indicar el tipo de daño y su gravedad,  
**para** que la comunidad identifique rápidamente de qué problema se trata y qué tan serio es.

#### Criterios de aceptación
1. **Dado que** estoy en el paso 2, **cuando** se carga la pantalla, **entonces** veo las categorías del catálogo en español, cada una con icono y nombre.
2. **Dado que** debo indicar la gravedad, **cuando** elijo entre Baja, Media, Alta y Crítica, **entonces** cada opción se distingue por forma, color y texto (según el sistema de diseño §3.3).
3. **Dado que** no elegí una categoría o una gravedad, **cuando** intento continuar, **entonces** se señala lo que falta y no puedo avanzar.
4. **Dado que** falla la carga de las categorías, **cuando** se muestra el error, **entonces** puedo reintentar sin perder lo ingresado en el paso anterior (HU-07).
5. **Dado que** estoy en el paso 2, **cuando** escribo en el buscador de tipos, **entonces** la lista muestra solo los tipos que coinciden, sin importar tildes ni mayúsculas.
6. **Dado que** selecciono un tipo y hay reportes de ese tipo cerca del punto marcado (HU-07), **cuando** termina la revisión, **entonces** veo un mensaje que dice *"Hay N daños cercanos"* que puedo tocar para verlos (HU-09).
7. **Dado que** cambio de tipo, **cuando** selecciono el nuevo, **entonces** el mensaje se actualiza con la cantidad de ese tipo.
8. **Dado que** no hay reportes cercanos de ese tipo o falla la revisión, **cuando** termina, **entonces** no se muestra la cantidad y puedo continuar con mi reporte.

---

### HU-09: Paso (2.1) - Ver daños cercanos al reporte
**Como** ciudadano registrado,  
**quiero** ver los daños cercanos del mismo tipo sin salir del reporte,  
**para** comprobar si el mío ya fue publicado sin perder mi progreso.

#### Criterios de aceptación
1. **Dado que** veo el mensaje *"Hay N daños cercanos"* (HU-08), **cuando** lo toco, **entonces** veo esos reportes sin salir del paso 2.
2. **Dado que** estoy viendo los daños cercanos, **cuando** reviso un reporte, **entonces** veo su foto principal, tipo, gravedad y distancia; si no tiene foto, veo un espacio reservado con el icono de su tipo.
3. **Dado que** reconozco mi daño, **cuando** toco *"Es este daño"*, **entonces** apoyo ese reporte y salgo del proceso sin publicar uno nuevo; si ya lo había apoyado, mi apoyo se mantiene, y si el reporte es mío, salgo sin registrar el apoyo.
4. **Dado que** mi daño es distinto, **cuando** toco *"Es otro daño"* o cierro la vista, **entonces** vuelvo al paso 2 con la ubicación, el tipo y la gravedad que había ingresado.

---

### HU-10: Paso (3) - Adjuntar fotos como evidencia
**Como** ciudadano registrado,  
**quiero** adjuntar fotos del daño,  
**para** respaldar mi reporte con evidencia.

#### Criterios de aceptación
1. **Dado que** estoy en el paso 3, **cuando** elijo agregar una foto, **entonces** puedo tomarla con la cámara o seleccionarla de la galería.
2. **Dado que** ya adjunté 3 fotos, **cuando** veo el paso 3, **entonces** la opción de agregar otra está deshabilitada y se indica el límite de 3.
3. **Dado que** selecciono un archivo que no es JPG, PNG o WebP, o que pesa más de 5 MB, **cuando** se valida, **entonces** se rechaza con un mensaje que indica el motivo y las demás fotos se conservan.
4. **Dado que** no tengo fotos disponibles, **cuando** elijo omitir este paso, **entonces** avanzo sin adjuntar ninguna.
5. **Dado que** adjunté varias fotos, **cuando** reviso el paso, **entonces** puedo quitar cualquiera de ellas, y la primera queda como foto principal del reporte.

---

### HU-11: Paso (4) - Describir el daño
**Como** ciudadano registrado,  
**quiero** escribir un título y una descripción del daño,  
**para** que la comunidad entienda el problema con detalle.

#### Criterios de aceptación
1. **Dado que** adjunté u omití las fotos (HU-10), **cuando** llego al paso 4, **entonces** veo los campos de título, descripción y dimensiones aproximadas.
2. **Dado que** dejo vacíos el título o la descripción, o escribo solo espacios, **cuando** intento continuar, **entonces** cada campo faltante muestra su error y no puedo avanzar.
3. **Dado que** escribo un título de más de 180 caracteres, **cuando** intento continuar, **entonces** veo un mensaje con el límite.
4. **Dado que** las dimensiones aproximadas son opcionales, **cuando** las dejo vacías, **entonces** puedo continuar.

---

### HU-12: Paso (5) - Confirmar y publicar el reporte
**Como** ciudadano registrado,  
**quiero** revisar un resumen y confirmar la publicación,  
**para** obtener un código público con el que pueda compartir el reporte.

#### Criterios de aceptación
1. **Dado que** completé los pasos anteriores (HU-07, HU-08, HU-10, HU-11), **cuando** llego al paso 5, **entonces** veo la ubicación, las fotos, la categoría, la gravedad, el título y la descripción, y puedo volver a cualquier paso sin perder lo ingresado.
2. **Dado que** confirmo la publicación, **cuando** se guarda correctamente, **entonces** el reporte queda en estado `REPORTED` con un código único (por ejemplo, `#VIG-8492`) que se me muestra en pantalla.
3. **Dado que** se publicó el reporte, **cuando** consulto mi perfil, **entonces** recibí **+100 XP** y quedé registrado como seguidor de mi propio reporte.
4. **Dado que** se está publicando, **cuando** toco de nuevo el botón, **entonces** no se crea un reporte duplicado (control de concurrencia y estado de carga).
5. **Dado que** falla la publicación o la subida de una foto, **cuando** se muestra el error, **entonces** conservo todo lo ingresado, puedo reintentar y no queda un reporte incompleto ni XP otorgado.

---

### HU-13: Ver los reportes en el mapa
**Como** ciudadano,  
**quiero** ver los reportes como marcadores en un mapa,  
**para** entender dónde se concentran los daños.

#### Criterios de aceptación
1. **Dado que** abro Mapa con ubicación activa, **cuando** carga, **entonces** se centra en mi posición y muestra los reportes de esa ciudad.
2. **Dado que** negué la ubicación, **cuando** abro Mapa, **entonces** se centra en `last_city` (HU-21) y veo un aviso discreto con el botón *"Activar ubicación"*.
3. **Dado que** veo los marcadores, **cuando** los comparo, **entonces** cada uno muestra un icono específico según su tipo de reporte (HU-08), sin depender solo del color.
4. **Dado que** estoy fuera de cobertura, **cuando** abro Mapa, **entonces** se mantiene `last_city` (HU-21) y veo un aviso que lo explica.

---

### HU-14: Ver el detalle de un reporte
**Como** ciudadano,  
**quiero** ver toda la información de un reporte,  
**para** evaluar el problema antes de apoyarlo o comentarlo.

#### Criterios de aceptación
1. **Dado que** toco un marcador, **cuando** se abre la tarjeta flotante, **entonces** veo el resumen y los votos del reporte, y puedo ir a su detalle.
2. **Dado que** toco un reporte en el feed (HU-19) o en el mapa (HU-13), **cuando** se abre el detalle, **entonces** veo el código, el estado, la categoría, la gravedad, el título, la descripción, las dimensiones, la dirección, las coordenadas y la fecha.
3. **Dado que** el reporte tiene fotos (HU-10), **cuando** las reviso, **entonces** puedo deslizar entre ellas; si no tiene, veo un espacio reservado con el icono de su categoría.
4. **Dado que** veo al autor, **cuando** reviso sus datos, **entonces** aparecen su nombre (o *"Ciudadano anónimo"* si decidió ocultarlo), y su rango cívico, y nunca su correo.
5. **Dado que** veo la barra de apoyo, **cuando** el reporte tiene menos de 10 votos, **entonces** se muestra el avance como *"X de 10"*, con número y barra.
6. **Dado que** falla la carga o el reporte ya no existe, **cuando** se muestra el error, **entonces** veo un mensaje claro y puedo reintentar o volver.

---

### HU-19: Ver el feed de la comunidad
**Como** ciudadano,  
**quiero** ver una lista de los reportes de mi ciudad,  
**para** conocer los problemas de mi entorno.

#### Criterios de aceptación
1. **Dado que** inicié sesión, **cuando** uso la barra de navegación inferior, **entonces** puedo moverme entre Mapa (HU-13), Comunidad y Perfil, y mi primera pantalla sigue siendo el perfil.
2. **Dado que** abro Comunidad, **cuando** cargan los datos, **entonces** veo los reportes de mi ciudad activa (HU-21), del más reciente al más antiguo, en bloques de 20 que se amplían al desplazarme (scroll infinito).
3. **Dado que** veo una tarjeta, **cuando** la reviso, **entonces** muestra foto principal, título, barrio, autor con su rango, chip de gravedad (HU-08), cantidad de votos y cantidad de comentarios.
4. **Dado que** un reporte no tiene fotos, **cuando** se muestra su tarjeta, **entonces** aparece un espacio reservado con el icono de su categoría.
5. **Dado que** deslizo hacia abajo (pull-to-refresh), **cuando** falla la actualización, **entonces** la lista anterior sigue visible y veo un aviso para reintentar.
6. **Dado que** la ciudad no tiene reportes, **cuando** carga la lista, **entonces** veo un mensaje que invita a publicar el primero (HU-06).

---

### HU-21: Cambiar de ciudad (*Smart City Switcher*)
**Como** ciudadano,  
**quiero** cambiar la ciudad que estoy consultando,  
**para** ver reportes de otros lugares sin desplazarme.

#### Criterios de aceptación
1. **Dado que** toco la ciudad en el encabezado, **cuando** se abre la hoja inferior sin haber escrito nada, **entonces** veo mis ciudades recientes (hasta 3) y accesos rápidos a Bogotá, Medellín, Cali, Barranquilla y Bucaramanga.
2. **Dado que** escribo en el buscador, **cuando** el texto coincide sin importar tildes ni mayúsculas (por ejemplo, *"bogota"*), **entonces** veo de 5 a 8 resultados como máximo, con formato `Ciudad, Departamento`.
3. **Dado que** selecciono una ciudad, **cuando** se cierra la hoja, **entonces** el mapa (HU-13) y el feed (HU-19) muestran esa ciudad.
4. **Dado que** inicié sesión y no tengo GPS activo, **cuando** selecciono una ciudad, **entonces** se actualiza `last_city` en la base de datos y la siguiente vez la app abre allí.
5. **Dado que** tengo GPS activo y consulto otra ciudad, **cuando** toco *"Centrar en mi ubicación"*, **entonces** el mapa vuelve a mi posición y `last_city` no cambia.

---

### HU-22: Explorar sin una cuenta (Modo Invitado)
**Como** visitante,  
**quiero** explorar los reportes sin registrarme,  
**para** conocer VIGÍA antes de crear una cuenta.

#### Criterios de aceptación
1. **Dado que** estoy en el inicio de sesión, **cuando** toco *"Explorar sin cuenta"*, **entonces** entro a Mapa (HU-13) y Comunidad (HU-19) sin credenciales.
2. **Dado que** soy visitante y concedí la ubicación, **cuando** entro, **entonces** veo la ciudad de cobertura más cercana; si no la concedí o estoy fuera de cobertura, se me pide elegir una ciudad (HU-21).
3. **Dado que** soy visitante, **cuando** toco *Reportar* (HU-06), *Apoyar* o *Comentar*, **entonces** se me invita a iniciar sesión o registrarme y no se ejecuta la acción.
4. **Dado que** soy visitante, **cuando** toco *Perfil*, **entonces** veo la misma invitación en lugar del panel cívico.
5. **Dado que** inicio sesión desde la invitación, **cuando** se completa, **entonces** llego a mi perfil como cualquier otro usuario.

---

## 3. Decisiones Técnicas y de Diseño del Sprint 2

### 3.1. Reordenamiento del Asistente (Decisión de UX)
- **Flujo original:** Ubicación $\rightarrow$ Fotos $\rightarrow$ Categoría $\rightarrow$ Descripción $\rightarrow$ Publicar.
- **Flujo adoptado:** **Ubicación (HU-07) $\rightarrow$ Clasificación y Severidad (HU-08) $\rightarrow$ Daños Cercanos (HU-09) $\rightarrow$ Fotos (HU-10) $\rightarrow$ Descripción (HU-11) $\rightarrow$ Confirmación (HU-12).**
- **Motivación:** Evita que el ciudadano tome fotos y espere la subida de archivos pesados antes de advertirle que el mismo daño ya fue reportado a pocos metros de distancia.

### 3.2. Reglas de Negocio Afectadas en el Sprint 2
1. **RN-01 (Integridad del Reporte):** Título (≤ 180 caracteres), descripción, categoría válida, severidad (`LOW`, `MEDIUM`, `HIGH`, `CRITICAL`), latitud, longitud, dirección y barrio obligatorios.
2. **RN-02 (Evidencia Fotográfica):** Entre 0 y 3 fotos en formato JPG, PNG o WebP, con tamaño máximo de 5 MB por archivo. Subida segura al bucket de Supabase Storage.
3. **RN-08 (XP Inicial):** Otorgamiento atómico de **+100 XP** al confirmar la publicación del reporte.
4. **RN-12 (Cobertura Geográfica):** Coordenadas validadas estrictamente dentro del Bounding Box de Colombia continental y limitadas a las ciudades de cobertura oficial DANE.
5. **RN-14 (Ubicación al inicio):** La solicitud de permisos de ubicación se ejecuta al entrar al Mapa principal, manteniendo la app 100% operativa ante denegación (fallback a `last_city`).

### 3.3. Estructura de Capas Prevista (Clean Architecture)
```
lib/features/reports/
├── domain/
│   ├── entities/ (Incident, IncidentCategory, IncidentPhoto, ProximityCheck)
│   ├── repositories/ (IncidentRepository, CategoryRepository)
│   └── usecases/ (CreateIncidentUseCase, GetNearbyIncidentsUseCase, GetCategoriesUseCase, ReverseGeocodeUseCase)
├── data/
│   ├── datasources/ (IncidentRemoteDataSource, CategoryRemoteDataSource, GeocodingDataSource)
│   ├── models/ (IncidentModel, IncidentCategoryModel)
│   └── repositories/ (IncidentRepositoryImpl, CategoryRepositoryImpl)
└── ui/
    ├── bloc/ (ReportWizardBloc, IncidentDetailBloc)
    ├── screens/ (ReportWizardScreen, IncidentDetailScreen)
    └── widgets/ (SeveritySelector, LocationPinPicker, PhotoUploadBox)

lib/features/explore/
├── domain/
│   ├── repositories/ (FeedRepository)
│   └── usecases/ (GetCityIncidentsUseCase, SwitchCityUseCase)
├── data/
│   └── repositories/ (FeedRepositoryImpl)
└── ui/
    ├── bloc/ (ExploreBloc, CitySwitcherBloc)
    ├── screens/ (HomeScreen, MapTab, FeedTab)
    └── widgets/ (IncidentCard, SmartCitySwitcherSheet, LiquidIncidentCard)
```
