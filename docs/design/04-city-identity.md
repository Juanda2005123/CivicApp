# VIGÍA: identidad por ciudad ("Ciudad Viva")

Estado: **diseño aprobado para construir** (2026-11-25). Base: rama `develop` (commit `88d0749`).
Maqueta navegable: [`mockups/city-identity.html`](mockups/city-identity.html) (Cali y Medellín, momento del día automático o manual, claro/oscuro, paleta editable y el catálogo de animaciones).
Fotos: originales en `docs/design/ideas/city-identity/photos/` con `CREDITS.json` (autor, licencia y enlace). La sesión que construye las convierte a WebP en `assets/cities/<slug>/`.
Cómo agregar otra ciudad: [`05-new-city-guide.md`](05-new-city-guide.md). Ideas que **no** se construyen ahora: [`ideas/city-identity/future-album-and-seasons.md`](ideas/city-identity/future-album-and-seasons.md).

> **Alcance: solo diseño.** Es una refactorización visual de lo que ya existe en `develop`. No se agregan funciones ni pantallas. **Cero backend:** no hay migraciones, tablas, políticas, triggers ni cambios en Supabase. Cada HU hace exactamente lo mismo que hoy; solo cambia cómo se ve y cómo se mueve. Lo único nuevo en el proyecto es del lado de la app: el paquete `lucide_icons_flutter`, la fuente Anton y las fotos en `assets/cities/` (unos 4 a 6 MB más en el APK).

> **Regla de oro.** Hay **una sola app**: las mismas pantallas, los mismos widgets y las mismas animaciones para todas las ciudades. Una ciudad es **un paquete de datos** (paleta, fotos, saludos y nombre de lugar de cada rango). Nadie escribe una pantalla "de Cali". Un `if (city == ...)` en un widget es un error: lo que cambia va en el paquete.

## 0. Decisiones de Juan (2026-11-25)
- Sin créditos de fotos dentro de la app (proyecto académico). Los créditos quedan en el repo.
- El botón principal usa el **acento cálido** de la ciudad con texto oscuro (sol en Cali, silleta en Medellín). El azul fuerte de la bandera queda solo en la franja.
- Íconos reales de **Lucide** en toda la app (§5). Nada de "+" ni emojis como ícono.
- Animaciones: 1A, 2D, 3A, 4C, 5A, 6A, 7A y 8D (§6). Son **iguales para todas las ciudades**.
- El momento del día es **automático** según la hora del teléfono (§3).
- Ciudades con paquete completo: **4** (Cali y Medellín de Juan; Bogotá y Cartagena del resto del equipo). Las demás usan el paquete regional o el por defecto.

---

## 1. Qué cambia y qué no

| Igual en todas las ciudades | Cambia por ciudad (paquete) |
|---|---|
| Funciones, pantallas, navegación (3 pestañas: Mapa, Comunidad, Mi perfil) | Paleta: acento (botones), tono profundo (chips, enlaces), velo de fotos |
| Sello, anillo punteado, datos en monoespaciada | Franja de la bandera |
| Tipografías (Fraunces, IBM Plex Sans/Mono) + titular de ciudad en **Anton** | Fotos reales de cabecera: mañana, tarde, noche |
| Reglas de XP, validación (10 apoyos) y los 4 rangos | Nombre de lugar y foto de cada rango (la "subida") |
| Íconos Lucide y todas las animaciones | Saludos según la hora y frase de validación |
| Superficies papel/tinta, colores de gravedad y de error | Foto de la ciudad en el registro y en el cambio de ciudad |

Niveles de paquete:
- **Completo** (4): Cali, Medellín, Bogotá, Cartagena.
- **Regional** (las demás ciudades del catálogo DANE): foto de la ciudad o de su región, franja de la bandera municipal, paleta de la región (Caribe, Pacífico, Andina, Llanos, Amazonía, Insular) y los nombres de rango genéricos. Barranquilla entra aquí (Caribe). Responsable: por asignar.
- **Por defecto**: si no hay paquete, la app se ve exactamente como hoy (Sello comunitario).

## 2. Dónde vive cada cosa (Clean Architecture, `AGENTS.md` §4)

