# Prompt: propuesta de sistema de diseño para VIGÍA

Cómo usarlo: cambia el modelo de esta sesión a Opus 5.5 y pega todo lo que está debajo de la línea horizontal. Trabaja dentro del repo, así que puede leer los documentos y ver la app corriendo.

---


## Rol y objetivo

Eres director de diseño de producto con experiencia en identidad de marca y sistemas de diseño para apps móviles. Quiero que propongas un **sistema de diseño completo con identidad propia** para **VIGÍA**, una app móvil colombiana de veeduría ciudadana vial. Hoy la app se ve genérica, no tiene logo (solo un ícono de ojo) y no transmite qué es ni a quién pertenece. El resultado debe ser algo que un estudiante de ingeniería pueda implementar en Flutter, y que se sienta como una marca real.

**Regla principal: no se agrega ni se quita ninguna funcionalidad.** Solo cambia cómo se ve, se siente y se comunica lo que ya existe. Si una idea requiere una función nueva, descártala o márcala claramente como "fuera de alcance".

## Trabaja dentro del repo (lee antes de proponer)

Estás en el repositorio de la app. Antes del paso 1:

1. Lee `docs/01-problem-statement-solution-actors.md`, `docs/02-architecture-screens-flows.md` y `docs/03-business-rules.md` (producto, pantallas planeadas y reglas de negocio).
2. Lee `AGENTS.md` (sobre todo §6 y §6b: reglas de UI y de diseño) y `lib/core/theme/app_theme.dart`, `lib/core/widgets/` y las pantallas de `lib/features/*/ui/screens/` para ver cómo está construido el estilo hoy.
3. Mira la app corriendo: `flutter run -d chrome --web-port 8090` (ya está configurado el `.env`; si no hay sesión verás el login y puedes ir a registro). Toma capturas de cada pantalla antes de criticarlas.

**No modifiques código de la app en esta tarea.** Todo lo que produzcas va en `docs/design/` (documentos en Markdown y maquetas en HTML o SVG que se puedan abrir en el navegador). La implementación en Flutter será una tarea posterior, que yo apruebo.

## Qué es VIGÍA

- Plataforma ciudadana, **independiente y 100 % liderada por la comunidad**, para auditar el estado de las vías y obras públicas en ciudades colombianas (huecos, andenes rotos, semáforos dañados, obras abandonadas, fugas de agua, señalización).
- Problema que resuelve: las quejas ciudadanas están dispersas en redes sociales, sin ubicación exacta ni evidencia, y la molestia colectiva es invisible. VIGÍA reúne evidencia fotográfica georreferenciada y el respaldo de la comunidad (votos) para que los problemas más críticos se vean.
- Lo que **no** es: no tramita PQRSD, no despacha cuadrillas, no es un canal oficial del gobierno. Es una herramienta cívica, pacífica y transparente.
- Tono: serio sin ser burocrático, cercano sin ser infantil, firme pero constructivo. La gamificación (puntos de experiencia, rangos, insignias) es **sutil y transparente**, nunca un juego de casino.
- Usuario típico: ciudadano de una ciudad intermedia de Colombia, 25-45 años, se mueve en carro, moto o a pie, usa el celular en la calle y bajo el sol, y ha perdido la confianza en que sus quejas sirvan de algo. Quiere sentir que su voz cuenta.
- Actores: visitante anónimo (solo explora), ciudadano registrado (reporta, vota, comenta, sigue reportes) y "veedor distinguido" (ciudadano con rango alto e insignias visibles).
- Rangos cívicos: el rango 1 se llama "Urban Observer"; los siguientes suben con XP (por ejemplo "Level 3 - Road Guardian"). Tienen que verse como una progresión coherente.
- Gravedad de un reporte: Low, Medium, High, Critical. Necesita un código de color claro y accesible.
- Cobertura: 51 municipios colombianos (capitales y ciudades de más de 100 mil habitantes).

