# Documento 6: Sprint Backlog 3 — Interacción Comunitaria, Ciclo de Vida, Gamificación y Notificaciones

**Rama:** `develop` (documentado en `docs/sprint-2-3-backlogs`)  
**Estado:** Planificado  
**Objetivo del Sprint:** Activar el tejido social y participativo de VIGÍA: habilitar el mecanismo de respaldo ciudadano (*upvotes*), la validación colectiva al alcanzar el quórum de 10 apoyos (+500 XP), el debate en hilos de comentarios con evidencia fotográfica, la moderación temporal estricta de reportes y comentarios, el panel de impacto con progresión gamificada en tiempo real, la gestión completa de perfil y privacidad, y el sistema de **notificaciones push** requerido académicamente.

---

## 1. Visión General del Sprint 3

El **Sprint 3** transforma la plataforma de un catálogo de reportes en una **herramienta viva de veeduría e incidencia colectiva**. Incorpora la retroalimentación mutua entre vecinos, la reputación cívica, la seguridad de la cuenta y los disparadores de notificaciones push para eventos críticos.

```
┌────────────────────────────────────────────────────────────────────────┐
│                        ALCANCE DEL SPRINT 3                            │
├────────────────────────────────────────────────────────────────────────┤
│ 1. Interacción Social y Voz Colectiva:                                 │
│    - HU-15: Mecanismo de apoyo toggle (+1 upvote) con XP bidireccional.│
│    - HU-16: Seguimiento de validación comunitaria (10 votos = +500 XP).│
│    - HU-17: Hilo cronológico de comentarios con foto opcional adjunta. │
│    - HU-18: Edición y eliminación de reporte (ventana de 30 minutos).  │
│                                                                        │
│ 2. Búsqueda y Filtrado Avanzado:                                       │
│    - HU-20: Filtros por categoría/barrio y ordenamiento (Votos/Fecha/  │
│             Distancia) sincronizados entre Mapa y Feed.                │
│                                                                        │
│ 3. Identidad, Privacidad y Configuración:                              │
│    - HU-01: Privacidad cívica (ocultar nombre / "Ciudadano anónimo").  │
│    - HU-02: Gestión de permisos del dispositivo desde ajustes.         │
│    - HU-04: Edición de datos personales, cambio de correo y clave.     │
│    - HU-05: Personalización de avatar ciudadano (hasta 5 MB).          │
│                                                                        │
│ 4. Gamificación y Dashboard Cívico:                                    │
│    - HU-23: Panel de impacto con 4 métricas calculadas en vivo,       │
│             recálculo reactivo de rangos y acceso a "Mis reportes".    │
│                                                                        │
│ 5. Requisito Académico del Curso:                                      │
│    - HU-24: Notificaciones Push para ≥ 2 eventos clave.                │
│    - HU-25: Propuesta de Resolución / Cierre de Reportes (RN-11).      │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 2. Historias de Usuario Detalladas

### HU-15: Apoyar un reporte (*Upvote*)
**Como** ciudadano registrado,  
**quiero** apoyar los reportes de otras personas,  
**para** dar visibilidad a los problemas más importantes de la ciudad.

#### Criterios de aceptación
1. **Dado que** no he apoyado un reporte ajeno, **cuando** toco *Apoyar*, **entonces** el contador sube en 1, el botón indica con icono y texto que ya apoyé, yo recibo **+10 XP** y el autor del reporte recibe **+10 XP**.
2. **Dado que** ya lo apoyé, **cuando** toco de nuevo, **entonces** se retira el voto (*toggle*), el contador baja en 1, y tanto yo como el autor perdemos los 10 XP previamente otorgados.
3. **Dado que** soy el autor del reporte, **cuando** veo mi reporte (HU-16), **entonces** no aparece el botón de apoyo; un intento directo contra el servidor también es rechazado (RN-05).
4. **Dado que** toco el botón varias veces rápidamente, **cuando** se procesan los toques, **entonces** nunca se registra más de un voto mío por reporte (debounce y restricción única en base de datos).
5. **Dado que** falla la operación, **cuando** se muestra el error, **entonces** el contador y el botón vuelven a su valor anterior, y los XP no cambian.

---

### HU-16: Seguir la validación de mi reporte
**Como** autor de un reporte,  
**quiero** ver en su detalle cuántos votos faltan para su validación comunitaria,  
**para** saber cuánto respaldo ciudadano ha logrado mi denuncia.

#### Criterios de aceptación
1. **Dado que** abro mi propio reporte, **cuando** carga el detalle (HU-14), **entonces** veo la vista de autor, sin botón de apoyo (HU-15).
2. **Dado que** tiene menos de 10 votos, **cuando** veo la tarjeta de validación, **entonces** se muestra *"X de 10 apoyos"* y *"Faltan Y apoyos para validar este reporte (+500 XP)"*.
3. **Dado que** recibe su décimo voto (HU-15) por primera vez, **cuando** se registra, **entonces** el estado del reporte pasa automáticamente a `COMMUNITY_VALIDATED` y recibo el bono de **+500 XP** (RN-08).
4. **Dado que** ya está validado, **cuando** cualquier persona lo ve, **entonces** aparece el sello *"Reporte validado por la comunidad"*, con texto además de color y forma.
5. **Dado que** ya estaba validado y baja de 10 votos por retiro de un apoyo, **cuando** se retira el voto (HU-15), **entonces** conservo los 500 XP consolidados; si vuelve a llegar a 10 votos, el bono de validación no se paga una segunda vez.

---

### HU-17: Comentar un reporte
**Como** ciudadano registrado,  
**quiero** comentar un reporte y adjuntar una foto si lo necesito,  
**para** aportar contexto o mostrar cómo sigue el daño con el tiempo.

#### Criterios de aceptación
1. **Dado que** abro un reporte (HU-14), **cuando** veo el hilo de discusión, **entonces** los comentarios aparecen en orden cronológico (del más antiguo al más reciente), con autor, rango cívico, fecha, texto y foto si la tienen.
2. **Dado que** escribí un texto, **cuando** lo envío, **entonces** aparece en el hilo, el campo se limpia y recibo **+15 XP**.
3. **Dado que** adjunté una foto y no escribí texto, **cuando** envío el comentario, **entonces** aparece en el hilo solo con la foto y recibo **+15 XP**.
4. **Dado que** adjunto una foto, **cuando** se valida, **entonces** se acepta solo una fotografía, en formatos JPG, PNG o WebP y de hasta 5 MB; en otro caso veo un mensaje claro con el motivo del rechazo.
5. **Dado que** publiqué un comentario hace menos de 5 minutos, **cuando** elijo *Eliminar* y confirmo, **entonces** desaparecen el texto y la foto, y se me descuentan los 15 XP ganados.
6. **Dado que** pasaron más de 5 minutos, **cuando** veo mi comentario, **entonces** ya no aparece la opción de eliminarlo; en ningún caso hay opción de editar el texto (RN-06), y el servidor rechaza una eliminación fuera de plazo.
7. **Dado que** falla el envío, **cuando** se muestra el error, **entonces** conservo el texto y la foto intactos para reintentar.

---

### HU-18: Editar o eliminar mi reporte
**Como** autor de un reporte,  
**quiero** corregirlo o eliminarlo poco después de publicarlo,  
**para** arreglar errores sin afectar el apoyo que ya recibió de la comunidad.

#### Criterios de aceptación
1. **Dado que** mi reporte tiene menos de 30 minutos de publicado y acumula menos de 5 votos (HU-15), **cuando** abro su detalle (HU-16), **entonces** veo habilitadas las acciones *Editar* y *Eliminar*.
2. **Dado que** edito el texto o las fotos, **cuando** guardo, **entonces** el reporte conserva su código `#VIG-XXXX` y se aplican las mismas validaciones de la publicación original.
3. **Dado que** elijo *Eliminar*, **cuando** confirmo en el diálogo, **entonces** el reporte y sus fotos desaparecen del feed (HU-19) y del mapa (HU-13), y se me retiran los 100 XP obtenidos por publicarlo.
4. **Dado que** el reporte superó los 30 minutos o alcanzó 5 votos comunitarios, **cuando** abro su detalle, **entonces** no veo las acciones y el reporte aparece como congelado para preservar la evidencia.
5. **Dado que** tenía la pantalla abierta cuando venció la ventana de 30 minutos, **cuando** intento guardar o eliminar, **entonces** el servidor lo rechaza y veo un mensaje informativo claro.

