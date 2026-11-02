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
