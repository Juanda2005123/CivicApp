# Cómo agregar una ciudad completa (Bogotá, Cartagena…)

Para: Cano, Juan David y cualquiera que arme un paquete de ciudad. Antes lee [`04-city-identity.md`](04-city-identity.md) §0 a §3.

## 1. Lo que NO se cambia (ya está decidido por Juan)
- Las pantallas, su estructura y sus funciones. Es una refactorización de **diseño**: nada nuevo, nada quitado.
- Los widgets compartidos (`core/widgets/city/`), la tipografía, los íconos Lucide y la barra de 3 pestañas.
- **Todas las animaciones**: 1A, 2D, 3A, 4C, 5A, 6A, 7A y 8D (`04-city-identity.md` §6). No se escoge otra por ciudad.
- Las reglas de XP, validación y rangos.
- Nunca un `if (city == 'Bogotá')` en un widget o pantalla. Si tu ciudad necesita algo que el paquete no tiene, se habla con Juan y se agrega al paquete para todas.

## 2. Lo que escoges tú (el paquete de tu ciudad)
| Campo | Regla |
|---|---|
| `deep` (tono profundo) | Chips y enlaces. 4.5:1 o más con blanco |
| `accent` + `onAccent` (botones) | Cálido o vivo, que llame la atención sin chillar. 4.5:1 o más entre los dos |
| `veil` | Muy oscuro, para que el texto blanco se lea sobre la foto |
| Bandera | Colores y peso de cada franja, de arriba a abajo, de la bandera **oficial** del municipio |
| 3 fotos de cabecera | Mañana, tarde y noche. Horizontales, mínimo 1080 px de ancho, lugares reconocibles |
| 4 lugares para los rangos | En orden de subida (0, 1.000, 2.500 y 4.000 XP); el último es el más icónico. Foto que se pueda recortar en cuadrado |
| Saludos | Mañana, tarde y noche, en el habla de la ciudad, con tuteo y respeto |
| Eslogan y frase al validar | Cortos. Ej.: "Cali se cuida entre vecinos." / "¡Eso, ve!" |