## Qué existe hoy (las únicas pantallas implementadas)

1. **Splash:** marca con indicador de carga mientras se revisa la sesión.
2. **Login:** correo, contraseña (con ojo para mostrar/ocultar), botón "Log In" y enlace a registro.
3. **Registro:** nombre completo, correo, ciudad (lista cerrada y botón "Detect nearest city via GPS"), contraseña con una lista de 4 reglas que se marcan en vivo (6+ caracteres, mayúscula, minúscula, número), confirmación de contraseña y botón "Create Civic Account".
4. **Resumen del perfil:** mensaje de sesión iniciada, tarjeta con nombre, correo, ciudad, rango y puntos de reputación, y botón "Log Out".
5. Mensajes de error y de carga (snackbars, indicadores).

Pantallas **planeadas** (aún no existen, pero el sistema debe poder crecer hacia ellas): mapa con marcadores y tarjeta flotante, feed comunitario con filtros, asistente de reporte en 4 pasos (ubicación, fotos, tipo y gravedad, resumen con código `#VIG-8492`), detalle de reporte con barra de respaldo comunitario y comentarios, y tablero cívico con métricas, XP e insignias.

Estado visual actual (lo que quiero superar): fondo con foto de ciudad difuminada, tarjetas de "vidrio" (liquid glass), acento índigo, un orbe con ojo como logo y una etiqueta "VEEDURÍA VIAL". Se siente a plantilla de app genérica y no tiene relación con las vías ni con Colombia. Además, el idioma de la interfaz está mezclado (casi todo en inglés, con textos en español como "6+ caracteres", "Mayúscula (A-Z)" y "VEEDURÍA VIAL").

## Restricciones técnicas (no negociables)

- Se implementa en **Flutter (Material 3), mobile-first** para Android e iOS. Nada de técnicas solo de web (Tailwind, CSS, shaders de Three.js).
- Todo estilo sale de **un único `AppTheme`** con tokens (colores, tipografía, radios, espaciado, elevación, movimiento). Nada de colores sueltos en los widgets.
- Las tipografías deben estar disponibles gratis (por ejemplo Google Fonts), soportar tildes y la ñ, y tener pocos pesos para no inflar la app.
- **Accesibilidad:** contraste WCAG 2.1 AA como mínimo (4.5:1 texto normal, 3:1 texto grande y componentes), objetivos táctiles de 48 dp o más, tamaños de texto escalables, soporte de "reducir movimiento", y que el color nunca sea la única señal (la gravedad y los estados deben tener también icono o texto).
- **Rendimiento:** efectos de desenfoque o vidrio como máximo una capa por elemento y pocos a la vez en pantalla; listas largas con superficies sólidas.
- Uso real: poca luz, sol directo, una mano, conexiones lentas. Prioriza legibilidad y claridad sobre decoración.
- Debe funcionar en **modo claro y oscuro**.
- Respeta las reglas de `AGENTS.md` (arquitectura y estilo): el rediseño solo toca presentación, no capas de dominio ni datos.
- Los textos visibles hoy se pueden reescribir si mejora la voz de marca, pero sin cambiar lo que hace cada pantalla.

## Cómo trabajar (dos pasos, con una pausa)

**Paso 1: direcciones de identidad.** Antes de desarrollar nada en detalle, preséntame **3 direcciones** distintas entre sí. Para cada una: nombre de la dirección, concepto en una frase, personalidad de marca, paleta de muestra (6-8 colores con hex), pareja tipográfica, un boceto del logo en SVG y cómo se vería la pantalla de login (SVG o HTML). Recomienda una y explica por qué, incluyendo los riesgos. **Detente ahí y espera mi elección.**

**Paso 2: sistema completo** de la dirección elegida (o una mezcla que te indique), con los entregables de abajo.

## Entregables del paso 2