```
lib/features/city_identity/
├── domain/
│   ├── entities/
│   │   ├── city_identity.dart      # slug, level (full|regional|fallback), palette, heroes, landmarks, copy
│   │   ├── city_palette.dart       # colores como int ARGB (0xFFF08A24): el dominio no importa Flutter
│   │   ├── city_photo.dart         # assetPath + descripción (texto alternativo)
│   │   ├── landmark.dart           # rankName (une con civic_rank.name), title, photo
│   │   ├── city_copy.dart          # saludo por DayPart, eslogan, frase de validación
│   │   └── day_part.dart           # enum DayPart { morning, afternoon, night } + DayPart.of(DateTime)
│   ├── repositories/city_identity_repository.dart   # identityFor(cityName, department)
│   └── usecases/get_city_identity_usecase.dart      # completo → regional → por defecto (nunca falla)
├── data/
│   ├── datasources/
│   │   ├── city_pack_local_data_source.dart    # registro de paquetes (const, sin red)
│   │   ├── packs/default_pack.dart             # la app de hoy
│   │   ├── packs/cali_pack.dart                # UN archivo por ciudad completa
│   │   ├── packs/medellin_pack.dart
│   │   └── packs/regional_packs.dart           # regiones + mapa departamento → región
│   └── repositories/city_identity_repository_impl.dart
└── ui/bloc/city_ambience_bloc.dart (+ _event, _state)   # app-wide: identity + dayPart

lib/core/theme/
├── city_theme.dart        # CityTheme extends ThemeExtension<CityTheme>
└── app_theme.dart         # AppTheme.build(Brightness, CityTheme) reemplaza los dos ThemeData fijos

lib/core/widgets/city/     # leen CityTheme.of(context), NUNCA el nombre de la ciudad
├── city_hero.dart          # foto por DayPart + velo + saludo
├── flag_stripe.dart        # franjas de la bandera
├── landmark_trail.dart     # la "subida": 4 rangos con foto, posición del usuario
├── celebration_overlay.dart# reporte validado (3A) y nuevo rango (4C)
├── city_skeleton.dart      # esqueletos con brillo (8D)
└── city_motion.dart        # press, ruta con eje compartido, helpers de animación (§6)
```

Por qué así:
- **Agregar una ciudad** = `packs/<slug>_pack.dart` + `assets/cities/<slug>/` + una línea en el registro. Cero widgets nuevos y cero cambios en la base de datos.
- Las pantallas de hoy no cambian de estructura: los colores llegan por el `ColorScheme` (recoloreado por la ciudad) y lo nuevo (foto, bandera, nombres de lugar) por `CityTheme`. Es el mismo patrón de `AppSemanticColors` y `AppSeverityColors`.
- El dominio sigue puro: colores como `int`, fotos como rutas `String`. La traducción a `Color` y `AssetImage` ocurre en `CityTheme.from(...)`.

## 3. Flujo en tiempo de ejecución
1. `main.dart`: `MultiBlocProvider` con `ThemeCubit` y `CityAmbienceBloc` por encima de `MaterialApp` (excepción documentada en `AGENTS.md` §5).
2. `theme: AppTheme.build(Brightness.light, cityTheme)`, `darkTheme: AppTheme.build(Brightness.dark, cityTheme)`, con `cityTheme = CityTheme.from(state.identity, brightness, state.dayPart)`.
3. **Qué ciudad manda:** la que se está explorando (`MapBloc.state.city`, la misma que el `HomeScreen` ya reenvía al `FeedBloc`); el shell agrega `ActiveCityChanged(city)` en ese mismo lugar. Antes de iniciar sesión: la ciudad detectada en el registro.
4. **La subida del perfil** usa la ciudad de referencia del usuario (`reference_city`): tus rangos llevan los lugares de tu ciudad aunque mires otra.
5. **Momento del día automático:** `DayPart.of(DateTime.now())` al abrir la app y cada vez que vuelve a primer plano (`AppLifecycleState.resumed`). Mañana 05:00–11:59, tarde 12:00–18:29, noche 18:30–04:59. Cambia la foto de cabecera y el saludo.

