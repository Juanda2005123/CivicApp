# VIGÍA: sistema de diseño, dirección E "Sello comunitario"

Rama: `design/design-system-proposal`. Estado: **implementado** en la app (tokens, tema claro y oscuro, widgets compartidos, splash, login, registro, resumen del perfil, ícono y splash nativo). Pendiente: la prueba en dispositivo. El sello de validación llegó con HU-16.

Maquetas navegables (se abren en cualquier navegador, son archivos autónomos):
- [`mockups/screens.html`](mockups/screens.html): splash, login (claro, oscuro, errores), registro (vacío, con errores, completo), resumen del perfil (claro, oscuro, error de carga).
- [`mockups/components.html`](mockups/components.html): color, tipografía, botones, campos, avisos, gravedad, rangos y vista previa de feed, mapa y sello de validación.
- [`mockups/tokens.css`](mockups/tokens.css): los tokens en CSS. `node mockups/build.mjs` regenera los HTML autónomos tras editarlo.
- [`assets/logo/`](assets/logo/): sello y variantes en SVG.

> **Actualización 2026-11-25: identidad por ciudad (implementada).** Sobre este sistema se monta la capa "Ciudad Viva" ([`04-city-identity.md`](04-city-identity.md)): fotos reales de cada ciudad, la franja de su bandera, colores de ciudad (recolorean `primary` y `secondary`) y un catálogo de animaciones único. Donde este documento dice "sin fotos" o "sin texto sobre fotos" (§6, §9, §11), manda ahora el 04: fotos solo a través de los widgets de `core/widgets/city/` y siempre con velo para contraste AA. La marca (sello, anillo punteado, datos en monoespaciada, superficies papel/tinta, colores de gravedad y de error) no cambia. Los créditos de las fotos están en `assets/cities/CREDITS.md`; la app no los muestra.

Antecedentes: `01-identity-directions.md` y `02-blend-b-c-directions.md` (cómo se llegó a la dirección E). Reglas de arquitectura que este sistema respeta: `AGENTS.md` (§4 capas, §6 UI, §6b diseño).

---

## 1. Idea central

VIGÍA es una veeduría hecha entre vecinos y respaldada por evidencia. La marca es un **sello**: el objeto que se estampa para dar fe de algo. Un sello comunitario que valida un reporte cuando suficientes vecinos lo respaldan (10 votos, RN-08) es a la vez el logo, la insignia de rango y el sello de "Reporte validado". Un solo lenguaje visual para identidad, gamificación y confianza.

Tres rasgos que se repiten en todo el sistema:

1. **Anillo punteado**: la perforación del sello y la marca de agua de las pantallas.
2. **Calidez de papel**: fondo crema, tinta azul verdosa, acentos de arcilla y mostaza. Se siente humano, no tecnológico.
3. **Datos de registro**: códigos, coordenadas, fechas y puntos en fuente monoespaciada, como en un expediente (`#VIG-8492`).

**Personalidad:** seria sin ser burocrática, cercana sin ser infantil, firme pero constructiva. Nunca grita; certifica.

**Voz:** español colombiano neutro, tuteo ("tú"), frases cortas y verbos directos ("Escribe tu correo", "Elige tu ciudad"). Sin diminutivos, sin signos de exclamación salvo en logros, sin tecnicismos. Se nombra lo que pasó y qué hacer ("Sin conexión. Revisa tu internet e inténtalo de nuevo.").

**Lema recomendado:** *Tu voz, con evidencia.* Alternativas: *Mira la vía. Deja constancia.* / *Lo que ves, queda registrado.*

## 2. Logo

| Archivo | Uso |
|---|---|
| `assets/logo/vigia-seal.svg` | Sello principal (color). Splash, login, encabezados, redes. |
| `assets/logo/vigia-seal-min.svg` | Tamaños de 16 a 24 px (favicon, notificaciones, chips). Sin anillo ni puntos: la V sola. |
| `assets/logo/vigia-seal-mono-ink.svg` | Una tinta sobre fondo claro (sellos de goma, impresos, fax). |
| `assets/logo/vigia-seal-mono-cream.svg` | Una tinta crema sobre fondo oscuro. |
| `assets/logo/vigia-app-icon.svg` | Ícono de app 1024 px a sangre (iOS y Play; el sistema recorta las esquinas). |
| `assets/logo/vigia-app-icon-adaptive-foreground.svg` | Primer plano del ícono adaptable de Android (108 dp), con fondo sólido `#10364A` aparte. |

**Construcción:** círculo de tinta; anillo punteado crema (perforación); una **V** de VIGÍA en crema; un punto de mostaza arriba y uno de arcilla abajo, que son los dos acentos de la marca. Evita deliberadamente el ojo genérico, el escudo y el pin de mapa de stock.

**Lockup:** sello a la izquierda + **VIGÍA** en Fraunces 700 con 0,06 em de espaciado; altura de la palabra igual al 40 % del diámetro del sello; separación igual al radio de los puntos × 4. Se entrega como texto en las maquetas; al exportar para impresión conviene convertirlo a contornos.

**Zona de seguridad:** un cuarto del diámetro del sello alrededor. **Tamaños mínimos:** sello completo 32 px; versión mínima 16 px. **No:** cambiar los colores de los puntos, girar, estirar, poner sobre fotos sin una base sólida, ni usar la versión crema sobre fondos claros.

## 3. Color

### 3.1 Paleta base

| Token de marca | Hex | Uso principal |
|---|---|---|
| Tinta | `#10364A` | Texto, botón primario, sello |
| Tinta profunda | `#0B2433` | Fondo en modo oscuro |
| Tinta elevada | `#17455C` | Superficies elevadas en modo oscuro |
| Crema | `#F6EFE0` | Fondo en modo claro |
| Papel | `#FFFBF2` | Tarjetas y campos en modo claro |
| Arcilla 500 | `#CF5C3F` | Solo gráficos y texto grande (3,49:1 sobre crema) |
| Arcilla 700 | `#A8432A` | Enlaces, acentos de texto, iconos, foco (5,24:1 sobre crema) |
| Arcilla 300 | `#EE8C6E` | Enlaces en modo oscuro |
| Mostaza | `#E8B03A` | Botón primario en oscuro, resaltes. Siempre con texto tinta; **nunca sola sobre crema** (1,71:1) |
| Salvia 700 | `#4F7A5A` | Rango nivel 2 |
| Grafito | `#55606B` | Texto secundario |

### 3.2 Tokens semánticos (los que usa el código)

| Token | Claro | Oscuro |
|---|---|---|
| `background` | `#F6EFE0` | `#0B2433` |
| `surface` (tarjetas, campos) | `#FFFBF2` | `#10364A` |
| `surfaceRaised` | `#FFFFFF` | `#17455C` |
| `onSurface` (texto) | `#10364A` | `#F6EFE0` |
| `onSurfaceVariant` (secundario) | `#55606B` | `#B8C4C9` |
| `primary` / `onPrimary` | `#10364A` / `#F6EFE0` | `#E8B03A` / `#0B2433` |
| `link` / `accent` | `#A8432A` | `#EE8C6E` / `#E8B03A` |
| `outline` (borde de campo) | `#7A6F5C` | `#6F8F9E` |
| `divider` | `#D9CFBB` | `#26516A` |
| `focus` | `#A8432A` | `#E8B03A` |
| `success` / `successBg` | `#1F6B4A` / `#E3EFE3` | `#6FCB9F` / `#123F36` |
| `error` / `errorBg` | `#A3261B` / `#F8E3DE` | `#FF9C8F` / `#4A2026` |
| `info` / `infoBg` | `#1F5F85` / `#E0ECF2` | `#8CC3E3` / `#17455C` |
| `warning` / `warningBg` | `#8A5A00` / `#F8ECCB` | `#F2C66A` / `#4A3A12` |

