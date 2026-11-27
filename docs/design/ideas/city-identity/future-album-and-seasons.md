# Ideas para después: álbum de estampas y temporadas

Estado: **propuesta, no se construye en la refactorización.** La refactorización Ciudad Viva ([`../../04-city-identity.md`](../../04-city-identity.md)) es solo de diseño. Esto son funciones nuevas: necesitan una pestaña, una migración y reglas en el servidor. Se le propone al equipo cuando Cali y Medellín estén terminadas.

Fotos ya descargadas para estas ideas (Cali y Medellín): en [`photos/`](photos/), con autor y licencia en `photos/CREDITS.json`.

## 1. Álbum de estampas
Cada ciudad completa trae 12 estampas de lugares, comida y fiestas. Se ganan con acciones reales de la app y se ven en una pestaña nueva, **Álbum**, con progreso ("7 de 12 lugares").

| Cali | Cómo se gana (ejemplo) | Medellín | Cómo se gana (ejemplo) |
|---|---|---|---|
| Gato del Río, La Ermita, San Antonio, Bulevar del Río, Torre de Cali, Plaza de Caycedo | Reportar o apoyar cerca de ese lugar (radio de unos 600 m) | Comuna 13, Plaza Botero, Orquideorama, Parque Explora, Biblioteca España, Coltejer | Igual |
| Cholado, Chontaduro | Primeros reportes en la ciudad | Bandeja paisa, Pies Descalzos | Igual |
| Río Pance, Farallones | 3 apoyos en Pance; 10 reportes validados | Parque Arví, Metrocable | 3 apoyos en Santa Elena; llegar a Guardián Vial |
| Tres Cruces | Llegar a Veedor Mayor | Pueblito Paisa | Llegar a Veedor Mayor |
| Salsódromo | Solo en temporada (Feria) | Silleta | Solo en temporada (Feria de las Flores) |

Animación cuando se gana una: **lámina que se voltea** (5B del catálogo original).

### Datos (migración nueva, la siguiente libre)
- `city_stamp` (catálogo): `code` PK, `city_name`, `title`, `kind` (`report_near`, `endorse_near`, `validated_count`, `rank_reached`, `season`), `center_lat`, `center_lng`, `radius_m`, `threshold`, `season_from`, `season_to`. Lectura pública.
- `user_stamp`: `(id_user, stamp_code)` PK, `earned_at`. RLS: cada uno lee las suyas; **el cliente no escribe** (igual que el XP desde la migración 006).
- `award_city_stamps(p_user)` `SECURITY DEFINER`, llamada desde los triggers que ya existen (publicar, apoyar, validar, cambiar de rango); idempotente.
- Notificación "Ganaste la estampa La Ermita" con HU-24 (`STAMP_EARNED`).
- Smoke test corriendo como rol `authenticated`.

### App
`city_stamp.dart`, `album_entry.dart`, `GetAlbumUseCase`, `CityStampRemoteDataSource`, `AlbumBloc`, `album_page.dart` y el widget `StampTile`. El paquete de cada ciudad suma su lista de estampas.

## 2. Temporadas
Fiestas reales cambian la cabecera y dan una estampa que solo se gana en esas fechas.
- Cali: Feria de Cali (25–30 de diciembre) con foto del Salsódromo; Petronio Álvarez (agosto).
- Medellín: Feria de las Flores (primeros días de agosto) con foto de una silletera.
- Fase posterior: multiplicador de XP en temporada (toca los triggers de 004 y 006).

## 3. Misiones de barrio (descartada por ahora)
Retos semanales ("San Antonio sin huecos: 2/5 reportes"). Juan decidió no hacerla.
