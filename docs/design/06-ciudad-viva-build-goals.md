# Ciudad Viva: objetivos de la construcción (definición de terminado)

Para la sesión de Claude que programa el rediseño. Trabaja **de corrido, sin detenerte a preguntar**, salvo en los casos de §4. Termina cuando todas las casillas de §2 estén cumplidas y verificadas, o cuando quede solo lo que §4 manda a preguntar.

Fuentes, en este orden:
1. `AGENTS.md`: todas las reglas de código siguen iguales (Clean Architecture, Bloc, GetIt, pruebas, checklist). El rediseño solo agregó la librería Lucide (§3), la excepción de `CityAmbienceBloc` (§5) y las reglas 4 y 10 de §6b.
2. [`04-city-identity.md`](04-city-identity.md): arquitectura, paletas, íconos, animaciones y tabla de pantallas.
3. Maqueta [`mockups/city-identity.html`](mockups/city-identity.html): valores exactos de Cali y Medellín (`PACKS`) y cómo se ve y se mueve cada cosa.
4. [`05-new-city-guide.md`](05-new-city-guide.md): para que el paquete quede fácil de copiar por Cano y Juan David.

## 1. Alcance
- **Solo diseño. Cero backend:** no se toca `data model/`, migraciones, SQL, políticas, triggers ni Supabase. No cambia ninguna regla de negocio ni ninguna HU.
- Blocs y casos de uso existentes: no se cambia su lógica. Si una pantalla necesita un dato de presentación (por ejemplo, el rango anterior para disparar la celebración 4C), se calcula en la capa de UI o con un campo nuevo de estado que no altere lo que ya emiten.
- Ciudades: **Cali y Medellín completas**. Paquete **por defecto** = la app de hoy. Paquete **regional**: solo la estructura (mapa departamento → región y el tipo de dato) cayendo al visual por defecto; el diseño regional lo hace otra persona.
- **No** construir Bogotá ni Cartagena (son de Cano y Juan David), ni el álbum, las temporadas o las misiones (`ideas/city-identity/future-album-and-seasons.md`).

## 2. Objetivos (todo verificable)
- [ ] **Arquitectura** como `04-city-identity.md` §2 y §3: feature `lib/features/city_identity/` (dominio puro, datos, `CityAmbienceBloc`), `CityTheme` como `ThemeExtension`, `AppTheme.build(Brightness, CityTheme)`, `CityAmbienceBloc` sobre `MaterialApp`, `ActiveCityChanged` desde el `HomeScreen` donde hoy se reenvía la ciudad al `FeedBloc`, y la subida del perfil con `reference_city`.
- [ ] **Momento del día automático**: `DayPart.of` (05:00–11:59, 12:00–18:29, 18:30–04:59), recalculado al abrir y al volver a primer plano.
- [ ] **Regresión**: con el paquete por defecto, `AppTheme.build` produce los mismos `ColorScheme` y extensiones de hoy (prueba que lo compare).
- [ ] **Paquetes de Cali y Medellín** con los valores de la maqueta y de `04` §3.3, incluido "Cerro de las Tres Cruces". Fotos convertidas a WebP (1080 px de ancho para cabeceras, 480 px cuadradas para rangos, < 200 KB) en `assets/cities/cali/` y `assets/cities/medellin/` desde `docs/design/ideas/city-identity/photos/`, y `assets/cities/CREDITS.md` generado desde `CREDITS.json` (solo las fotos usadas).
- [ ] **Lucide** (`lucide_icons_flutter`) en toda la app según `04` §5. `grep -rn "Icons\." lib` solo puede devolver casos justificados y listados en el reporte final.
- [ ] **Fuente Anton** en `assets/fonts/` con su licencia OFL en `assets/fonts/licenses/`, usada solo en titulares de ciudad.
- [ ] **Widgets** de `core/widgets/city/` (`CityHero`, `FlagStripe`, `LandmarkTrail`, `CelebrationOverlay`, `CitySkeleton`, `city_motion.dart`), solo con tokens y con su prueba de widget.
- [ ] **Animaciones 1A, 2D, 3A, 4C, 5A, 6A, 7A y 8D** exactamente como `04` §6 y la maqueta, con los tokens nuevos de `AppMotion`. Con `MediaQuery.disableAnimations` todo pasa a fundido de 100 ms, sin escala, giro ni confeti (probado).
- [ ] **Las 18 filas de `04` §7** rediseñadas. Ninguna función perdida: las pruebas existentes siguen pasando sin cambiar lo que verifican (solo se actualizan buscadores de widgets o íconos si cambió el ícono).
- [ ] **Contraste**: prueba unitaria que recorre todos los paquetes registrados y exige 4.5:1 (`deep` con blanco, `accent` con `onAccent`).
- [ ] **Rendimiento**: `cacheWidth` en las fotos, `precacheImage` de la cabecera al cambiar de ciudad, un solo controlador para el zoom lento (pausado fuera de pantalla), confeti con `CustomPainter`, ningún indicador de carga en operaciones de menos de 300 ms.
- [ ] **`dart run tool/check.dart` en verde** (guardas + `flutter analyze` + `flutter test`), con el resultado real en el reporte.
- [ ] **Capturas** de la app real (build web en Chrome): Registro (paso ciudad), Comunidad, Detalle y Mapa, en Cali y Medellín, claro y oscuro, en `docs/design/screenshots/ciudad-viva/`. Usa el modo invitado. Mi perfil necesita sesión: no escribas contraseñas; deja esas capturas para Juan o usa una prueba de widget que genere la imagen.
- [ ] **Documentación**: `03-design-system.md` (tabla de componentes con los widgets nuevos, tokens de movimiento, íconos), `04-city-identity.md` marcado "implementado" con lo que haya cambiado, y la plantilla de `05-new-city-guide.md` comprobada (copiar `cali_pack.dart` debe bastar).

## 3. Forma de trabajar
- Orden de `04` §8. Commits pequeños en tu rama, en Conventional Commits en inglés (`feat(city-identity): ...`), **sin** líneas `Co-Authored-By` ni "Generated with Claude Code". No hagas push, merge ni PR: eso lo decide Juan.
- Si `develop` avanza (Julio está terminando HU-24 y HU-25 con las migraciones 010 y 011), integra `develop` en tu rama con merge, nunca con rebase de algo publicado. Los archivos que más pueden chocar: `incident_detail_screen.dart`, `profile_page.dart`, `home_screen.dart`, `main.dart` y `injection_container.dart`. Mantén esos cambios enfocados.
- Si la build web necesita servidor, usa el puerto 8124 como en las pruebas anteriores.

## 4. Cuándo sí parar y preguntarle a Juan
- Algo exigiría tocar backend, cambiar una regla de negocio o quitar una función.
- Hace falta un paquete de pub distinto de `lucide_icons_flutter`.
- Una regla de `AGENTS.md` choca con este documento.
- Hay que iniciar sesión con contraseña, hacer push o abrir un PR.

## 5. Reporte final
Qué se hizo, por objetivo de §2 (cumplido / pendiente y por qué), la salida real de `tool/check.dart`, la lista de commits, dónde están las capturas, los usos de `Icons.` que quedaron y lo que falta para que Cano y Juan David agreguen Bogotá y Cartagena.