### 3.1 Contrato de `CityTheme`
```dart
final city = CityTheme.of(context);   // nunca null: el paquete por defecto llena todo
city.slug;  city.displayName;  city.level;
city.hero;                 // ImageProvider de la foto del DayPart actual
city.flag;                 // List<FlagBand(color, weight)>
city.accent / onAccent;    // botones principales, FAB, "TÚ", barra de apoyos, confeti
city.deep / onDeep;        // chips activos, enlaces, etiquetas
city.veil;                 // velo sobre fotos (texto blanco AA)
city.landmarks;            // 4, en orden de min_xp
city.copy.greeting;        // según DayPart
```

### 3.2 Recoloreo del `ColorScheme`
| Rol | Claro | Oscuro | Se usa en |
|---|---|---|---|
| `primary` / `onPrimary` | `accent` / `onAccent` | igual | botones principales (`FilledButton`), FAB "Reportar", barra de apoyos, "TÚ" |
| `secondary` / `onSecondary` | `deep` / blanco | `accent` / `onAccent` | chips activos, enlaces, etiquetas, indicador de la barra inferior |
| superficies, texto, errores, gravedad | **sin cambio** | sin cambio | todo lo demás |

Cada `deep` debe pasar 4.5:1 con blanco y cada `accent` 4.5:1 con su `onAccent` (prueba unitaria, §7). En el paquete por defecto `accent` = mostaza y `deep` = tinta.

### 3.3 Paquetes de Juan
| | Cali | Medellín |
|---|---|---|
| deep (tono profundo) | `#1B4B5F` azul petróleo | `#0E6B3F` verde bandera |
| accent / onAccent (botones) | `#F08A24` sol de los Farallones / `#1B1205` | `#F4B400` silleta / `#1A1400` |
| velo | `#0B2433` | `#0B2A1E` |
| bandera (arriba a abajo, peso) | azul 3, rojo 1, blanco 3, rojo 1, verde 3 (confirmar con la Alcaldía) | blanco 1, verde 1 |
| cabeceras: mañana / tarde / noche | Centro desde Cristo Rey / Cerro de las Tres Cruces / el oeste de noche | Desde El Picacho / Metrocable / Medellín de noche |
| rangos 0 / 1.000 / 2.500 / 4.000 XP | Gato del Río · La Ermita · Cristo Rey · Cerro de las Tres Cruces | Comuna 13 · Plaza Botero · Metrocable · Pueblito Paisa |
| saludo mañana / tarde / noche | "¡Buenos días, ve!" / "¡Qué más, ve!" / "¡Buenas noches, ve!" | "¡Buenos días, parce!" / "¡Quiubo, parce!" / "¡Buenas noches, parce!" |
| eslogan | "Cali se cuida entre vecinos." | "Medellín se cuida entre vecinos." |
| frase al validar | "¡Eso, ve!" | "¡Qué chimba, parce!" |

El nombre del rango de siempre (Observador Urbano, Vecino Activo, Guardián Vial, Veedor Mayor) se conserva como subtítulo.

## 4. Recursos
- `assets/cities/<slug>/hero_morning.webp`, `hero_afternoon.webp`, `hero_night.webp` (1080 px de ancho, < 200 KB) y `rank_1.webp` … `rank_4.webp` (480 px cuadradas).
- Wikimedia Commons con licencia CC0, dominio público, CC BY o CC BY-SA. No se muestran créditos en la app; quedan en `assets/cities/CREDITS.md`.
- Fuente nueva: Anton (OFL) en `assets/fonts/`, solo para titulares de ciudad.

## 5. Íconos: Lucide
- Paquete `lucide_icons_flutter` (aprobado en `AGENTS.md` §3; revisar la última versión estable al agregarlo). Reemplaza los `Icons.*` de Material en **toda** la app. Grosor visual ~1,9, tamaño 24 dp.