1. **Plataforma de marca:** esencia, personalidad, voz y tono con ejemplos de microcopy (errores, éxito, estados vacíos, botones), y 3 opciones de lema corto. Debe sentirse colombiano sin caer en clichés ni estereotipos.
2. **Logo:** el mejor concepto desarrollado en SVG: versión principal, versión monocroma, ícono de app (cuadrado y adaptable de Android), versión mínima legible a 16-24 px, y zona de seguridad. Evita el ojo genérico, el escudo y el pin de mapa de stock; busca algo propio que conecte con vías, vigilancia cívica o comunidad. Explica el razonamiento.
3. **Color:** paleta con tokens semánticos (marca, superficies, texto, bordes, estados de éxito/advertencia/error/info), **escala de gravedad** (Low, Medium, High, Critical), colores para rangos e insignias, y la lista de pares texto/fondo con su relación de contraste calculada. Versión clara y oscura.
4. **Tipografía:** familias, pesos, y una escala completa (display, título, cuerpo, etiqueta, número/dato) con tamaños, altura de línea y espaciado, mapeada a los roles de `TextTheme` de Material 3.
5. **Forma, espaciado, elevación y movimiento:** escala de espaciado base 4/8, radios, bordes, sombras o capas (con reglas claras para cuándo usar cada una), duraciones y curvas de animación, y la alternativa con movimiento reducido.
6. **Iconografía, imágenes y mapa:** estilo de iconos (con qué familia existente se logra), tratamiento de fotografías de evidencia, ilustraciones o patrones de marca para estados vacíos y splash (con lenguaje visual de vía: marcas viales, señalización, asfalto, etc., si lo consideras acertado), y dirección de estilo para el mapa futuro.
7. **Componentes** con todos sus estados (normal, foco, presionado, deshabilitado, cargando, error): botones (primario, secundario, texto, destructivo), campos de texto con etiquetas y ayudas, selector de ciudad, chips de reglas de contraseña, tarjetas, snackbars/avisos, barra superior, indicadores de carga y de progreso (incluida la barra de XP), insignias de rango y de gravedad.
8. **Pantallas de alta fidelidad** en el viewport de un celular (HTML o SVG): splash, login, registro (vacío, con errores y completado), resumen del perfil y un estado de error de red. Los textos deben respetar lo que cada pantalla hace hoy.
9. **Vista previa del futuro:** un boceto de cómo se aplicaría el sistema a una tarjeta de reporte del feed, al marcador y la tarjeta flotante del mapa y a una insignia de rango, para comprobar que escala.
10. **Mapeo a Flutter:** tabla `token -> constante en AppTheme -> propiedad de ThemeData/ColorScheme/TextTheme/ComponentTheme`, un esqueleto de código de `AppTheme` y `ThemeData` claro y oscuro, lista de assets (SVG, fuentes) y de paquetes nuevos si hacen falta (justifica cada uno).
11. **Decisiones y alternativas descartadas**, con una frase de por qué.
12. **Plan de migración** en pasos pequeños y ordenados (tokens y tema, luego componentes compartidos, luego cada pantalla), pensado para hacerse con commits separados.

## Calidad esperada

- Identidad reconocible a simple vista, con una idea central clara, no una colección de estilos de moda. Sé crítico: si algo de la lista anterior no aporta, dilo.
- Evita los tópicos de apps generadas por IA: degradados morados o azul-cian sin sustento, exceso de vidrio y brillos, tarjetas idénticas con sombras flotantes, emojis como iconografía.
- Sobrio y confiable, pero con carácter. Piensa en una institución ciudadana joven, no en una fintech ni en una app de gobierno.
- Todo concreto y utilizable: valores exactos (hex, sp, dp, ms), no adjetivos.
- Si necesitas asumir algo que no está en este documento, dilo en una línea y sigue; no me hagas preguntas salvo que sea imprescindible para el paso 1.
- **Idioma de la interfaz:** hoy es mayormente inglés y los usuarios son colombianos. En el paso 1 dime cuál recomiendas y qué consecuencias tiene para el microcopy; decidiré yo.
