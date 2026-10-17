# Documento 3: Reglas de Negocio del Sistema

## 3.1. Reglas sobre Reportes
* **RN-01 (Integridad del Reporte):** Todo reporte debe registrar obligatoriamente: latitud, longitud, dirección de referencia, barrio, título descriptivo, descripción del problema y categoría válida.
* **RN-02 (Evidencia Fotográfica):** Cada reporte admite entre 0 y 3 fotografías adjuntas en formatos JPG, PNG o WebP, con un tamaño máximo de 5 MB por archivo.
* **RN-03 (Ventana de Edición y Eliminación de Reportes):** 
  * El autor de un reporte puede editar sus textos/fotos o eliminarlo **únicamente durante los primeros 30 minutos** posteriores a su publicación, siempre y cuando el reporte tenga **menos de 5 upvotes**.
  * Si el reporte supera los 30 minutos de antigüedad o acumula 5 o más upvotes comunitarios, queda congelado y no puede ser alterado ni eliminado por el autor, protegiendo la veracidad del respaldo ciudadano acumulado.

## 3.2. Reglas de Interacción Comunitaria
* **RN-04 (Votación Única / Mecanismo Toggle):** Un usuario autenticado solo puede emitir un único voto de apoyo (*upvote*) por reporte. Si presiona nuevamente el botón de apoyo en un reporte ya respaldado, el voto es revocado (*toggle vote*).
* **RN-05 (Prohibición de Autovoto):** Un usuario no puede votar sus propios reportes en ninguna circunstancia.
* **RN-06 (Moderación, Adjuntos y Eliminación de Comentarios):**
  * Solo los usuarios registrados pueden publicar comentarios en los hilos de los reportes.
  * **Evidencia Fotográfica Opcional:** Cada comentario puede adjuntar de manera opcional hasta una (1) fotografía como complemento visual o seguimiento del estado de la vía (formatos JPG, PNG o WebP, tamaño máximo de 5 MB). No es un requisito obligatorio para comentar.
  * Los comentarios son inmutables (no admiten edición de texto ni sustitución de imagen) para mantener la coherencia cronológica del hilo.
  * **Ventana de Eliminación:** El autor del comentario puede **eliminarlo exclusivamente dentro de los primeros 5 minutos** posteriores a su publicación (removiendo tanto el texto como la fotografía adjunta). Pasado ese tiempo, el comentario es definitivo.
* **RN-07 (Suscripción y Notificaciones):** Cualquier usuario autenticado (distinto al autor) puede activar o desactivar el seguimiento a un reporte para recibir notificaciones sobre nuevos comentarios o hitos comunitarios. El autor está suscrito automáticamente.

## 3.3. Reglas de Gamificación y Puntos de Experiencia (XP)
* **RN-08 (Tabla de Adquisición de XP):**
  * **Crear un nuevo reporte:** **+100 XP** otorgados al momento de publicar el reporte.
  * **Bono de Validación Comunitaria:** **+500 XP** automáticos otorgados al autor cuando su reporte alcanza por primera vez los **10 upvotes**.
  * **Por cada upvote recibido en reportes propios:** **+10 XP** para el autor por cada voto individual que sume su publicación.
  * **Apoyar un reporte ajeno (emitir upvote):** **+10 XP** para el usuario votante.
  * **Publicar un comentario constructivo:** **+15 XP** para el usuario que comenta.
  * **Penalización por revocación de voto:** Si un usuario retira su upvote, se descuentan automáticamente **-10 XP** al votante y **-10 XP** al autor del reporte. Si la revocación reduce el total de votos por debajo de 10, no se retira el bono de validación si este ya había sido consolidado.
* **RN-09 (Escala de Rangos Cívicos):**
  * *Nivel 1 - Observador Urbano:* 0 a 999 XP.
  * *Nivel 2 - Vecino Activo:* 1,000 a 2,499 XP.
  * *Nivel 3 - Guardián Vial:* 2,500 a 3,999 XP.
  * *Nivel 4 - Veedor Maestro:* 4,000+ XP.
  * *Nota:* cada rango queda definido por `rango_civico.xp_minimo` (0, 1000, 2500 y 4000). El rango del usuario es el de mayor `xp_minimo` que no supere sus `puntos_experiencia`.
* **RN-10 (Asignación Automática de Insignias):** Las insignias se otorgan de forma síncrona al cumplir las siguientes condiciones acumulativas:
  * *Primer Paso Cívico:* Al publicar el primer reporte.
  * *Voz Activa:* Al realizar 10 comentarios en discusiones comunitarias.
  * *Cazador de Baches:* Al publicar 5 reportes en la categoría "Hueco o Bache".
  * *Reporte de Alto Impacto:* Al conseguir que un reporte propio alcance la validación comunitaria (10 upvotes).
  * *Guardián Comunitario:* Al otorgar 50 apoyos (*upvotes*) a reportes de otros vecinos.