### 3.3 Gravedad (Low, Medium, High, Critical)

Cada nivel tiene **color, forma y texto**; nunca solo color (daltonismo, sol directo).

| Nivel | Texto | Forma | Fondo del chip | Texto del chip | Contraste |
|---|---|---|---|---|---|
| Low | Baja | círculo | `#266A70` | blanco | 6,22:1 |
| Medium | Media | triángulo | `#E8B03A` | tinta | 6,49:1 |
| High | Alta | rombo | `#C2410C` | blanco | 5,18:1 |
| Critical | Crítica | octágono (como señal de pare) | `#8F1D2C` | blanco | 8,82:1 |

En oscuro se aclaran (`#3E9AA2`, mostaza, `#F08A57`, `#E56B7B`) con texto muy oscuro. Regla: la **arcilla de marca no se usa como fondo de chip de gravedad**; para evitar confusión con "Alta", los acentos de marca solo van en botones, enlaces y sellos.

### 3.4 Rangos (RN-09)

Un sello por nivel, con numeral Fraunces: **1 Observador Urbano** (tinta, anillo punteado), **2 Vecino Activo** (salvia), **3 Guardián Vial** (mostaza, anillo liso de tinta), **4 Veedor Mayor** (arcilla 700, doble anillo). Progresión: más llenos y más "oficiales" a mayor nivel. En oscuro, el nivel 1 lleva contorno crema.

### 3.5 Contrastes calculados (WCAG 2.1)

Calculados con la fórmula de luminancia relativa del estándar (script reproducible en la sección 9).

| Par | Relación | Cumple |
|---|---|---|
| Tinta sobre crema (texto) | 11,13:1 | AAA |
| Tinta sobre papel (texto en tarjeta) | 12,33:1 | AAA |
| Grafito sobre crema (secundario) | 5,61:1 | AA |
| Crema sobre tinta (botón primario) | 11,13:1 | AAA |
| Arcilla 700 sobre crema (enlace) | 5,24:1 | AA |
| Arcilla 700 sobre papel | 5,81:1 | AA |
| Blanco sobre arcilla 700 (botón destructivo/sello) | 6,00:1 | AA |
| Blanco sobre arcilla 500 | 4,00:1 | Solo texto grande |
| Arcilla 500 sobre crema | 3,49:1 | Solo gráficos y texto grande |
| Tinta sobre mostaza | 6,49:1 | AA |
| Mostaza sobre crema | 1,71:1 | **No usar** |
| Borde de campo `#7A6F5C` sobre papel | 4,78:1 | ≥ 3:1 (componente) |
| Éxito `#1F6B4A` / error `#A3261B` / info `#1F5F85` / aviso `#8A5A00` sobre crema | 5,63 / 6,43 / 6,05 / 5,18 | AA |
| Oscuro: crema sobre `#0B2433` / sobre `#10364A` / sobre `#17455C` | 13,95 / 11,13 / 8,98 | AAA |
| Oscuro: secundario `#B8C4C9` sobre `#10364A` | 7,14:1 | AAA |
| Oscuro: tinta profunda sobre mostaza (botón) | 8,14:1 | AAA |
| Oscuro: enlace `#EE8C6E` sobre `#10364A` | 5,22:1 | AA |
| Oscuro: borde `#6F8F9E` sobre `#10364A` | 3,70:1 | ≥ 3:1 |
| Oscuro: éxito / error sobre `#10364A` | 6,50 / 6,31 | AA |

Los divisores y las superficies decorativas (1,25 a 1,35:1) no transmiten información por sí solos, así que no se exige contraste.

### 3.6 Color de ciudad

Con un paquete de ciudad, `AppTheme.build(brightness, cityTheme)` cambia solo estos roles. Sin paquete (look por defecto) el esquema es el de §3.2, sin cambios.

| Rol | Claro | Oscuro | Dónde |
|---|---|---|---|
| `primary` / `onPrimary` (y sus `Container`) | acento de la ciudad / su texto | igual | botones principales, "Reportar daño", barra de apoyos, "TÚ", confeti |
| `secondary` / `onSecondary` (y sus `Container`), acento semántico | tono profundo / blanco | acento / su texto | enlaces, chips activos, foco, sellos, controles seleccionados |
| `CityTheme.deep` | tono profundo | acento | íconos y textos destacados sobre el fondo (en el look por defecto es `primary`) |
| `CityTheme.veil` / `onVeil` | velo oscuro / blanco | igual | texto sobre fotos, celebraciones |

Superficies, texto, errores y gravedad son iguales en todas las ciudades. Cada paquete pasa 4,5:1 en blanco sobre `deep`, `onAccent` sobre `accent` y blanco sobre el velo (`test/unit/core/city_theme_test.dart` recorre todos). El acento **no se usa como texto ni ícono sobre papel claro** (el sol de Cali da 2,2:1 sobre crema y la silleta de Medellín menos): ahí va `deep`.

| Ciudad | `deep` | `accent` / `onAccent` | `veil` | Bandera (peso) |
|---|---|---|---|---|
| Cali | `#1B4B5F` | `#F08A24` / `#1B1205` | `#0B2433` | `#1D3E9E` 3, `#C8202F` 1, blanco 3, `#C8202F` 1, `#1C7C43` 3 |
| Medellín | `#0E6B3F` | `#F4B400` / `#1A1400` | `#0B2A1E` | blanco 1, `#0E6B3F` 1 |

## 4. Tipografía

| Rol | Familia | Peso | Tamaño / interlineado | Mapeo `TextTheme` |
|---|---|---|---|---|
| Display (marca, grandes titulares) | Fraunces | 700 | 32 / 40, +0,02 em | `displaySmall` |
| Headline | Fraunces | 600 | 24 / 32 | `headlineSmall` |
| Title | IBM Plex Sans | 600 | 18 / 26 | `titleMedium` |
| Body | IBM Plex Sans | 400 | 16 / 24 | `bodyLarge` |
| Body small | IBM Plex Sans | 400 | 14 / 20 | `bodyMedium` |
| Label (botones, campos) | IBM Plex Sans | 500 / 600 | 14 / 20, +0,01 em | `labelLarge` |
| Caption | IBM Plex Sans | 400 | 12 / 16 | `bodySmall` / `labelSmall` |
| Dato | IBM Plex Mono | 500 | 14 / 20 | `ThemeExtension` (`AppTextStyles.data`) |

**Titulares de ciudad (Anton, OFL):** solo para las palabras de una ciudad sobre foto o velo, con interlineado 1,12: `cityDisplay` 36 (lugar del nuevo rango), `cityHeadline` 32 (saludo y frase al validar), `cityTitle` 26 ("Vas por La Ermita") y `cityCard` 22 (nombre en la tarjeta). Además `landmark` (Fraunces 700, 16) para los lugares de la subida y `eyebrow` (mono 11, mayúsculas) para el rótulo sobre fotos.

Las familias son de licencia abierta (OFL), traen tildes y ñ, y se **empaquetan en la app** (`assets/fonts/`) en lugar de descargarse en ejecución: la app se usa con conexión mala y no debe parpadear con otra fuente. Pesos incluidos: Fraunces 600 y 700; Plex Sans 400, 500 y 600; Plex Mono 500 (unos 6 archivos). Todo el texto respeta el factor de escala del sistema; los diseños deben envolver en lugar de truncar hasta 200 %.

## 5. Forma, espaciado, elevación y movimiento