---

### HU-20: Buscar, filtrar y ordenar reportes
**Como** ciudadano,  
**quiero** buscar, filtrar y ordenar los reportes en la pantalla Comunidad,  
**para** encontrar rápidamente los que me interesan.

#### Criterios de aceptación
1. **Dado que** escribo en el buscador, **cuando** el texto coincide con la descripción, título o dirección de un reporte, **entonces** la lista muestra solo esas coincidencias, sin distinguir mayúsculas ni tildes.
2. **Dado que** selecciono una categoría o un barrio, **cuando** se aplica el filtro, **entonces** solo veo los reportes que cumplen con esa selección.
3. **Dado que** cambio de criterio de orden, **cuando** elijo *Más votados*, *Más recientes* o *Más cercanos*, **entonces** la lista se reordena inmediatamente según la opción seleccionada.
4. **Dado que** no di permiso de ubicación, **cuando** elijo *Más cercanos*, **entonces** se me explica que necesito activar la ubicación y se mantiene el orden previo.
5. **Dado que** apliqué filtros en Comunidad (HU-19), **cuando** cambio a Mapa (HU-13), **entonces** esos mismos filtros se mantienen activos en los marcadores.
6. **Dado que** ningún reporte coincide, **cuando** se aplican los filtros, **entonces** veo un mensaje de estado vacío amigable y un botón para limpiarlos con un toque.
7. **Dado que** estoy buscando o filtrando reportes, **cuando** veo la pantalla, **entonces** se muestra claramente la ciudad activa en la que estoy consultando.