| Uso | Ícono |
|---|---|
| Barra inferior: Mapa, Comunidad, Mi perfil | `map`, `users-round`, `circle-user-round` (el activo dentro de una pastilla del acento al 38 %) |
| Reportar (FAB y wizard) | `map-pin-plus` |
| Apoyar / apoyos | `thumbs-up` |
| Comentarios | `message-circle` |
| Dirección, ubicación, GPS | `map-pin`, `locate-fixed` |
| Volver, ir | `arrow-left`, `chevron-right` |
| Foto vacía, galería, cámara | `image`, `images`, `camera` |
| Validado | `badge-check` |
| Ajustes, privacidad, permisos, salir | `settings`, `eye-off`, `shield-check`, `log-out` |
| Buscar, filtrar, ordenar | `search`, `sliders-horizontal`, `arrow-up-down` |
| Editar, eliminar | `pencil`, `trash-2` |

Los íconos de **gravedad** siguen siendo las formas propias del sistema de diseño (círculo, triángulo, rombo, octágono).

## 6. Movimiento (igual en toda la app y en todas las ciudades)

| Momento | Elección | Cómo se ve |
|---|---|---|
| 1. Tocar botones y tarjetas | 1A Sello que se hunde | escala 0,96 y vuelve, 120 ms |
| 2. Apoyar | 2D Combinada | el pulgar salta, sube un "+1" y la barra de validación crece; el anillo punteado alrededor del pulgar avanza una décima y late |
| 3. Reporte validado (ya existe, HU-16) | 3A Sello y confeti | el sello cae girando y rebota, sale una onda y confeti con la bandera; se cierra al tocar o a los 2,5 s |
| 4. Nuevo rango (ya existe, RN-09) | 4C Foto a pantalla completa | la foto del lugar se abre en círculo desde su medalla, con nombre y XP; se cierra al tocar o a los 2,6 s |
| 5. Cambio de pantalla | 5A Eje compartido | sale 24 px a la izquierda con fundido, entra desde 30 px a la derecha |
| 6. Cabecera | 6A Zoom lento | escala 1 → 1,1 en 20 s, ida y vuelta |
| 7. Cambio de ciudad (ya existe, HU-21) | 7A Cortina con la bandera | las franjas de la ciudad nueva barren la pantalla y se retiran |
| 8. Cargando | 8D Según el caso | ver abajo |

(En la maqueta el catálogo está numerado así. En el mensaje anterior se llamaban 6A, 7A, 8A y 9D porque existía la animación del álbum.)

**Cargando (8D), para que la app siga rápida:**
- **Esqueletos con brillo** solo la *primera* vez que se abre una lista o pantalla sin datos (feed, perfil, detalle, Mis reportes), con la forma real de la tarjeta.
- **Anillo punteado** (`DottedSpinner`, en el acento) **dentro del botón** que se tocó, en acciones cortas: publicar, comentar, apoyar, guardar, cambiar de ciudad. El botón queda deshabilitado mientras tanto.
- **Nada** en recargas (pull-to-refresh usa su indicador) ni cuando ya hay datos en pantalla; si algo tarda menos de 300 ms no se muestra indicador.
- Rendimiento: WebP < 200 KB con `cacheWidth`, `precacheImage` de la cabecera al cambiar de ciudad, un solo `AnimationController` para el zoom que se pausa fuera de pantalla, y confeti con un `CustomPainter`.

Tokens nuevos en `AppMotion`: `reveal` 600 ms, `celebration` 1.400 ms, `ambient` 20 s y `curveStamp` = `Cubic(0.3, 1.4, 0.5, 1)`, junto a los que ya existen (`micro` 120, `standard` 200, `emphasized` 320, `curve`). Un solo helper por patrón en `city_motion.dart`. Con `AppMotion.reduceOf(context)` todo pasa a **fundido de 100 ms**, sin escala, rotación ni confeti, y la cabecera queda quieta.

## 7. Todas las pantallas de `develop` y qué les pasa
Ninguna función cambia. Las que no están en la maqueta reciben el tratamiento común: íconos Lucide, botón principal en el acento, chips y enlaces en el tono profundo, carga según 8D, transición 5A y presión 1A.