- **Espaciado** (base 4/8): 4, 8, 12, 16, 24, 32, 48. Márgenes de pantalla: 20. Entre campos: 14.
- **Radios:** 8 (botones, campos, avisos), 12 (tarjetas), 16 (hojas inferiores), círculo (sellos), 14 (chips, mitad de su alto).
- **Alturas:** botón y campo 52; botón compacto 40; chips 28; objetivos táctiles ≥ 48.
- **Elevación:** por defecto **plano con borde de 1 px** (`divider`). Dos niveles: tarjeta destacada (sombra mínima, solo en claro) y superposiciones (hoja, snackbar, tarjeta flotante del mapa). En oscuro la profundidad la da la superficie, no la sombra. **Sin vidrio ni desenfoque**; si el mapa lo necesitara, será una sola capa.
- **Movimiento:** 120 ms (microinteracciones), 200 ms (cambios de estado), 320 ms (énfasis). Curva `cubic-bezier(.2, 0, 0, 1)` (`Curves.easeOutCubic` es la aproximación en Flutter). Momentos de marca: el sello se **estampa** (escala 1,18 → 1 con fundido, 320 ms) en el splash y al validar un reporte; el indicador de carga es un anillo punteado que gira. Con "reducir movimiento" activo: sin escalas ni giros, solo fundidos de 100 ms y el anillo fijo.
- **Movimiento de Ciudad Viva** (igual en todas las ciudades; un helper por patrón en `core/widgets/city/city_motion.dart`). Tokens en `AppMotion`: `reveal` 600 ms, `celebration` 1.400 ms, `ambient` 20 s, `curveStamp` `cubic-bezier(.3, 1.4, .5, 1)`, `thumbJump` 380, `floatUp` 750, `ringBeat` 420, `stampDrop` 520, `shockwave` 700 (tras `shockwaveDelay` 380), `confettiDelay` 360, `validationHold` 2.500, `rankHold` 2.600, `curtainIn` 300 + `curtainHold` 40 + `curtainOut` 380, `loadingDelay` 300 y `shimmer` 1.100.

| Momento | Qué pasa | Con "reducir movimiento" |
|---|---|---|
| 1A Tocar botones y tarjetas | escala 0,96 y vuelve (`PressScale`; un botón deshabilitado no responde) | fundido |
| 2D Apoyar | el pulgar salta, sube "+1", el anillo avanza una décima y late, la barra crece | solo cambian los datos |
| 3A Reporte validado | sello que cae girando, onda y confeti con la bandera; se cierra al tocar o a los 2,5 s | aparece con fundido, sin confeti |
| 4C Nuevo rango | la foto del lugar se abre en círculo desde su medalla; 2,6 s | fundido |
| 5A Cambio de pantalla | sale 24 dp a la izquierda, entra desde 30 dp a la derecha | fundido |
| 6A Cabecera | zoom 1 → 1,1 en 20 s, ida y vuelta; se detiene fuera de pantalla | quieta |
| 7A Cambio de ciudad | las franjas de la bandera nueva barren la pantalla | sin cortina; el tema cambia en 100 ms |
| 8D Cargando | esqueleto con brillo la primera vez de una lista o pantalla; anillo dentro del botón en acciones cortas; nada en recargas ni antes de 300 ms | esqueleto quieto, anillo fijo |

## 6. Iconografía, imágenes y patrón