---

### HU-01: Gestionar mi privacidad
**Como** ciudadano registrado,  
**quiero** decidir si mi nombre es visible,  
**para** controlar qué información comparto con los demás usuarios de la plataforma.

#### Criterios de aceptación
1. **Dado que** toqué mi icono de perfil y se abrió la lista de configuración, **cuando** veo la sección *"Privacidad"*, **entonces** aparece la opción *"Mostrar mi nombre"* con su estado actual en texto explicativo.
2. **Dado que** desactivo *"Mostrar mi nombre"*, **cuando** se guarda el cambio, **entonces** en mis reportes y comentarios (incluidos los ya publicados en el pasado), aparece *"Ciudadano anónimo"* en lugar de mi nombre real, conservando visible mi rango cívico honorario.
3. **Dado que** tenía mi nombre oculto, **cuando** activo *"Mostrar mi nombre"*, **entonces** mi nombre vuelve a aparecer públicamente en mis reportes y comentarios.
4. **Dado que** falla el guardado, **cuando** se muestra el error, **entonces** el interruptor vuelve a su estado anterior.

---

### HU-02: Gestionar mis permisos
**Como** ciudadano registrado,  
**quiero** gestionar los permisos de cámara y de ubicación,  
**para** decidir qué partes de mi dispositivo puede usar la app en cualquier momento.

#### Criterios de aceptación
1. **Dado que** abrí la lista de configuración en mi perfil, **cuando** veo la sección *"Permisos"*, **entonces** aparecen el permiso de cámara y el permiso de ubicación, cada uno con su estado legible en texto.
2. **Dado que** la app nunca me ha pedido el permiso de cámara, **cuando** toco la opción, **entonces** se abre el diálogo nativo de solicitud del sistema.
3. **Dado que** ya respondí la solicitud, **cuando** toco la opción, **entonces** se abren los ajustes del sistema operativo y, al volver a la app, veo el estado sincronizado.
4. **Dado que** el permiso está denegado, **cuando** adjunto una foto, **entonces** puedo elegirla desde la galería y la app no se bloquea.
5. **Dado que** el permiso de ubicación está denegado, **cuando** creo un reporte o exploro el mapa, **entonces** puedo ubicar el punto a mano o elegir una ciudad del catálogo sin bloqueos.

---

### HU-04: Editar mis datos personales
**Como** ciudadano registrado,  
**quiero** editar mi nombre, ciudad, correo y contraseña,  
**para** mantener mi cuenta al día y protegida.

