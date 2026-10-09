# Documento 2: Arquitectura de Pantallas y Flujos de Usuario

## 2.1. Mapa de Pantallas Principales

### Pantalla 0: Autenticación y Acceso
* Inicio de sesión y registro mediante correo/contraseña o inicio de sesión social (Google, Apple, Facebook).
* Acceso directo en modo *"Veedor Anónimo / Invitado"* para consulta rápida sin fricción.

### Pantalla 1: Mapa General de Obras (Home Cartográfico)
* Mapa interactivo a pantalla completa centrado en la ciudad con pines clasificados por ícono y categoría de daño.
* **Barra Unificada de Filtros:**
  * **Categoría:** *Todos, Huecos/Baches, Semáforos, Obras Paradas, Andenes, Fugas de Agua, Señalización*.
  * **Sector/Barrio:** Selector por lista o búsqueda de zonas.
  * **Criterio de Relevancia:** *Más Votados, Recientes, Críticos, Validados por la Comunidad (+10 votos)*.
* Tarjeta flotante interactiva (*Liquid Card*) al seleccionar un marcador con resumen, apoyos recibidos y acceso al detalle.
* Botón de acción flotante (*FAB*): *"Reportar Vía / Obra"*.

### Flujo de Creación de Reporte (Wizard en 4 Pasos)
* **Paso 1 - Fijar Ubicación:**
  * Mapa con mira interactiva para georreferenciación exacta vía GPS o pin manual.
  * Extracción automática de dirección aproximada, barrio y localidad/comuna con opción de ajuste manual.
* **Paso 2 - Evidencia Fotográfica:**
  * Captura directa desde la cámara del dispositivo o selección desde la galería (máximo 3 fotos).
  * Validación visual de calidad/nitidez. Opción de omitir fotografía si no se dispone de ella.
* **Paso 3 - Tipo y Severidad:**
  * Selección de la tipología del daño mediante tarjetas descriptivas con íconos.
  * Selección del nivel de severidad percibido (*Baja, Media, Alta, Crítica*).
  * Campo opcional para dimensiones aproximadas (ej. *~1.2m x 18cm de fondo*).
* **Paso 4 - Resumen y Confirmación:**
  * Tarjeta de consolidación con ubicación, fotografía previa, categoría y fecha/hora.
  * Confirmación de publicación con generación de código de radicado cívico público (ej. `#VIG-8492`).

### Pantalla 2: Feed Comunitario (Comunidad)
* Listado de tarjetas de reporte en scroll vertical.
* **Barra de Filtros y Búsqueda (Sincronizada con Pantalla 1):**
  * Buscador por texto libre (descripción o dirección).
  * Chips de categoría (*Huecos, Semáforos, etc.*) y filtro por sector/barrio.
  * Pestañas de ordenación: *Más Votados*, *Más Recientes*, *Más Cercanos*.
* Cada tarjeta de reporte muestra: foto de portada, título, barrio, autor con su nivel cívico, etiqueta de prioridad, botón de apoyo rápido (*Upvote*) con contador en vivo y contador de comentarios.

### Pantalla 3A: Detalle del Reporte (Vista de Vecino / Tercero)
* Carrusel o galería de fotografías de evidencia con coordenadas exactas y fecha de captura.
* Información del autor del reporte (nombre, barrio, rango cívico actual).
* Descripción del problema, dimensiones e impacto vial reportado.
* **Barra de Voz Colectiva:** Contador de apoyos y barra de progreso hacia la validación comunitaria.
* **Botón Principal de Apoyo:** Botón *"Impulsar Reporte (+1 Voto)"* (permite retirar el voto si ya se otorgó).
* **Botón de Notificación (Campana):** Suscribirse para recibir alertas sobre nuevos comentarios o hitos del reporte.
* **Hilo de Discusión:** Lista de comentarios cronológicos con avatar, rango del usuario, texto del comentario y soporte para visualización de imagen adjunta. Incluye caja de texto y botón para adjuntar 1 fotografía opcional (desde cámara o galería) como evidencia o seguimiento complementario (no obligatoria).

### Pantalla 3B: Detalle del Reporte (Vista de Autor / Mi Reporte)
* Muestra la información completa del incidente reportado por el propio usuario.
* **Sin botón de suscripción:** El autor está suscrito por defecto a su propia publicación.
* **Sin botón de upvote:** No se permite el autovoto.
* **Tarjeta de Validación Comunitaria (Gamificación Sutil):**
  * Indicador de progreso: *"X de 10 apoyos recibidos para Validación Comunitaria"*.
  * Mensaje dinámico de incentivo: *"Faltan Y votos para validar este reporte (+500 XP)"*.
  * Si ya superó los 10 votos: Sello visible de *"Reporte Validado por la Comunidad"*.
* **Gestión del Reporte:** Acciones de *Editar* o *Eliminar* habilitadas únicamente si cumple la ventana de 30 minutos y menos de 5 upvotes (RN-03).

### Pantalla 4: Dashboard Cívico (Perfil y Engagement)
* **Encabezado de Identidad Cívica:** Avatar, nombre del ciudadano, rango actual (ej. *Nivel 3 - Guardián Vial*) y barra de progreso de XP hacia el siguiente nivel.
* **Métricas Personales de Impacto Ciudadano:**
  1. **Reportes Creados:** Total histórico de incidentes publicados.
  2. **Upvotes Recibidos:** Total de apoyos que la comunidad ha otorgado a los reportes del usuario (métrica clave de impacto colectivo).
  3. **Upvotes Otorgados:** Total de apoyos dados a reportes de otros vecinos.
  4. **Comentarios Realizados:** Total de participaciones y aportes en hilos de discusión.
* **Galería de Insignias Cívicas:** Cuadrícula con insignias desbloqueadas y metas para las siguientes.
* **Sección "Mis Reportes":** Listado de accesos directos a las publicaciones del usuario (redireccionan a la vista 3B).
