# VIGÍA: sistema de diseño, dirección E "Sello comunitario"

Rama: `design/design-system-proposal`. Estado: **implementado** en la app (tokens, tema claro y oscuro, widgets compartidos, splash, login, registro, resumen del perfil, ícono y splash nativo). Pendiente: lo que depende de funciones que aún no existen (gravedad, tarjetas de reporte, mapa, sello de validación) y la prueba en dispositivo.

Maquetas navegables (se abren en cualquier navegador, son archivos autónomos):
- [`mockups/screens.html`](mockups/screens.html): splash, login (claro, oscuro, errores), registro (vacío, con errores, completo), resumen del perfil (claro, oscuro, error de carga).
- [`mockups/components.html`](mockups/components.html): color, tipografía, botones, campos, avisos, gravedad, rangos y vista previa de feed, mapa y sello de validación.
- [`mockups/tokens.css`](mockups/tokens.css): los tokens en CSS. `node mockups/build.mjs` regenera los HTML autónomos tras editarlo.
- [`assets/logo/`](assets/logo/): sello y variantes en SVG.

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

Las tres familias son de licencia abierta (OFL), traen tildes y ñ, y se **empaquetan en la app** (`assets/fonts/`) en lugar de descargarse en ejecución: la app se usa con conexión mala y no debe parpadear con otra fuente. Pesos incluidos: Fraunces 600 y 700; Plex Sans 400, 500 y 600; Plex Mono 500 (unos 6 archivos). Todo el texto respeta el factor de escala del sistema; los diseños deben envolver en lugar de truncar hasta 200 %.

## 5. Forma, espaciado, elevación y movimiento

- **Espaciado** (base 4/8): 4, 8, 12, 16, 24, 32, 48. Márgenes de pantalla: 20. Entre campos: 14.
- **Radios:** 8 (botones, campos, avisos), 12 (tarjetas), 16 (hojas inferiores), círculo (sellos), 14 (chips, mitad de su alto).
- **Alturas:** botón y campo 52; botón compacto 40; chips 28; objetivos táctiles ≥ 48.
- **Elevación:** por defecto **plano con borde de 1 px** (`divider`). Dos niveles: tarjeta destacada (sombra mínima, solo en claro) y superposiciones (hoja, snackbar, tarjeta flotante del mapa). En oscuro la profundidad la da la superficie, no la sombra. **Sin vidrio ni desenfoque**; si el mapa lo necesitara, será una sola capa.
- **Movimiento:** 120 ms (microinteracciones), 200 ms (cambios de estado), 320 ms (énfasis). Curva `cubic-bezier(.2, 0, 0, 1)` (`Curves.easeOutCubic` es la aproximación en Flutter). Momentos de marca: el sello se **estampa** (escala 1,18 → 1 con fundido, 320 ms) en el splash y al validar un reporte; el indicador de carga es un anillo punteado que gira. Con "reducir movimiento" activo: sin escalas ni giros, solo fundidos de 100 ms y el anillo fijo.

## 6. Iconografía, imágenes y patrón

- **Iconos:** los de Material en versión *outlined/rounded* a 24 dp (ya incluidos, sin paquetes nuevos), trazo uniforme. Color: `onSurfaceVariant` por defecto, `accent` para iconos que ordenan información (resumen del perfil). Los de gravedad son propios (forma por nivel); en Flutter equivalen a `Icons.circle_outlined`, `Icons.change_history_outlined`, `Icons.diamond_outlined` y `Icons.dangerous_outlined`.
- **Patrón de marca:** anillos punteados concéntricos recortados en una esquina, al 7-8 % de opacidad (`rings` en las maquetas). Sustituye a la foto de ciudad difuminada, que se elimina (y con ella `assets/images/civic_road_hero.jpg`).
- **Estados vacíos y errores:** círculo punteado con una marca (un signo de exclamación, una V) y un texto corto; sin ilustraciones complejas.
- **Fotos de evidencia (futuro):** relación 4:3, radio 8, con la etiqueta del código (`#VIG-8492`) en mono sobre fondo tinta en la esquina inferior izquierda.
- **Mapa (futuro):** base crema atenuada, rótulos tinta. Marcadores con la **forma** de cada gravedad (el medio lleva relleno mostaza y contorno tinta para ser visible sobre crema). Una sola tarjeta flotante con superficie sólida.

