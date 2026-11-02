# Documento 1: Planteamiento del Problema, Solución y Actores

## 1.1. Contexto y Problema
En entornos urbanos, el deterioro constante de la malla vial y del espacio público (baches, andenes destruidos, alcantarillado averiado, semáforos defectuosos y obras paralizadas) perjudica la movilidad, daña vehículos y genera riesgos constantes de accidentes para peatones, ciclistas y conductores.

Actualmente, la gestión ciudadana de estos problemas presenta dos fallas críticas:
1. **Opacidad y dispersión de las quejas:** Los ciudadanos publican quejas aisladas en redes sociales o grupos de mensajería vecinal sin georreferenciación estandarizada, perdiendo visibilidad e impacto.
2. **Invisibilidad del descontento colectivo:** Las denuncias individuales no reflejan la magnitud real del problema. No existe una herramienta cívica abierta y pacífica que consolide la evidencia con respaldo comunitario para evidenciar públicamente los puntos más críticos de la ciudad.

## 1.2. La Solución (VIGÍA)
**VIGÍA** es una plataforma cívica colaborativa (web y móvil) de auditoría abierta y control ciudadano que permite:
* Registrar daños viales en un mapa interactivo con ubicación exacta por coordenadas, fotografía de evidencia y tipificación estructurada.
* Explorar y filtrar incidentes mediante cartografía en tiempo real y un feed comunitario unificado.
* Amplificar problemáticas mediante el respaldo colectivo (*upvoting* o votos de impulso) y debates en hilos de comentarios vecinales.
* Incentivar el compromiso cívico continuo mediante un **Dashboard de Impacto Personal**, rangos y logros cívicos (*gamificación sutil y transparente*).

## 1.3. Alcance del Sistema
### Dentro del Alcance (In Scope)
* **Gestión de Identidad:** Registro y autenticación ciudadana (correo/contraseña y proveedores Google, Apple, Facebook), además de navegación en modo invitado/anónimo.
* **Módulo Cartográfico y Exploración:** Visualización interactiva de daños en mapa georreferenciado y feed comunitario, con filtros sincronizados.
* **Flujo Guiado de Reporte (Wizard en 4 Pasos):** Ubicación en mapa $\rightarrow$ Evidencia fotográfica $\rightarrow$ Tipo/severidad del daño $\rightarrow$ Confirmación y generación de radicado cívico público.
* **Interacción y Presión Colectiva:** Votos de impulso (*upvotes* con prevención de duplicados y autovoto) y comentarios vecinales cronológicos (con opción de adjuntar 1 fotografía de evidencia complementaria, no obligatoria).
* **Validación Comunitaria:** Reconocimiento de reportes que superan el umbral de respaldo comunitario (10 upvotes).
* **Dashboard y Gamificación Cívica:** Registro de métricas personales de participación (reportes creados, upvotes recibidos, upvotes otorgados, comentarios), acumulación de experiencia (XP), niveles cívicos e insignias.

### Fuera del Alcance (Out of Scope - Delimitación Explícita)
* **Interacción Directa con Entidades Gubernamentales:** La plataforma no gestiona trámites ante secretarías de infraestructura, alcaldías ni contratistas dentro de su flujo de software, manteniéndose como una herramienta 100% ciudadana, comunitaria e independiente.
* **Despacho Operativo:** No incluye asignación de cuadrillas ni programación de obras públicas.
* **Trámites Estatales Internos:** Toda acción legal, derecho de petición o notificación formal a entes gubernamentales es potestad externa de la comunidad.

## 1.4. Actores del Sistema
1. **Visitante / Veedor Anónimo:**
   * Accede a la plataforma sin credenciales.
   * Puede consultar el mapa general, explorar el feed comunitario y ver el detalle de los reportes.
   * No puede crear reportes, votar (*upvote*), comentar ni acumular experiencia.
2. **Ciudadano Registrado:**
   * Usuario autenticado con perfil activo.
   * Crea reportes viales con evidencia fotográfica.
   * Apoya reportes ajenos (*upvote*), participa en discusiones de comentarios (pudiendo adjuntar 1 foto opcional) y sigue reportes de interés.
   * Administra sus propios reportes (edición/eliminación bajo ventana de tiempo).
   * Consulta su Dashboard Cívico para monitorear su impacto, nivel y logros.
3. **Veedor Comunitario Destacado:**
   * Ciudadano con alto nivel cívico acumulado en la plataforma gracias a reportes validados por la comunidad.
   * Cuenta con insignias públicas visibles que otorgan mayor credibilidad comunitaria a sus contribuciones.