- **Iconos:** [Lucide](https://lucide.dev) (`lucide_icons_flutter`) a 24 dp en toda la app, también en los botones de volver y cerrar que pone Flutter (`ActionIconTheme`). Color: `onSurfaceVariant` por defecto, acento semántico para iconos que ordenan información. Los de gravedad son propios (forma por nivel) y son los únicos que siguen siendo de Material: `Icons.circle_outlined`, `Icons.change_history_outlined`, `Icons.diamond_outlined` y `Icons.dangerous_outlined` (`SeverityChip.shapeOf`).

| Uso | Lucide |
|---|---|
| Pestañas Mapa, Comunidad, Mi perfil | `map`, `usersRound`, `circleUserRound` (la activa, en una pastilla del acento al 38 %) |
| Reportar | `mapPinPlus` |
| Apoyar, comentarios | `thumbsUp`, `messageCircle` |
| Dirección, GPS | `mapPin`, `locateFixed` (`locateOff` bloqueada) |
| Volver, ir, cerrar | `arrowLeft`, `chevronRight`, `x` |
| Fotos | `image`, `images`, `camera`, `imagePlus`, `imageOff` |
| Validado, correcto, error, información | `badgeCheck`, `circleCheck`, `circleAlert`, `info` |
| Ajustes, permisos, salir, privacidad | `settings`, `shieldCheck`, `logOut`, `lock` |
| Buscar, filtrar, ordenar, barrio, ciudad | `search`, `slidersHorizontal`, `arrowUpDown`, `mapPinned`, `building2` |
| Editar, eliminar | `pencil`, `trash2` |
| Categorías de daño | `road`, `trafficCone`, `construction`, `footprints`, `droplet`, `signpost`, `triangleAlert` |
- **Patrón de marca:** anillos punteados concéntricos recortados en una esquina, al 7-8 % de opacidad (`rings` en las maquetas). Sustituye a la foto de ciudad difuminada, que se elimina (y con ella `assets/images/civic_road_hero.jpg`).
- **Estados vacíos y errores:** círculo punteado con una marca (un signo de exclamación, una V) y un texto corto; sin ilustraciones complejas.
- **Fotos de evidencia (futuro):** relación 4:3, radio 8, con la etiqueta del código (`#VIG-8492`) en mono sobre fondo tinta en la esquina inferior izquierda.
- **Mapa:** base crema atenuada, rótulos tinta. Marcadores con la **forma** de cada gravedad (el medio lleva relleno mostaza y contorno tinta para ser visible sobre crema). Una sola tarjeta flotante con superficie sólida. Implementado en HU-13 con `flutter_map` y mosaicos de OpenStreetMap (sin clave de API) con la atribución "© OpenStreetMap"; en el tema oscuro los mismos mosaicos se oscurecen con `darkModeTileBuilder`. CARTO no se usa: sus mosaicos ahora exigen clave y devuelven una imagen "API KEY REQUIRED". Pendiente: el tono crema de los mosaicos y la tarjeta flotante.

## 7. Componentes

Todos están en `mockups/components.html` con sus estados (normal, foco, presionado, deshabilitado, cargando, error) en claro y oscuro.

| Componente | Especificación | Dónde vivirá (Flutter) |
|---|---|---|
| Botón primario | 52 dp, radio 8, tinta con texto crema (oscuro: mostaza con texto tinta profunda); cargando: texto + anillo punteado; deshabilitado: 45 % | `core/widgets/primary_button.dart` (reemplaza `LiquidGlassButton`) |
| Botón secundario | Contorno de 1,5 px del color de texto, fondo transparente | `FilledButton`/`OutlinedButton` con tema |
| Botón tonal y de texto | Tonal: 8 % del color de texto; texto: arcilla 700 subrayado | `TextButton` con tema |
| Botón destructivo | Fondo `error`; solo para borrar. **Cerrar sesión no es destructivo**: es secundario | tema |
| Campo de texto | Etiqueta arriba (14/500), campo 52 dp, borde 1,5 px `outline`, foco: borde `focus` 2 px + halo 3 px, error: borde `error` 2 px + icono y texto de ayuda | `InputDecorationTheme` |
| Selector de ciudad | Campo con icono y flecha, en el que también se escribe: la lista se filtra mientras tecleas, sin distinguir tildes ni mayúsculas (`narino` encuentra `Nariño`) y también por departamento; menú de 280 dp como máximo, con capitales en negrita. Escribir sin elegir de la lista no selecciona nada y el formulario pide la ciudad | `app_dropdown_field.dart` (`DropdownMenu` con tema) |
| Regla de contraseña (chip) | 28 dp, pendiente: contorno; cumplida: fondo `successBg`, icono de check y texto `success` | `password_strength_chips.dart` (ya existe) |
| Aviso | Fondo del estado, icono + texto, radio 8; nunca solo color | `core/widgets/app_notice.dart` |
| Snackbar | Fondo tinta, texto crema, acción en mostaza, flotante | `SnackBarTheme` |
| Tarjeta | Papel, borde 1 px, radio 12; "destacada" suma sombra mínima (solo claro) | `CardTheme` |
| Barra superior | Fondo = pantalla, título Fraunces 20/600, sin elevación | `AppBarTheme` |
| Indicador de carga | Anillo punteado que gira, visible solo después de 300 ms; en una ciudad toma `deep` sobre el fondo y el color del texto dentro de un botón; barra de progreso de 6 dp para avance conocido | `core/widgets/dotted_spinner.dart` + `ProgressIndicatorTheme` |
| Cabecera de ciudad | Foto del momento del día (240 dp; 168 y quieta en el login) con velo, franja, "CIUDAD, DEPARTAMENTO · tarde", saludo en Anton y eslogan; zoom 6A. Sin paquete no dibuja nada. La foto lleva su descripción como texto alternativo | `core/widgets/city/city_hero.dart` |
| Franja de la bandera | 32 × 8 dp (160 de ancho en el splash), un segmento por franja con su peso; decorativa | `core/widgets/city/flag_stripe.dart` |
| Tarjeta de ciudad | Registro: foto de 88 dp con velo lateral, nombre en Anton, departamento, franja y etiqueta "Detectada por GPS"; la elegida lleva borde del acento, check y estado hablado | `core/widgets/city/city_photo_card.dart` (la usa `features/auth/ui/widgets/featured_city_cards.dart`) |
| La subida (rangos) | "Mi perfil": encabezado sobre el velo ("TU SUBIDA AL …", "Vas por La Ermita", "Nivel actual: N"), barra, "1750 / 2500 pts" y la frase de lo que falta, y los cuatro rangos de arriba abajo con medalla de 56 dp, camino punteado, "TÚ", etiquetas "Logrado" y "Siguiente", y "1000 XP · Vecino Activo". Lo no logrado va en gris. Sin fotos, usa los `RankSeal` y los nombres de rango | `core/widgets/city/landmark_trail.dart` (datos desde `features/dashboard/ui/widgets/rank_climb.dart`) |
| Celebraciones | 3A (sello con foto, frase de la ciudad, confeti con la bandera, "+500 XP para quien lo reportó") y 4C (foto del lugar a pantalla completa, "NUEVO RANGO · …"). Se cierran al tocar o solas; una sola etiqueta hablada | `core/widgets/city/celebration_overlay.dart` |
| Esqueleto de carga | Formas de las tarjetas reales (feed, perfil, impacto, detalle, lista) con brillo; etiqueta hablada inmediata, visible tras 300 ms | `core/widgets/city/city_skeleton.dart` |
| Movimiento compartido | `PressScale` (1A), `SharedAxisPageTransitionsBuilder` (5A), `DelayedReveal` (8D), `EndorseThumb` (2D), `FlagCurtain` (7A) | `core/widgets/city/city_motion.dart` |
| Botón de tema | Botón de icono de 48 dp; el icono muestra el tema al que se pasa (luna → oscuro, sol → claro) y el tooltip lo dice en texto. Esquina superior derecha del login; en `actions` de la barra superior en las demás pantallas | `core/widgets/theme_toggle_button.dart` + `core/theme/theme_cubit.dart` |
| Marca (encabezado) | Sello + palabra + lema, centrado | `core/widgets/brand_mark.dart` (reemplaza `CivicBrandHeader`) |
| Sello de rango | Círculo con numeral, 4 variantes (§3.4) | `core/widgets/rank_seal.dart` |
| Chip de gravedad | Mínimo 28 dp (crece con el tamaño del texto), radio 14. Forma + color + texto: círculo `Baja`, triángulo `Media`, rombo `Alta`, octágono `Crítica` (iconos Material `circle_outlined`, `change_history_outlined`, `diamond_outlined`, `dangerous_outlined`). Colores de §3.3 por `AppSeverityColors.fillOf`/`onFillOf`; etiqueta semántica "Gravedad Alta". Recibe un `SeverityLevel` (enum del tema), no el de dominio: cada función lo traduce | `core/widgets/severity_chip.dart` |
| Barra de navegación inferior | Fondo = pantalla, plana con borde superior de 1 px (`divider`); seleccionado: etiqueta 600 en `CityTheme.navSelected` y, en una ciudad, el icono dentro de una pastilla del acento al 38 % (sin paquete: `primary`, sin pastilla); siempre icono + texto | `BottomNavigationBarTheme` + `features/explore/ui/screens/home_screen.dart` |
| Botón de mi ubicación | Botón de icono circular de 48 dp sobre el mapa (arriba a la derecha): superficie sólida con borde de 1 px, tooltip "Centrar en mi ubicación", anillo punteado mientras busca. La posición se dibuja como un punto `info` con aro de superficie, etiqueta semántica "Tu ubicación". Si el permiso está bloqueado abre el diálogo de ubicación bloqueada; los demás errores van en un aviso | `features/explore/ui/pages/map_page.dart` |
| Selector de punto en el mapa | Paso 1 del asistente (HU-27): el botón con contorno "Seleccionar ubicación" (icono de mapa) cambia el formulario por el mapa dentro del mismo paso, así el encabezado "Paso 1 de 5" se mantiene. Título "Selecciona el punto en el mapa", ayuda "Mueve el mapa hasta que el pin quede sobre el daño.", mapa que llena el alto libre del paso para que no quede espacio vacío bajo los botones (en pantallas bajas, como en horizontal, conserva `AppSizes.mapPicker`, 360 dp, y el paso se desplaza), con radio `md` y borde de 1 px, pin fijo `location_on` en `primary` de `AppSizes.mapPin` (44 dp) con la punta en el centro (etiqueta semántica "Punto del daño"), el botón de mi ubicación arriba a la derecha, las coordenadas en monoespaciada debajo, "Confirmar punto" (primario) y "Volver" (texto). El crédito del mapa es el de `flutter_map` con la fuente "OpenStreetMap" (el widget ya agrega el "©") | `features/reports/ui/widgets/map_point_selector.dart` |
| Diálogo de ubicación bloqueada | Modal con icono de ubicación desactivada, título "Ubicación bloqueada", el mensaje de HU-29 y dos acciones: "Ahora no" (texto) y "Abrir ajustes" (primario con icono). Se abre una vez por intento desde los tres botones de GPS: "Detectar mi ciudad por GPS" (registro), "Centrar en mi ubicación" (mapa) y "Centrar en mi ubicación" (mapa del paso 1 del asistente) | `core/widgets/location_blocked_dialog.dart` (`showLocationBlockedDialog`) |
| Diálogo de inicio de sesión requerido | Modal para el visitante sin cuenta (HU-22) cuando intenta una acción que necesita cuenta: icono de candado, título "Necesitas iniciar sesión", el motivo y tres acciones: "Ahora no" (texto), "Crear cuenta" (texto) e "Iniciar sesión" (primario con icono). No realiza la acción. Hoy lo abre "Reportar daño"; los futuros botones de apoyar y comentar deben usarlo | `core/widgets/sign_in_required_dialog.dart` (`showSignInRequiredDialog`) |
| Marcador de mapa | Forma de la gravedad (§3.3) de 36 dp con contorno de 2 px e icono de la categoría; objetivo táctil de 48 dp; etiqueta semántica con título, categoría y gravedad. Los reportes resueltos (HU-25) no se dibujan: el mapa muestra lo que está dañado hoy, y los resueltos siguen en Comunidad y en el detalle | `features/explore/ui/widgets/incident_map_marker.dart` (colores en `core/theme/severity_colors.dart`) |
| Tarjeta de reporte (feed) | HU-19. Tarjeta de §7 (papel, borde 1 px, radio 12) que se toca entera. Arriba la portada 16:9 (la foto principal, o el icono de la categoría sobre `surfaceContainerHighest` si no hay foto o no carga) con el código `#VIG-XXXX` en monoespaciada sobre una pastilla de superficie. Debajo: chip de gravedad + barrio (y "a 350 m" / "a 1,2 km" solo si se conoce la posición); título; autor con `RankSeal` de 24 dp y "Nombre · Rango" ("Ciudadano anónimo" si no hay autor); contadores de apoyos y comentarios (icono + número monoespaciado), `AppStatusChip` del estado (con check solo si está validado o resuelto) y la fecha `dd/mm/aaaa`. Crece con el texto (sin truncar a 200 %); una sola etiqueta semántica para toda la tarjeta | `features/explore/ui/widgets/feed_incident_card.dart` |
| Búsqueda y filtros | HU-20. Bajo el nombre de la ciudad en Comunidad: campo de búsqueda ("Buscar reportes", corto para no cortarse en 375 dp; busca en título, descripción, dirección, barrio y código; lupa y botón "Borrar búsqueda") y tres chips en un `Wrap` que baja de línea en pantallas angostas o con texto grande: categoría, barrio y orden. Un chip con valor lo muestra en negrita y con check (el filtro activo no se dice solo con color). Con un filtro encendido aparece "N reportes coinciden" y el botón de texto "Limpiar filtros". Si nada coincide, el estado vacío "Ningún reporte coincide" ofrece ese botón (uno solo, sin repetirlo bajo el campo). Una ciudad sin reportes no muestra la barra | `features/explore/ui/widgets/feed_filter_bar.dart` |
| Hoja de opciones | HU-20. Hoja inferior con asa, título y una lista de opciones de 48 dp o más; la elegida va en negrita y con check. Tocar una opción cierra la hoja y la aplica. Se redibuja si la lista de opciones cambia mientras está abierta (las categorías y los barrios salen de reportes que pueden seguir cargándose) | `features/explore/ui/widgets/choice_sheet.dart` |
| Aviso de filtros en el mapa | HU-20, criterio 5. Con un filtro de Comunidad encendido, bajo el botón de ciudad del mapa: superficie sólida con borde de 1 px, icono de filtro, "N filtros activos: X de Y reportes" y el botón "Limpiar". Los pines que no coinciden desaparecen | `features/explore/ui/pages/map_page.dart` |
| Sello "Reporte validado" | HU-16. Tarjeta de papel con borde de 2 px en `secondary` (arcilla 700 en claro, arcilla 300 en oscuro), un anillo con check a la izquierda y el texto "Reporte validado por la comunidad" con el número de apoyos en monoespaciada. Forma (anillo y check), color y texto dicen lo mismo. Aparece cuando el reporte llegó a 10 apoyos y **se queda** aunque después baje de 10 (el bono ya está consolidado). Una sola etiqueta semántica | `core/widgets/validation_seal.dart` |
| Comentarios del reporte | HU-17. Al final del detalle: título "Comentarios (N)" y los comentarios de más antiguo a más nuevo, cada uno en una tarjeta de papel con borde de 1 px: `RankSeal` de 36 dp, "Nombre" (o "Ciudadano anónimo"), "Rango · dd/mm/aaaa hh:mm" en monoespaciada, el texto y, si hay, la foto 180 dp de alto. "Eliminar" solo en el comentario propio de los últimos 5 minutos, con confirmación. Debajo, el campo "Tu comentario" (500 caracteres), cámara, galería, vista previa de la foto con "Quitar la foto" y "Publicar" (con "Publicando…" mientras envía). Un invitado lee el hilo y ve "Inicia sesión para comentar", que abre el modal de invitado. Un fallo conserva el texto y la foto y avisa con un SnackBar | `features/reports/ui/widgets/incident_comments_section.dart` |
| Avance de rango | HU-23. Es la tarjeta "La subida": barra de progreso de 6 dp con radio `small`, los puntos en monoespaciada ("1750 / 2500 pts") y "Te faltan N pts para el Nivel X · Nombre." En el nivel más alto la barra va llena y dice "Llegaste al nivel más alto. Gracias por vigilar tu ciudad." La barra se lee como "Progreso hacia el siguiente nivel, N por ciento". Al subir de rango se abre la celebración 4C | `features/dashboard/ui/widgets/rank_climb.dart` y `rank_up_celebrator.dart` |
| Contadores de impacto | HU-23. Cuadrícula de 2 × 2 tarjetas de papel con borde de 1 px: icono de acento, el número en monoespaciada de 24 y la etiqueta ("Reportes creados", "Apoyos recibidos", "Apoyos otorgados", "Comentarios publicados"). Cada par comparte altura aunque una etiqueta se parta; cada tarjeta se lee como una frase ("12 apoyos recibidos") | `features/dashboard/ui/widgets/impact_counters.dart` |
| Mis reportes | HU-23. Título "Mis reportes" y los reportes del ciudadano, del más nuevo al más antiguo, con la misma tarjeta del feed; tocar uno abre su detalle. Sin reportes: tarjeta de papel "Aún no has publicado reportes." con el botón "Reportar mi primer daño" | `features/dashboard/ui/widgets/my_reports_section.dart` |
| Acciones del autor | HU-18. En el detalle, solo para quien escribió el reporte, bajo el botón de apoyo: tarjeta de papel "Tu reporte" con "Puedes editarlo o eliminarlo durante N min más, mientras tenga menos de 5 apoyos" y dos botones de contorno, "Editar" y "Eliminar" (icono + texto, 48 dp). Pasados los 30 minutos o con 5 apoyos, la tarjeta cambia a "Reporte congelado" con un candado y la razón, sin botones; un temporizador revisa el reloj cada 15 s para quitarlos solos. "Eliminar" pide confirmación ("¿Eliminar este reporte?", pierdes los 100 XP, no se puede deshacer) | `features/reports/ui/widgets/author_actions_card.dart` |
| Fotos editables | HU-18. Tres espacios cuadrados con borde de 1 px y radio `small`: las fotos que el reporte ya tiene y las recién elegidas, cada una con un botón "Quitar foto" (48 dp, superficie sólida) en la esquina, y el primer espacio libre con el icono de cámara "Agregar foto". Título "Fotos (n/3)"; una foto que no carga muestra el icono de imagen rota | `features/reports/ui/widgets/editable_photos_box.dart` |
| Configuración y privacidad | HU-01. Pantalla abierta desde "Configuración" en Mi perfil: tarjeta de papel con borde de 1 px bajo el título "Privacidad" y el interruptor "Mostrar mi nombre" (`SwitchListTile` ≥ 48 dp). Si falla al guardar, un aviso de error aparece arriba y el interruptor vuelve a su estado anterior | `features/dashboard/ui/screens/profile_settings_screen.dart` |
| Datos personales | HU-04. Pantalla abierta desde "Datos personales" en Mi perfil con dos tarjetas planas de borde 1 px: "Información de cuenta" (nombre completo, selector cerrado DANE con apoyo de GPS y correo con aviso de verificación al cambiarlo) y "Cambiar contraseña" (contraseña actual, nueva contraseña con `PasswordStrengthChips`). Conserva los borradores si falla al guardar | `features/dashboard/ui/screens/edit_profile_screen.dart` |
| Avatar cívico | HU-05. Círculo con la foto subida por el ciudadano o, si no tiene o falla al cargar, el `RankSeal` de su nivel. En Mi perfil se toca para elegir "Tomar foto" o "Elegir de la galería" (JPG/PNG/WebP hasta 5 MB); también se muestra junto a cada comentario | `core/widgets/civic_avatar.dart` |
| Permisos del dispositivo | HU-02. Pantalla abierta desde "Permisos" en Mi perfil con dos tarjetas planas de borde 1 px ("Cámara" y "Ubicación") que muestran su estado en texto claro ("Permitido", "No solicitado", "Denegado", "Bloqueado"), solicitan el permiso nativo si no se ha pedido o abren los ajustes del sistema y se actualizan al volver | `features/dashboard/ui/screens/permissions_screen.dart` |
| Propuesta de reparación | HU-25 (RN-11). Bloque del detalle justo encima de "Comentarios". Sin propuesta, en un reporte abierto: botón de contorno "Reportar como reparado" (icono Lucide `wrench`); el invitado ve el modal de inicio de sesión. Con una propuesta pendiente: tarjeta de papel **con borde de 2 px en `success`** (la tarjeta "fijada" del hilo), con la etiqueta "Reparación en verificación" (fondo `successBg`, icono y texto `success`) y "Vence en N días" en monoespaciada; la foto de 180 dp de alto, la descripción, "Propuesta de Nombre" (o "Ciudadano anónimo") y dos barras de 6 dp con su número escrito ("Confirmaciones 2 de 3" en `success`, "Objeciones 1 de 3" en `error`). Acciones según quién mira: un vecino ve "Objetar" (contorno) y "Confirmar" (relleno), o "Ya votaste esta propuesta." después de votar; quien la propuso ve cuánto falta y los +50 XP; el autor del reporte ve "Rechazar" (contorno, abre el diálogo "¿Por qué la rechazas?" con motivo obligatorio de 10 caracteres) y "Aceptar" (relleno). En un reporte resuelto, aviso de éxito "Reparación verificada". El estado nunca va solo en el color: etiqueta, icono y números escritos | `features/reports/ui/widgets/resolution_section.dart`, `resolution_proposal_card.dart` |
| Formulario de reparación | HU-25. Hoja inferior con asa: título "Reportar como reparado", aviso informativo (al autor: "el reporte quedará resuelto de inmediato"; a un vecino: "con 3 confirmaciones… ganas +50 XP"), "Foto de la reparación (obligatoria)" con "Tomar foto" y "Galería" (contorno) o la vista previa de 160 dp con "Quitar la foto", el campo "¿Cómo quedó la vía?" (500 caracteres) y "Enviar evidencia" (primario, "Enviando…" mientras envía), que se habilita con la foto y 10 caracteres. Se cierra sola al enviar; si ya había otra propuesta, se cierra y muestra la que está en verificación | `features/reports/ui/widgets/resolution_proposal_sheet.dart` |

## 8. Voz y textos en español (mazo de textos)

Decisión de idioma: **interfaz completa en español**. Los identificadores, el código y los comentarios siguen en inglés (`AGENTS.md`).

| Hoy (inglés / mezcla) | Español propuesto |
|---|---|
| `VIGÍA - Civic Road Audit` (título de app) | VIGÍA · Veeduría vial ciudadana |
| `Civic Road Infrastructure Auditing Platform` | Tu voz, con evidencia. |
| `VEEDURÍA VIAL` (etiqueta) | (se elimina; pie: VEEDURÍA VIAL CIUDADANA) |
| `Email Address` / `example@email.com` | Correo electrónico / nombre@correo.com |
| `Password` / `Confirm Password` / `Repeat your password` | Contraseña / Confirmar contraseña / Repite tu contraseña |
| `Minimum 6 characters` | Mínimo 6 caracteres |
| `Log In` (botón) / `Log In` (enlace del registro) | Ingresar / Ingresa |
| `Don't have a civic account? ` / `Register here` | ¿Aún no tienes cuenta? / Regístrate |
| `Citizen Registration` | Crear cuenta |
| `Join Civic Oversight` + descripción | Únete a la veeduría de tu ciudad: reporta el estado de las vías y respalda a tus vecinos. |
| `Full Name` / `e.g. Juan David Quintero` | Nombre completo / Ej. Juan David Quintero |
| `Residence City (DANE Coverage)` / `Select your city` | Ciudad de residencia / Elige tu ciudad |
| `Detect nearest city via GPS` / `Detecting location...` | Detectar mi ciudad por GPS / Detectando tu ubicación… |
| `Detected nearest city: X` | Ciudad detectada: X |
| `6+ caracteres`, `Mayúscula (A-Z)`, `Minúscula (a-z)`, `Número (0-9)` | 6+ caracteres, Una mayúscula, Una minúscula, Un número |
| `Create Civic Account` | Crear cuenta |
| `Already have an account? ` | ¿Ya tienes cuenta? |
| `VIGÍA Civic Dashboard` / `Civic Profile Summary` | Mi perfil / (se elimina el rótulo; la tarjeta de identidad lo reemplaza) |
| `Successfully logged in!` + `Active civic session and confirmed credentials.` | Indicador "Sesión activa" |
| `Full Name`, `Email Address`, `Residence City` (resumen) | Nombre completo (en la tarjeta de identidad), Correo electrónico, Ciudad de residencia |
| `Civic Rank` / `Reputation Points` | Rango cívico / Puntos de reputación |
| `Log Out` (botón y tooltip) | Cerrar sesión |
| `Try again` / `Could not load your profile.` | Reintentar / No pudimos cargar tu perfil |
| `Supabase is not configured` + instrucciones | Falta configurar Supabase / Copia .env.example a .env, completa SUPABASE_URL y SUPABASE_ANON_KEY y reinicia la app. |
| Rangos: `Urban Observer`, `Active Neighbor`, `Road Guardian`, `Master Overseer` | Observador Urbano, Vecino Activo, Guardián Vial, Veedor Mayor |

**Validaciones** (hoy en `PasswordPolicy` y `RegistrationRules`): "Escribe tu nombre completo", "Escribe tu nombre y apellido", "Escribe tu correo", "Escribe un correo válido", "Escribe una contraseña", "Escribe tu contraseña", "La contraseña debe tener al menos 6 caracteres", "Usa al menos 6 caracteres", "Incluye una letra minúscula", "Incluye una letra mayúscula", "Incluye un número", "Las contraseñas no coinciden", "Elige tu ciudad".

**Errores de servicio y GPS** (hoy en `data/` y casos de uso): "Correo o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.", "Ese correo ya está registrado en VIGÍA.", "Sin conexión. Revisa tu internet e inténtalo de nuevo.", "No pudimos crear tu cuenta.", "Confirma tu correo y luego ingresa.", "Tu cuenta se creó pero no pudimos guardar tu perfil. Ingresa para intentarlo de nuevo.", "No encontramos tu perfil.", "La ubicación está desactivada. Elige tu ciudad en la lista.", "Sin permiso de ubicación. Elige tu ciudad en la lista.", "El permiso de ubicación está bloqueado. Toca "Abrir ajustes" y luego Permisos → Ubicación." (con el botón "Abrir ajustes"), "No pudimos abrir los ajustes. Activa la ubicación desde la configuración de tu navegador o teléfono.", "No pudimos obtener tu ubicación. Elige tu ciudad en la lista.", "Escribe tu correo y tu contraseña".

**Sugerencia de dirección** (HU-26, paso 1 del asistente): "Actualizamos la dirección según el punto. Revísala antes de continuar." (aviso informativo; el crédito "© OpenStreetMap" queda en el mapa). Mientras llega la sugerencia, los campos que aún no tiene muestran el anillo punteado a la derecha y el texto de ayuda "Buscando…": "Vía principal" (etiqueta de accesibilidad "Buscando la vía") hasta que llega la dirección y "Cruce o generadora (#)" ("Buscando el cruce") hasta el final. Si la sugerencia falla o llega incompleta, un aviso de error dice qué faltó y pide escribirlo: "No encontramos el cruce. Escríbelo a mano.", "No reconocimos la vía en este punto. Escribe la dirección a mano." o el motivo de la falla seguido de "Escríbela a mano." ("La sugerencia de dirección tardó demasiado.", "Sin conexión para sugerir la dirección.").

**Dirección escrita** (HU-28, paso 1 del asistente). Ayuda bajo "Nomenclatura vial": "Ejemplo: Carrera 9 # 5-45 (vía, cruce y número de la puerta)."; bajo "Punto de referencia": "Para ubicarlo en el mapa, mejor escribe una dirección como Carrera 9 # 5-45. Si es un lugar (frente al parque), marca el punto en el mapa." Origen del punto bajo las coordenadas, siempre con icono y texto: "Tu ubicación (GPS)", "Punto marcado en el mapa", "Aproximada: según la dirección", "Aproximada: centro de la ciudad". Botón mientras busca: "Buscando la dirección…". Resultado de la búsqueda (aviso sobre el botón; los de error no culpan a la persona, porque a veces el dato falta en OpenStreetMap):
- Encontrada (éxito): "Encontramos esa dirección. Revisa que el punto esté sobre el daño y toca "Confirmar ubicación"."
- Solo la calle (informativo) + "Ajustar en el mapa": "Ubicamos la calle, pero no la puerta. Mueve el punto en el mapa hasta el daño."
- No encontrada (error) + "Marcar en el mapa": "No encontramos esa dirección, así que dejamos el punto en el centro de {ciudad}. Revisa cómo la escribiste (ej. Carrera 9 # 5-45) o marca el punto en el mapa."
- Formato no entendido (error) + "Marcar en el mapa": "Parece una dirección, pero no entendemos cómo está escrita. Prueba con Carrera 9 # 5-45 o marca el punto en el mapa. Dejamos el punto en el centro de {ciudad}."
- Servicio caído (error) + "Reintentar" y "Marcar en el mapa": "No pudimos buscar la dirección por la conexión. Dejamos el punto en el centro de {ciudad}. Inténtalo de nuevo o márcalo en el mapa."
El aviso desaparece en cuanto se edita la dirección. Al confirmar un punto en el mapa, el aviso de la sugerencia dice: "Actualizamos la dirección según el punto. Revísala antes de continuar." (antes: "Sugerimos la dirección de este punto…").

**Modo visitante** (HU-22): en el login, el botón de texto "Explorar sin cuenta" (icono de brújula). Al tocar "Reportar daño": "Necesitas iniciar sesión" / "Para reportar un daño necesitas una cuenta. Inicia sesión o regístrate; es gratis." En "Mi perfil", en lugar del tablero: "Inicia sesión para ver tu perfil" / "Con una cuenta puedes reportar daños, apoyar reportes y ganar puntos de reputación." con "Iniciar sesión" (primario) y "Crear cuenta" (contorno); el visitante no ve "Cerrar sesión".

**Resolución comunitaria** (HU-25): botón "Reportar como reparado". Formulario: "Foto de la reparación (obligatoria)", "Tomar foto", "Galería", "¿Cómo quedó la vía?" (ej. "Taparon el hueco con asfalto nuevo y ya se puede pasar."), "Enviar evidencia" / "Enviando…", "Necesitas una foto y al menos 10 caracteres.". Tarjeta: "Reparación en verificación", "Vence en N días" / "Vence hoy", "Propuesta de Nombre", "Confirmaciones" y "Objeciones" con "N de 3"; vecino: "¿Pasaste por ahí? Ayuda a verificar si la vía de verdad quedó bien.", "Objetar", "Confirmar", "Ya votaste esta propuesta. Gracias por verificar."; proponente: "Es tu propuesta. Si 3 vecinos la confirman, el reporte queda resuelto y ganas +50 XP."; autor: "Un vecino dice que tu reporte ya fue reparado. ¿Es cierto?", "Rechazar", "Aceptar", diálogo "¿Por qué la rechazas?" con "Motivo". Resultados (SnackBar): "Listo: cerraste el reporte como reparado.", "Tu propuesta quedó en verificación. Con 3 confirmaciones de vecinos el reporte queda resuelto.", "Gracias, registramos tu confirmación.", "¡Reparación verificada! El reporte quedó resuelto.", "La comunidad rechazó la propuesta. El reporte sigue abierto.", "Aceptaste la reparación. El reporte quedó resuelto.", "Rechazaste la propuesta. El reporte sigue abierto.". Reporte resuelto: "Reparación verificada: la comunidad confirmó que este daño ya fue reparado.". Errores del servidor (migración 010): "Ya hay una propuesta de reparación en verificación para este reporte.", "No puedes votar tu propia propuesta.", "Como autor del reporte, acepta o rechaza la propuesta.", "Ya votaste esta propuesta.", "Esta propuesta ya no está en verificación.", "Escribe por qué rechazas la propuesta.".

**Notificaciones push** (HU-24): el canal de Android se llama "Avisos de VIGÍA" ("Apoyos, comentarios y reparaciones de tus reportes."). Los textos los escribe la base, los mismos que guarda en `notification`: "Nuevo apoyo" / "Un ciudadano apoyó tu reporte #VIG-…"; "Nuevo comentario" / "Nuevo comentario en el reporte #VIG-…: {Nombre o Ciudadano anónimo} aportó a la discusión."; "¡Reporte validado por la comunidad!" / "Tu reporte #VIG-… alcanzó 10 apoyos (+500 XP)."; "Propuesta de reparación" / "Un ciudadano envió una foto de la reparación de tu reporte #VIG-…"; "¡Reporte resuelto!" / "El reporte #VIG-… en {barrio} fue verificado como reparado.". El ícono es el de la app.

**Éxito y logro** (registro completo): "Listo, tu cuenta está creada."

**Dónde viven los textos.** Hoy están repartidos en pantallas, casos de uso y data sources. La traducción es un cambio de texto en esos archivos (sin cambiar su estructura) más la actualización de los tests que buscan cadenas en inglés (`test/widget`, `test/integration`, `test/unit`). Los nombres de rango salen de `civic_rank.name` en la base: o se actualiza `seeds.sql` y se corrige el dato en Supabase (recomendado, una sola fuente de verdad), o se traducen en la UI por `rankId`. **Se recomienda actualizar la base.** El valor de reserva `Urban Observer` en `Profile` y `ProfileModel` cambia a `Observador Urbano`. Si más adelante la app necesita otro idioma, el paso siguiente es `gen-l10n` con archivos ARB; hoy sería sobreingeniería para un solo idioma.

## 9. Accesibilidad

- Contraste AA mínimo en todos los pares de §3.5 (tabla calculada; para reproducirla basta la fórmula de luminancia relativa del estándar, p. ej. un script de 10 líneas).
- Objetivos táctiles ≥ 48 dp (los botones y campos miden 52; los iconos de la barra, 44 + margen).
- **El color nunca es la única señal:** gravedad = forma + texto; errores = icono + texto + borde grueso; reglas de contraseña = icono de check + color.
- Foco visible en todo control interactivo (borde `focus` + halo de 3 px); orden de foco natural.
- `Semantics` con etiqueta en iconos sin texto (cerrar sesión, mostrar/ocultar contraseña), y los avisos de error como regiones "en vivo".
- Texto escalable hasta 200 % sin truncar; probar con la fuente más grande del sistema.
- "Reducir movimiento": ver §5.
- Se usa en la calle y al sol: texto base 16 sp y contrastes altos en tinta sobre crema. El texto sobre una foto solo existe en los widgets de ciudad y siempre con un velo que garantiza AA incluso sobre blanco.

## 10. Mapeo a Flutter (sin escribir código todavía)

Se respeta `AGENTS.md`: estilo en `core/theme/`, componentes compartidos en `core/widgets/`, ningún color suelto en las pantallas, ningún cambio en dominio ni datos salvo los textos de §8.

```
lib/core/theme/
├── app_colors.dart        # constantes de marca + paleta clara y oscura (ColorScheme)
├── app_text_styles.dart   # TextTheme + ThemeExtension con el estilo "dato" (mono)
├── app_spacing.dart       # espaciado, radios, alturas, duraciones y curvas
├── app_theme.dart         # AppTheme.light / AppTheme.dark (ThemeData con los component themes)
└── severity_colors.dart   # ThemeExtension con los colores de gravedad y rangos
assets/fonts/              # Fraunces, IBM Plex Sans, IBM Plex Mono (TTF, licencia OFL)
assets/brand/              # SVG del sello (flutter_svg) o PNG exportados
```

Esqueleto de la paleta (valores de §3; ejemplo de forma, no se aplica aún):

```dart
abstract final class AppColors {
  // Marca
  static const ink = Color(0xFF10364A);
  static const inkDeep = Color(0xFF0B2433);
  static const cream = Color(0xFFF6EFE0);
  static const paper = Color(0xFFFFFBF2);
  static const clay700 = Color(0xFFA8432A);
  static const mustard = Color(0xFFE8B03A);
  // ...resto de §3.1
}

ColorScheme _lightScheme() => const ColorScheme(
  brightness: Brightness.light,
  primary: AppColors.ink, onPrimary: AppColors.cream,
  secondary: AppColors.clay700, onSecondary: Colors.white,
  tertiary: AppColors.mustard, onTertiary: AppColors.ink,
  error: Color(0xFFA3261B), onError: Colors.white,
  surface: AppColors.cream, onSurface: AppColors.ink,
  onSurfaceVariant: Color(0xFF55606B),
  outline: Color(0xFF7A6F5C), outlineVariant: Color(0xFFD9CFBB),
  surfaceContainerLow: AppColors.paper,
);
```

`ThemeData` incluye: `FilledButtonTheme` (alto 52, radio 8), `OutlinedButtonTheme`, `TextButtonTheme`, `InputDecorationTheme` (relleno `surfaceContainerLow`, borde 1,5 px, foco 2 px, error 2 px), `CardTheme` (plano con borde), `ChipThemeData`, `SnackBarThemeData` (flotante, tinta), `AppBarTheme` (sin elevación, Fraunces 20), `ProgressIndicatorThemeData`, `ThemeMode.system`.

**Modo claro/oscuro.** La app arranca siguiendo el tema del sistema. El widget compartido `ThemeToggleButton` (`core/widgets/`) cambia al tema opuesto del que se ve en ese momento; su ícono muestra el tema al que se pasa (luna → oscuro, sol → claro) y su tooltip lo dice con texto ("Cambiar a modo oscuro" / "Cambiar a modo claro"). Va en la esquina superior derecha del login y en la barra superior de registro y perfil, y toda pantalla nueva con barra superior debe incluirlo. El estado vive en `ThemeCubit` (`core/theme/`, un `Cubit<ThemeMode>` provisto sobre `MaterialApp`). La elección dura mientras la app está abierta; guardarla entre sesiones requiere una dependencia de almacenamiento local (p. ej. `shared_preferences`) y queda pendiente de aprobación.

**Dependencias nuevas:** ninguna obligatoria. `flutter_svg` (si se usa el SVG del sello en lugar de PNG) y, como herramientas de desarrollo, `flutter_launcher_icons` y `flutter_native_splash` para generar el ícono y el splash nativos. Se justifica cada una al implementarla.

**Se eliminan:** `CivicBackground`, `LiquidGlassButton`, `CivicCard`, `CivicBrandHeader` (sustituidos por `BrandMark`, `PrimaryButton`, tarjetas con tema) y `assets/images/civic_road_hero.jpg`.

## 11. Decisiones y alternativas descartadas

- **Sello frente a ojo, escudo o pin:** el ojo (hoy) es genérico y remite a vigilancia; el sello habla de dar fe, que es lo que hace la comunidad.
- **Fondo plano crema frente a foto de ciudad difuminada:** la foto era decoración sin relación con las vías, pesaba en el APK y bajaba el contraste del texto.
- **Fuentes empaquetadas frente a `google_fonts`:** sin red no debe cambiar la tipografía, y se evita una dependencia más.
- **Sin vidrio:** `AGENTS.md` §6b ya limita el efecto; aquí se elimina por completo en el Sprint 1 y queda reservado para una sola capa en el mapa.
- **Cerrar sesión como botón secundario, no rojo:** el rojo se reserva a errores y a acciones destructivas de datos.
- **Mostaza como acento y no como estado:** evita confundirla con la gravedad "Media" y respeta el contraste (se usa siempre con tinta).
- **Tres familias (serif, sans y mono) en lugar de una sola:** Fraunces da la voz "de sello" en títulos y números de rango; Plex Sans hace legible el resto; la mono refuerza el "registro". Tres familias es el máximo.
- **Español frente a inglés:** ver §8.
- **Banner "Successfully logged in!" eliminado:** no aportaba información nueva; se conserva el estado como indicador "Sesión activa".

## 12. Plan de migración (commits separados, cada uno con `flutter analyze` y `flutter test` en verde)

1. `chore(design): add fonts and brand assets`: fuentes, SVG del sello, `pubspec.yaml`.
2. `feat(design): add AppTheme tokens for light and dark`: `app_colors`, `app_text_styles`, `app_spacing`, `app_theme`, `ThemeMode.system`; pruebas de contraste de tokens (un test que recorre los pares críticos).
3. `feat(design): add shared widgets`: `BrandMark`, `PrimaryButton`, `AppNotice`, `DottedSpinner`, `RankSeal`; tests de widget.
4. `refactor(ui): restyle splash and login with the new system`.
5. `refactor(ui): restyle registration`.
6. `refactor(ui): restyle profile summary and configuration screen`.
7. `refactor(i18n): translate user-facing strings to Spanish`: pantallas, casos de uso, data sources, validadores y tests; migración o actualización de `civic_rank.name` y `seeds.sql`.
8. `chore(design): app icon and native splash`: `flutter_launcher_icons` y `flutter_native_splash`.
9. `chore(design): remove old glass widgets and hero image`.
10. `docs: update README, AGENTS section 6b and screenshots`: sustituir las reglas web de §6b por este sistema; actualizar la guía del demo y las capturas.

## 13. Riesgos y pendientes

- **Fraunces** tiene eje óptico y varios pesos; se usan dos pesos estáticos para controlar el peso del paquete. Probar en pantallas pequeñas y con texto grande.
- **Tests con cadenas en inglés:** la traducción los rompe a propósito; se actualizan en el paso 7.
- **Rangos desde la base:** depende de decidir dónde se traducen (§8).
- **Modo oscuro:** definido y maquetado, pero requiere probarse en dispositivo (brillo, sol, OLED).
- **Sello a 16 px:** la versión mínima (solo V) debe revisarse sobre fondos reales de Android y iOS.
- **Ícono adaptable de Android:** verificar la zona segura en varias máscaras (círculo, squircle).
- **Marca registrada y nombre:** "VIGÍA" es un nombre común; si el proyecto sale del ámbito académico conviene revisar disponibilidad.
- **Fuera de alcance de esta propuesta:** mapa, feed, asistente de reporte y tablero de métricas (solo se muestra cómo escalaría el sistema); animaciones de logro más allá del sello; ilustraciones.

## 14. Reproducir los contrastes

```js
// node contraste.mjs  (relación de contraste WCAG entre dos colores #RRGGBB)
const lin = c => { c /= 255; return c <= 0.03928 ? c / 12.92 : ((c + 0.055) / 1.055) ** 2.4 };
const L = h => { const n = parseInt(h.slice(1), 16); return 0.2126 * lin(n >> 16) + 0.7152 * lin((n >> 8) & 255) + 0.0722 * lin(n & 255) };
const ratio = (a, b) => { const [x, y] = [L(a), L(b)].sort((p, q) => q - p); return (x + 0.05) / (y + 0.05) };
console.log(ratio('#10364A', '#F6EFE0').toFixed(2)); // 11.13
```