#### Criterios de aceptación
1. **Dado que** inicié sesión, **cuando** toco la configuración en mi perfil, **entonces** veo la sección *"Datos personales"* con mi nombre, ciudad y correo actuales, y la opción de cambiar contraseña.
2. **Dado que** escribo un nombre sin apellido (menos de dos palabras), **cuando** intento guardar, **entonces** veo el error correspondiente y no se guarda.
3. **Dado que** cambio de ciudad de residencia, **cuando** la elijo, **entonces** solo puedo seleccionarla del catálogo cerrado DANE o detectarla por GPS.
4. **Dado que** escribo un correo inválido o ya registrado por otro usuario, **cuando** intento guardar, **entonces** el sistema muestra un mensaje claro y no cambia.
5. **Dado que** escribo un correo válido, **cuando** guardo, **entonces** la app notifica que debo confirmarlo desde el nuevo correo para surtir efecto.
6. **Dado que** cambio mi contraseña, **cuando** la contraseña actual es incorrecta o la nueva no cumple la complejidad exigida (6+ caracteres, mayúscula, minúscula, número), **entonces** se detalla el error y no se actualiza.
7. **Dado que** falla la actualización, **cuando** se muestra el error, **entonces** conservo lo que escribí para reintentar.

---

### HU-05: Cambiar mi avatar
**Como** ciudadano registrado,  
**quiero** agregar o cambiar mi avatar,  
**para** que los demás usuarios de la aplicación me identifiquen visualmente.

#### Criterios de aceptación
1. **Dado que** estoy en la sección *"Datos personales"*, **cuando** toco mi avatar, **entonces** puedo tomar una nueva foto con la cámara o elegir una de la galería.
2. **Dado que** selecciono un archivo no permitido o mayor a 5 MB, **cuando** se valida, **entonces** se rechaza con un aviso explicativo y conservo mi imagen actual.
3. **Dado que** elijo una imagen válida, **cuando** se completa la subida, **entonces** mi avatar se actualiza en mi perfil y en mis comentarios futuros y pasados.
4. **Dado que** no he configurado un avatar, **cuando** se muestra mi perfil o un comentario mío, **entonces** se presenta el sello genérico por defecto de la marca.
5. **Dado que** falla la subida de la imagen a Supabase Storage, **cuando** ocurre el error, **entonces** conservo mi avatar previo intacto y puedo reintentar.

---

### HU-23: Ver mi impacto en el panel cívico
**Como** ciudadano registrado,  
**quiero** ver mis métricas, mi rango y mis reportes en el panel,  
**para** conocer el impacto real de mi participación ciudadana.

#### Criterios de aceptación
1. **Dado que** abro mi perfil, **cuando** cargan los datos, **entonces** veo mi avatar, nombre (o indicador de anonimato), rol (*Ciudadano*), ciudad de residencia, sello del rango cívico, balance de XP y barra de avance porcentual hacia el siguiente nivel.
2. **Dado que** veo mis métricas de impacto, **cuando** las contrasto con mi actividad, **entonces** coinciden con la suma real de:
   - *Reportes Creados* (HU-12).
   - *Apoyos Recibidos* en mis reportes (HU-15).
   - *Apoyos Otorgados* a denuncias de vecinos (HU-15).
   - *Comentarios Publicados* en hilos (HU-17).
3. **Dado que** mis puntos de experiencia superan un umbral (1.000, 2.500 o 4.000 XP), **cuando** se refresca el panel, **entonces** veo mi ascenso de rango cívico; si descienden por revocación de votos, el rango se recalcula acordemente (RN-09).
4. **Dado que** alcancé el rango máximo (*Nivel 4 · Veedor Mayor*), **cuando** veo la barra de avance, **entonces** se indica con orgullo que he alcanzado el nivel de veeduría más alto.
5. **Dado que** tengo reportes publicados, **cuando** toco un elemento en la sección *"Mis reportes"*, **entonces** se abre su vista de autor (HU-16); si no tengo ninguno, veo una invitación a publicar el primero.

---

### HU-24: Notificaciones Push y Alertas Cívicas *(Requisito Obligatorio del Curso)*
**Como** ciudadano registrado,  
**quiero** recibir notificaciones push en mi teléfono ante eventos de alta relevancia en mis reportes,  
**para** enterarme oportunamente del progreso del respaldo comunitario y el estado de la infraestructura.

