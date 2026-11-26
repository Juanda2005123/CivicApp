# VIGÍA · Identidad de ciudad gamificada (plan, borrador)

> **Reemplazado.** Este fue el primer borrador. Lo vigente es [`../../04-city-identity.md`](../../04-city-identity.md) (solo diseño), [`../../05-new-city-guide.md`](../../05-new-city-guide.md) y, para el álbum y las temporadas, [`future-album-and-seasons.md`](future-album-and-seasons.md).

Objetivo: que cada ciudad se sienta *esa* ciudad (fotos reales, íconos, bandera, jerga, comida, fiestas) y que la gamificación (XP, rangos, apoyos) se viva como "conquistar y cuidar tu ciudad".

## 1. Dos niveles de profundidad
- **Nivel 1 · Ciudad Viva** (pack completo): Cali (piloto), Bogotá, Medellín, Barranquilla, Cartagena.
- **Nivel 2 · Pack regional** para las otras ~27: paleta y motivos por región (Caribe, Pacífico, Andina/Cafetera, Llanos, Amazonía, Insular) + una foto real + bandera de la ciudad.

## 2. Qué trae un pack (modelo `CityIdentity`)
| Pieza | Cali (piloto) |
|---|---|
| Héroe con foto real (cambia mañana/tarde/noche) | Cali desde Cristo Rey · atardecer · Cali de noche desde La Reforma |
| Paleta derivada de la bandera + foto | Bandera de Cali (verificar colores oficiales con `cali-bandera.png`) + naranja atardecer |
| Saludo y microcopy local | "¡Qué más, ve!", "Cali se ve más bonita contigo" |
| **Hitos = rangos** (reemplazan los 4 rangos genéricos solo en la UI) | Observador → **Gato del Río**; Vecino Activo → **La Ermita**; Guardián Vial → **Cristo Rey**; Veedor Mayor → **Tres Cruces** (la cima) |
| Mapa de progreso tipo "subida al cerro" | El perfil muestra el camino al Cerro de las Tres Cruces; cada 250 XP es un tramo |
| Insignias coleccionables ("álbum de la ciudad") | San Antonio, Bulevar del Río, Torre de Cali, Plaza de Caycedo, Farallones, Río Pance, Salsódromo, Cholado, Chontaduro |
| Eventos de temporada | **Feria de Cali (25–30 dic)**: XP x1.5 y skin "Salsódromo"; Petronio Álvarez (ago) |
| Celebración al validar un reporte | Confeti con colores de la bandera + sonido corto de salsa (opcional, silenciable) |

Bogotá: Monserrate, La Candelaria, TransMilenio, ajiaco, "¡Qué hubo, sumercé!". Medellín: Metrocable, Comuna 13, Plaza Botero, Feria de las Flores (silleteros). Barranquilla: Ventana al Mundo, Marimonda, Carnaval (feb). Cartagena: Puerta del Reloj, La Popa, murallas.

## 3. Fotos reales (ya descargadas en `photos/`, créditos en `photos/CREDITS.json`)
Todas de Wikimedia Commons con licencia CC0, dominio público, CC BY o CC BY-SA. **Requisito:** pantalla "Créditos de fotos" en Ajustes (autor + licencia + enlace) y atribución corta en el héroe. Colombia tiene libertad de panorama, así que las esculturas públicas (Gato del Río, Botero) se pueden fotografiar y usar.
Pendientes al cortar la sesión: Tres Cruces, Cristo Rey, Gato del Río, Ermita, bandera (la descarga quedó corriendo; si faltan, se repite `dl2.py`).

## 4. Implementación en Flutter (fases)
1. `lib/core/theme/city/`: `CityIdentity` (paleta, fotos, hitos, copy, temporadas) + registro por `cityName`; `CityThemeCubit` que escucha `lastCityName` y reconstruye `ThemeData` (respeta claro/oscuro existente).
2. Assets: fotos optimizadas a WebP ~1080 px (<200 KB c/u), `pubspec.yaml`.
3. Widgets: `CityHero` (foto + degradado + hora del día), `LandmarkRankBadge`, `CityProgressTrail` (subida al cerro), `CityStampAlbum`, `CelebrationOverlay`.
4. Pantallas: Comunidad, Detalle, Mi perfil, Mapa (marcadores con color de ciudad), Registro (al elegir ciudad, se "enciende" su identidad).
5. Datos: sin migración al inicio (insignias calculadas en cliente con contadores existentes). Si se quieren persistir: migración `009_city_badges.sql` (tabla `user_badge`, otorgada por trigger, nunca por el cliente).
6. Pruebas: unitarias del registro/cubit, widget tests de hero y rangos, golden de Cali; mantener verde la suite actual (715).

## 5. Conflicto con el sistema de diseño actual
`AGENTS.md` §6b regla 4 y `docs/design/03-design-system.md` prohíben fondos con foto y degradados. Este plan cambia esa regla: el cambio debe actualizar `03-design-system.md`, `AGENTS.md` §6b y los mockups en el mismo PR (contraste AA del texto sobre foto con velo de color sólido, modo oscuro, movimiento reducido).

## 6. Decisiones pendientes del usuario
- ¿Piloto solo Cali para la entrega del sprint 3, y el resto después?
- ¿Los nombres de rango por hito reemplazan los genéricos o van como subtítulo?
- ¿Sonido en celebraciones sí/no?