| Pantalla / pieza (HU) | Archivo | Qué cambia | ¿En la maqueta? |
|---|---|---|---|
| Splash | `auth/ui/screens/splash_screen.dart` | Sigue en tinta con el sello; debajo, la franja de la bandera de la última ciudad | No |
| Login | `auth/.../login_screen.dart` | Tratamiento común; cabecera corta con la foto de la ciudad | No |
| Registro (3 pasos) | `auth/.../register_screen.dart` | Paso ciudad con tarjetas con foto de las 4 ciudades completas; las demás en la lista con buscador de siempre | Sí (paso ciudad) |
| Shell y barra inferior (HU-19, HU-22) | `explore/ui/screens/home_screen.dart` | 3 pestañas con íconos Lucide; avisa `ActiveCityChanged`; invitado igual que hoy | Sí |
| Mapa (HU-13) | `explore/ui/pages/map_page.dart` | FAB "Reportar" en el acento con `map-pin-plus`; marcadores de gravedad iguales | No |
| Cambio de ciudad (HU-21) | `city_switcher_sheet.dart` | Filas con miniatura de la ciudad; al cambiar, cortina 7A | No (la animación sí) |
| Comunidad (HU-19) | `explore/ui/pages/feed_page.dart` | `CityHero` con saludo según la hora arriba de la lista | Sí |
| Buscar, filtrar, ordenar (HU-20) | `feed_filter_bar.dart`, `choice_sheet.dart` | Igual; chips activos en el tono profundo; íconos Lucide | Parcial |
| Tarjeta del feed | `feed_incident_card.dart` | Contadores con `thumbs-up` y `message-circle`; presión 1A | Sí |
| Wizard de reporte (HU-06 a 12, 27, 28) | `report_wizard_screen.dart` | Barra de pasos en el acento; al publicar, anillo en el botón | No |
| Reportes cercanos | `nearby_incidents_modal.dart` | Tratamiento común | No |
| Detalle (HU-14, 15, 16) | `incident_detail_screen.dart` | Apoyar con 2D; al llegar a 10, celebración 3A; vista del autor sin botón, igual que hoy | Sí |
| Comentarios (HU-17) | `incident_comments_section.dart` | "Publicar" con anillo | No |
| Editar / eliminar (HU-18) | `edit_report_screen.dart`, `author_actions_card.dart` | Íconos `pencil`, `trash-2` | No |
| Mi perfil (HU-23, HU-05) | `dashboard/ui/pages/profile_page.dart` | `RankProgressCard` → `LandmarkTrail`, misma información; 4C al subir de rango; contadores y "Mis reportes" se quedan | Sí (subida) |
| Ajustes, privacidad, permisos, datos personales (HU-01, 02, 04) | `profile_settings_screen.dart`, `permissions_screen.dart`, `edit_profile_screen.dart` | Tratamiento común | No |
| Diálogos | `core/widgets/*_dialog.dart` | Tratamiento común | No |
| HU-24 y HU-25 (Julio) | por construir | Usan los widgets nuevos si arrancan después del paso 3 de §8 | No |

## 8. Orden de construcción
1. Dominio de `city_identity` + pruebas.
2. Datos: `default_pack`, `cali_pack`, `medellin_pack`, regionales vacíos; registro; repositorio.
3. `CityTheme` + `AppTheme.build` + `CityAmbienceBloc` en `main.dart`. Con el paquete por defecto la app debe verse **igual que hoy** (prueba de regresión).
4. Lucide + widgets de `core/widgets/city/` + `city_motion.dart`.
5. Pantallas en el orden de §7.
6. `assets/cities/CREDITS.md`, `03-design-system.md`, mockups y capturas en claro y oscuro de Cali y Medellín.

Pruebas mínimas: `DayPart.of`, `GetCityIdentityUseCase` (completo → regional → por defecto, nombres con tilde), contraste AA de cada paleta, `CityAmbienceBloc` (cambio de ciudad, vuelve a primer plano), y widget tests de `CityHero`, `LandmarkTrail` y `CelebrationOverlay` con Cali, Medellín y por defecto, claro y oscuro, y con animaciones desactivadas. `dart run tool/check.dart` en verde.

## 9. Reparto
- **Juan:** arquitectura (pasos 1–4), paquetes de Cali y Medellín, todo en una rama propia y documentado.
- **Cano y Juan David:** Bogotá y Cartagena, siguiendo [`05-new-city-guide.md`](05-new-city-guide.md) (maqueta primero).
- **Paquete regional:** por asignar.
- **Julio:** HU-25 (migración 010) y HU-24 (011).