Fotos: solo de [Wikimedia Commons](https://commons.wikimedia.org) con licencia CC0, dominio público, CC BY o CC BY-SA. Guarda autor, licencia y enlace (van a `assets/cities/CREDITS.md`, no a la app).

## 3. Paso 1, obligatorio: maqueta antes de programar
Nadie escribe el paquete en Dart sin que antes exista la maqueta de su ciudad y la apruebe su dueño.

1. Pídele a Claude (o al agente que uses) que **agregue tu ciudad a la misma maqueta** `docs/design/mockups/city-identity.html`: una entrada nueva en `PACKS` con los mismos campos que Cali y Medellín, su lista de fotos en `POOL` y un botón nuevo en el selector "Ciudad". No se hace una maqueta aparte ni se tocan las pantallas ni las animaciones (en la maqueta solo se reproducen, no se escogen).
2. Que busque y descargue un **banco de fotos** de tu ciudad: unas 15, con al menos 3 candidatas buenas para cada espacio (mañana, tarde, noche y los 4 lugares). Las originales van a `docs/design/ideas/city-identity/photos/` con su crédito en `CREDITS.json`, y las livianas a `docs/design/mockups/city-img/`. Que revise cada foto a ojo antes de proponerla: nada borroso, oscuro, en blanco y negro o que no se reconozca.
3. Abre tu ciudad en la maqueta y usa la sección **"Paquete de la ciudad"**:
   - **Fotos:** toca las miniaturas hasta que cada espacio tenga la mejor foto. Revisa mañana, tarde y noche, en claro y en oscuro.
   - **Textos:** los 4 lugares de los rangos, los saludos, el eslogan y la frase al validar.
   - **Colores:** con el chequeo AA en verde.
   - Al final, **"Copiar paquete"** y pégaselo a Claude: ese JSON es el que se pasa a Dart.
4. Muéstrala en el grupo. Cuando estés conforme, sigue con el paso 2.

Mensaje listo para pegarle a Claude:

> Lee `AGENTS.md`, `docs/design/04-city-identity.md` y `docs/design/05-new-city-guide.md`. Quiero agregar **[CIUDAD]** como ciudad completa de VIGÍA. Primero solo la maqueta: agrega [CIUDAD] a `docs/design/mockups/city-identity.html` (nueva entrada en `PACKS` y botón en el selector), sin tocar pantallas ni animaciones. Busca en Wikimedia Commons un banco de unas 15 fotos reales con licencia libre, con al menos 3 candidatas por espacio (cabeceras de mañana, tarde y noche, y 4 lugares icónicos para los rangos en orden de subida). Revísalas a ojo y agrégalas a `POOL` para que yo escoja en el editor. Propón la paleta (`deep`, `accent`, `onAccent`, `veil`) que pase AA, la bandera oficial y los saludos en el habla local. Guarda las fotos y sus créditos como dice la guía. Muéstrame la maqueta publicada y espera mi aprobación antes de escribir Dart.

## 4. Paso 2: el paquete en la app
1. Rama desde `develop` (Ciudad Viva ya está fusionada): `feat/city-<slug>`.
2. Copia `lib/features/city_identity/data/datasources/packs/cali_pack.dart` a `<slug>_pack.dart` y cambia solo los datos: `caliPack`, la ruta `assets/cities/cali`, `slug`, `name` y `department` (escritos igual que en el catálogo DANE), paleta, bandera, fotos, lugares y textos.
3. Fotos: agrega tu ciudad al diccionario `CITIES` de `tool/city_photos.py` (las claves de `CREDITS.json` que escogiste en la maqueta) y corre `python tool/city_photos.py` (necesita Pillow). Genera los WebP de `assets/cities/<slug>/` y reescribe `assets/cities/CREDITS.md`.
4. Dos líneas más: la carpeta `assets/cities/<slug>/` en `pubspec.yaml` y el paquete en la lista de `city_pack_local_data_source.dart` (con su `import`).
5. `dart run tool/check.dart`. Las pruebas recorren todos los paquetes: fallan si tu paleta no pasa AA, falta una foto o pesa 200 KB o más, o el nombre no coincide con el catálogo.
6. Capturas de Comunidad, Detalle y Mi perfil en claro y oscuro: en `tool/screenshots/capture.mjs` y `profile_screenshots_test.dart` agrega tu ciudad a la lista (las instrucciones están al inicio de cada archivo).
7. PR a `develop`.

No hay que tocar widgets, pantallas ni pruebas. Esto se ensayó copiando el paquete de Cali como una tercera ciudad: la suite completa pasó sin más cambios.

## 5. Ciudad genérica (paquete regional)
Para quien tome este frente: cubre todas las ciudades que no son Cali, Medellín, Bogotá ni Cartagena (Barranquilla incluida). Se diseña **por región**, no por ciudad. Qué trae cada región está en [`04-city-identity.md`](04-city-identity.md) §3.4: paleta, franja de la bandera de Colombia, 3 fotos de cabecera, foto para cada uno de los 4 rangos (con sus nombres genéricos) y saludos regionales neutros.

Mismas reglas de §1 y mismo orden:
1. **Maqueta primero.** Pídele a Claude que agregue la opción **"Ciudad genérica"** al selector de la maqueta, con un segundo selector de región (Caribe, Pacífico, Andina, Llanos, Amazonía, Insular). Cada región va como una entrada en `PACKS`, con su banco de fotos en `POOL` (al menos 3 candidatas por espacio). Escoge en "Paquete de la ciudad", copia el paquete de cada región y muéstralo en el grupo.
2. **Después, el código:** llena `lib/features/city_identity/data/datasources/packs/regional_packs.dart` (la estructura y el mapa departamento → región ya existen) y pon las fotos en `assets/cities/region-<nombre>/`. Se sigue el mismo paso 2 de §4. Un paquete regional va sin `name` ni `department`, con `level: CityIdentityLevel.regional`, los nombres genéricos de los rangos y `{ciudad}` donde el texto lleve el nombre de la ciudad.
3. Un detalle por resolver ahí: la subida del perfil busca el paquete con `reference_city`, que no trae departamento. Para que muestre las fotos de la región, `ReferenceCityChanged` tiene que recibir también el departamento (sale del catálogo de ciudades). Es un cambio pequeño en la capa de presentación, sin base de datos; coordínalo con Juan.

Mensaje listo para pegarle a Claude:

> Lee `AGENTS.md`, `docs/design/04-city-identity.md` (§3.4) y `docs/design/05-new-city-guide.md` (§5). Quiero diseñar la **ciudad genérica** de VIGÍA, por regiones. Primero solo la maqueta: agrega "Ciudad genérica" al selector de `docs/design/mockups/city-identity.html` con un selector de región, y una entrada en `PACKS` y en `POOL` por cada región, sin tocar pantallas ni animaciones. Busca en Wikimedia Commons fotos reales con licencia libre de paisajes reconocibles de cada región (al menos 3 candidatas por espacio) y revísalas a ojo. Propón paletas que pasen AA y saludos regionales neutros. Muéstrame la maqueta publicada y espera mi aprobación antes de escribir Dart.