#### Criterios de aceptación
1. **Dado que** mi reporte alcanza el quórum de 10 apoyos comunitarios (`COMMUNITY_VALIDATED`), **cuando** se consolida el décimo voto, **entonces** recibo una notificación push prioritaria: *"¡Reporte validado por la comunidad! Tu reporte '#[Título]' alcanzó 10 apoyos (+500 XP)"*.
2. **Dado que** un vecino publica un nuevo comentario en un reporte en el que soy autor o al que estoy suscrito, **cuando** se registra el comentario, **entonces** recibo una notificación push o alerta in-app: *"Nuevo comentario en el reporte #[Código]: [Nombre/Anónimo] aportó a la discusión"*.
3. **Dado que** toco cualquiera de las notificaciones recibidas en el sistema operativo, **cuando** se abre la app, **entonces** navega directamente a la pantalla de detalle del reporte correspondiente (HU-14/HU-16).
4. **Dado que** el usuario desactiva las notificaciones a nivel de sistema operativo, **cuando** ocurren los eventos, **entonces** los registros se guardan silenciosamente en la tabla `notification` para consultarse en el Centro de Alertas in-app.

---

### HU-25: Propuesta de Resolución y Verificación de Reparación *(Opcional / Cierre Cívico RN-11)*
**Como** ciudadano o vecino,  
**quiero** proponer o validar que un bache o daño ya fue reparado adjuntando foto del arreglo,  
**para** cerrar el ciclo de veeduría y marcar la vía como recuperada.

#### Criterios de aceptación
1. **Dado que** estoy en el detalle de un reporte en estado `REPORTED` o `COMMUNITY_VALIDATED`, **cuando** toco *"Reportar como reparado"*, **entonces** se abre un formulario para adjuntar 1 foto obligatoria de la vía pavimentada/arreglada y una descripción de las obras.
2. **Dado que** ya existe una propuesta de resolución en estado `PENDING` para ese reporte, **cuando** otro vecino intenta proponer otra, **entonces** el sistema le impide duplicarla (enforzado por el índice único `idx_single_active_resolution`) y lo invita a votar la propuesta existente.
3. **Dado que** el autor original sube la foto de la reparación, **cuando** se confirma, **entonces** el reporte transiciona directamente a estado `RESOLVED`.
4. **Dado que** un vecino sube la propuesta, **cuando** acumula **3 votos de confirmación comunitaria** de otros vecinos, **entonces** el reporte pasa automáticamente a `RESOLVED` y quien propuso la solución recibe **+50 XP**.
5. **Dado que** los vecinos identifican evidencia falsa o una vía aún rota, **cuando** la propuesta recibe **3 objeciones comunitarias**, **entonces** la propuesta pasa a `REJECTED_BY_COMMUNITY`, liberando el reporte para que continúe activo.

---

## 3. Decisiones Técnicas y de Negocio del Sprint 3

### 3.1. Reglas de Negocio Afectadas en el Sprint 3
1. **RN-03 (Ventana de edición/borrado de reportes):** Estricta ventana de **30 minutos** y **menos de 5 apoyos**. Al eliminar un reporte se revocan los 100 XP asignados originalmente.
2. **RN-04 y RN-05 (Apoyos y Prohibición de Auto-voto):** Mecanismo de voto toggle. Un usuario jamás puede votar sus propias publicaciones.
3. **RN-06 (Comentarios e Inmutabilidad):** Comentarios inmutables (sin edición de texto). Borrado permitido exclusivamente dentro de los primeros **5 minutos**, con penalización de -15 XP. Se permite comentar únicamente con imagen (sin requerir texto obligatorio si hay foto).
4. **RN-08 y RN-09 (Matriz de Experiencia y Progresión Cívica):**
   - Apoyo otorgado: **+10 XP** al votante y **+10 XP** al autor.
   - Retiro de apoyo: **-10 XP** al votante y **-10 XP** al autor.
   - Comentario constructivo: **+15 XP**.
   - Validación comunitaria (10 votos): **+500 XP** de bono único irreversible para el autor.
   - Verificación de solución: **+50 XP** al proponente aceptado.
   - Escala de Rangos: *Observador Urbano* (0–999 XP), *Vecino Activo* (1.000–2.499 XP), *Guardián Vial* (2.500–3.999 XP), *Veedor Mayor* (4.000+ XP).

### 3.2. Infraestructura de Notificaciones Push
- Cumplimiento de la rúbrica de la materia (≥ 2 eventos push).
- Integración mediante **Firebase Cloud Messaging (FCM)** o Supabase Webhooks con Firebase Admin SDK.
- Gestión de tokens de dispositivo (`fcm_token`) en una tabla auxiliar o metadatos de usuario en Supabase.
