# Documento 4: Pendientes y decisiones para debatir

Estado al 9 de octubre de 2026. El modelo entidad-relación ya está entregado. Este documento junta lo que falta decidir con el grupo antes de tocar el modelo o el prototipo.

## 4.1. Decisión principal: alcance de VIGÍA
Los docs dicen que VIGÍA es 100% ciudadana (sin interacción con entidades). El prototipo muestra seguimiento oficial del trámite.
- **Opción A: solo ciudadana (recomendada).** Se ajusta el prototipo a los docs. El modelo casi no cambia.
- **Opción B: con seguimiento del trámite.** Hay que agregar una tabla de hitos (por ejemplo `hito_reporte`: fecha, tipo de paso, número de oficio), el estado `EN_OBRA` en `reporte.estado_actual` y reescribir el "fuera de alcance" de los docs.

Decisión del grupo: _pendiente_.

## 4.2. Ajustes al prototipo (si se elige la opción A)
1. Quitar la "Trazabilidad del Trámite" del detalle (oficio a Sec. Infraestructura, plazo legal de 72h, `#RAD-INF-99120`).
2. Quitar menciones a la Alcaldía y al IDU (pantalla de resumen) y el estado "En obra".
3. Unificar ciudad: los pasos de ubicación y resumen siguen en Bogotá (Av. Caracas, Teusaquillo); el resto está en Cali.
4. Umbral de validación comunitaria: usar 10 apoyos. Hoy el detalle dice "Meta distrital: 60", "Faltan 12" y "40+ firmas".
5. Agregar en el wizard los campos de título y descripción (son obligatorios en el modelo) y la selección de severidad (Baja, Media, Alta, Crítica).
6. Dashboard: el rango mostrado (Nivel 3 con 2,450 XP, siguiente en 3,000) no cuadra con la escala de XP de las reglas (Nivel 3 desde 2,500, Nivel 4 desde 4,000).
7. Dashboard: "Insignias 4 de 8" no cuadra con las 5 insignias definidas, y algunos nombres cambian ("Veedor Verif.", "Voz Granada").
8. Dashboard: las métricas "Obras intervenidas" y "Vecinos prevenidos" no tienen fuente en el modelo. Quitarlas o definirlas.
9. Feed: "5 veedores" y "validado por 12 veedores". Hoy solo existe el rol Ciudadano. Cambiar el texto por "apoyos" o definir el rol.
10. Borrar la pantalla vieja de resumen en tema oscuro (de 5 pasos) del proyecto en Stitch.

## 4.3. Posibles ampliaciones del modelo (opcionales)
- **Login social (Google, Apple, Facebook):** hoy `usuario` solo tiene correo y contraseña opcional. Opciones: campo `proveedor_auth` en `usuario` o tabla `identidad_externa`.
- **Notificaciones:** la pantalla de notificaciones pide al menos 2 eventos. Si la lista se guarda, agregar tabla `notificacion`. Si son avisos en vivo, no hace falta. Si hay push, evaluar una tabla de tokens de dispositivo.
- **Rol de moderación:** se propuso un rol de moderador. Sin decidir.

## 4.4. Mejoras menores del modelo
- Definir quién marca un reporte como `RESUELTO` y cómo.
- Índice único parcial para que cada reporte tenga una sola foto con `es_principal = TRUE`.
- Justificar o ajustar la tercera forma normal: `id_rango` depende de `puntos_experiencia` (dependencia transitiva).
- Soporte para varias ciudades (hoy `ciudad` tiene valor por defecto 'Cali').

## 4.5. Ya resuelto en esta entrega
- Rangos de XP sin solapamiento (RN-09).
- Umbral de validación unificado en 10 apoyos en los docs.
- `foto_comentario` alineada con el PDF (llave primaria `id_comentario`).
- `reporte.id_usuario_reportante` con `ON DELETE RESTRICT`.
- Datos semilla de rangos, categorías e insignias en `schema.sql`.