## 7. Componentes

Todos están en `mockups/components.html` con sus estados (normal, foco, presionado, deshabilitado, cargando, error) en claro y oscuro.

| Componente | Especificación | Dónde vivirá (Flutter) |
|---|---|---|
| Botón primario | 52 dp, radio 8, tinta con texto crema (oscuro: mostaza con texto tinta profunda); cargando: texto + anillo punteado; deshabilitado: 45 % | `core/widgets/primary_button.dart` (reemplaza `LiquidGlassButton`) |
| Botón secundario | Contorno de 1,5 px del color de texto, fondo transparente | `FilledButton`/`OutlinedButton` con tema |
| Botón tonal y de texto | Tonal: 8 % del color de texto; texto: arcilla 700 subrayado | `TextButton` con tema |
| Botón destructivo | Fondo `error`; solo para borrar. **Cerrar sesión no es destructivo**: es secundario | tema |
| Campo de texto | Etiqueta arriba (14/500), campo 52 dp, borde 1,5 px `outline`, foco: borde `focus` 2 px + halo 3 px, error: borde `error` 2 px + icono y texto de ayuda | `InputDecorationTheme` |
| Selector de ciudad | Campo con icono y flecha; menú con capitales en negrita (como hoy) | `DropdownButtonFormField` con tema |
| Regla de contraseña (chip) | 28 dp, pendiente: contorno; cumplida: fondo `successBg`, icono de check y texto `success` | `password_strength_chips.dart` (ya existe) |
| Aviso | Fondo del estado, icono + texto, radio 8; nunca solo color | `core/widgets/app_notice.dart` |
| Snackbar | Fondo tinta, texto crema, acción en mostaza, flotante | `SnackBarTheme` |
| Tarjeta | Papel, borde 1 px, radio 12; "destacada" suma sombra mínima (solo claro) | `CardTheme` |
| Barra superior | Fondo = pantalla, título Fraunces 20/600, sin elevación | `AppBarTheme` |
| Indicador de carga | Anillo punteado que gira; barra de progreso de 6 dp para avance conocido | `core/widgets/dotted_spinner.dart` + `ProgressIndicatorTheme` |
| Marca (encabezado) | Sello + palabra + lema, centrado | `core/widgets/brand_mark.dart` (reemplaza `CivicBrandHeader`) |
| Sello de rango | Círculo con numeral, 4 variantes (§3.4) | `core/widgets/rank_seal.dart` |
| Chip de gravedad | 28 dp, forma + color + texto | `core/widgets/severity_chip.dart` (se crea cuando exista la función) |
| Sello "Reporte validado" | Sello de arcilla 700 con anillo y texto circular | futuro |

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

**Errores de servicio y GPS** (hoy en `data/` y casos de uso): "Correo o contraseña incorrectos. Revisa tus datos e inténtalo de nuevo.", "Ese correo ya está registrado en VIGÍA.", "Sin conexión. Revisa tu internet e inténtalo de nuevo.", "No pudimos crear tu cuenta.", "Confirma tu correo y luego ingresa.", "Tu cuenta se creó pero no pudimos guardar tu perfil. Ingresa para intentarlo de nuevo.", "No encontramos tu perfil.", "La ubicación está desactivada. Elige tu ciudad en la lista.", "Sin permiso de ubicación. Elige tu ciudad en la lista.", "El permiso de ubicación está bloqueado. Usa la lista de ciudades.", "No pudimos obtener tu ubicación. Elige tu ciudad en la lista.", "Escribe tu correo y tu contraseña".

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
- Se usa en la calle y al sol: texto base 16 sp, contrastes altos en tinta sobre crema, sin texto sobre fotos.

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