## 3.4. Reglas de Resolución de Reportes
* **RN-11 (Resolución Cívica con Evidencia Fotográfica y Verificación Cruzada):**
  * Para marcar un reporte en estado `RESUELTO`, es mandatorio presentar evidencia fotográfica reciente (1 foto) que demuestre que el daño vial ha sido reparado o subsanado, junto con una descripción del estado actual.
  * **Interacción en UI y Entidad Independiente:** La pantalla de detalle cuenta con un botón dedicado *"Reportar como Reparado/Resuelto"* que abre un modal especializado. Este genera un registro en la entidad desacoplada `resolucion_reporte` (con su fotografía en `url_foto_evidencia`).
  * **Visualización en Frontend:** La propuesta activa se renderiza como una tarjeta fijada (*pinned card*) destacada con borde verde al inicio de la discusión del reporte.
  * **Resolución por el Autor Original:** Si el autor del reporte publica la evidencia de subsanación, el reporte pasa directamente a estado `RESUELTO`.
  * **Resolución por Ciudadano no Autor:** Si un ciudadano diferente al autor presenta la propuesta de resolución:
    * Se notifica de inmediato al autor del reporte con opciones de **[Aceptar Solución]** o **[Rechazar]**.
    * **Salvaguarda Comunitaria:** Si el autor no responde en 48 horas, o si la propuesta recibe **3 votos de confirmación comunitaria** mediante la tabla `confirmacion_resolucion` (`votos_confirmacion >= 3`), el sistema actualiza automáticamente el estado del reporte a `RESUELTO`.
  * **Recompensa Cívica por Verificación:** La resolución exitosa de un reporte otorga un bono de **+50 XP** al usuario que propuso la evidencia aceptada.

## 3.5. Reglas de Alcance Geográfico
* **RN-12 (Delimitación Territorial y Catálogo Oficial Urbano DANE):**
  * VIGÍA opera sobre la infraestructura vial y espacio público urbano de las principales ciudades y aglomeraciones metropolitanas de Colombia registradas en la tabla `ciudad_cobertura`:
    1. Las 32 capitales de departamento de Colombia.
    2. Ciudades y municipios no capitales con población urbana superior a 100.000 habitantes o pertenecientes a áreas metropolitanas consolidadas (ej. Palmira, Tuluá, Buenaventura, Soledad, Bello, Itagüí, Soacha, Floridablanca).
  * Quedan excluidas las vías rurales terciarias (trochas) y carreteras interdepartamentales concesionadas (ANI / Invías).
  * Las coordenadas registradas deben ubicarse estrictamente dentro del Bounding Box del territorio continental colombiano (Latitud entre -4.2° y 13.5°, Longitud entre -79.0° y -66.8°).

## 3.6. Reglas de Notificaciones del Sistema
* **RN-13 (Generación, Persistencia y Matriz de Notificaciones Cívicas):**
  * El sistema almacena persistentemente en la tabla `notificacion` todas las novedades cívicas del usuario para alimentar el Centro de Alertas (Campanita).
  * **Notificaciones Prioritarias / Push:**
    1. *`VALIDACION_COMUNITARIA`:* Cuando un reporte propio alcanza los 10 apoyos.
    2. *`PROPUESTA_RESOLUCION`:* Cuando un vecino sugiere con foto que un reporte del autor ha sido reparado.
    3. *`REPORTE_RESUELTO`:* Cuando un reporte que el usuario sigue o reportó es marcado como solucionado.
  * **Notificaciones In-App Silenciosas:** 
    1. *`NUEVO_APOYO`:* Incrementos individuales de upvotes en publicaciones propias.
    2. *`NUEVO_COMENTARIO`:* Participaciones de debate en reportes suscritos.
    3. *`SUBIDA_RANGO` y `NUEVA_INSIGNIA`:* Hitos de gamificación celebrados mediante modales o banners interactivos en la sesión activa.

## 3.7. Reglas de Autenticación, Onboarding y Resumen de Perfil
* **RN-14 (Registro, Manejo de Ubicación y Redirección a Perfil):**
  * **Registro:** Requiere obligatoriamente nombre completo, correo electrónico único, contraseña con hash seguro y selector de ciudad de referencia (`ciudad_referencia` del catálogo oficial). No se exige barrio ni comuna para eliminar fricción de onboarding.
  * **Permiso de Ubicación en Tiempo de Uso ("When in use"):** Al iniciar la app, se solicita permiso de GPS del sistema operativo para centrar dinámicamente el mapa y feed en la posición del usuario.
  * **Planes de Mitigación ante Rechazo de Ubicación y Zonas sin Cobertura:**
    1. *Permiso Concedido:* Centrado automático en coordenadas GPS en vivo.
    2. *Permiso Denegado:* La aplicación permanece 100% operativa. Muestra un banner no intrusivo con botón **"Activar ubicación"** (que vuelve a solicitar permiso o abre ajustes del SO) y sitúa el mapa en la última ciudad activa del usuario (`usuario.ultima_ciudad`).
    3. *Búsqueda de Ciudades:* Todos los usuarios disponen de un selector/buscador de ciudades en el mapa. Si un usuario sin GPS busca otra ciudad (ej. Bogotá), el mapa navega allí y actualiza `usuario.ultima_ciudad = 'Bogotá'` para sus siguientes aperturas.
    4. *Apertura en Zona Rural / Fuera de Cobertura:* Si el GPS detecta una ubicación fuera de las ciudades catalogadas, la app mantiene la visualización en la última ciudad urbana activa (`ultima_ciudad`) con un mensaje informativo sutil.
    5. *Creación de Reporte sin GPS:* El usuario puede mover el pin manualmente en el mapa o buscar una dirección aproximada por texto.
  * **Redirección Inmediata Post-Login:** Tras autenticarse (registro o inicio de sesión), el sistema dirige al usuario directamente a la **Pantalla de Resumen de Perfil (Dashboard Cívico)**, donde visualiza su avatar, nivel cívico inicial (*Observador Urbano*), saldo de XP, ciudad de referencia y estadísticas personales.


