-- =============================================================================
-- VIGÍA - PLATAFORMA DE AUDITORÍA Y CONTROL CIUDADANO VIAL
-- ESQUEMA RELACIONAL (DDL) - TERCERA FORMA NORMAL (3FN)
-- MOTOR: PostgreSQL 14+
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLA: rango_civico (Catálogo Maestro de Niveles)
CREATE TABLE rango_civico (
    id_rango SERIAL PRIMARY KEY,
    nombre VARCHAR(50) NOT NULL UNIQUE,
    xp_minimo INT NOT NULL CHECK (xp_minimo >= 0),
    url_icono VARCHAR(500) NULL
);

-- 2. TABLA: ciudad_cobertura (Catálogo Oficial de Ciudades Urbanas de Cobertura DANE)
CREATE TABLE ciudad_cobertura (
    id_ciudad SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL,
    departamento VARCHAR(80) NOT NULL,
    latitud_centro DECIMAL(10, 8) NOT NULL,
    longitud_centro DECIMAL(11, 8) NOT NULL,
    es_capital BOOLEAN NOT NULL DEFAULT FALSE,
    activa BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT uq_ciudad_departamento UNIQUE (nombre, departamento)
);

-- 3. TABLA: usuario (Ciudadanos Registrados)
CREATE TABLE usuario (
    id_usuario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_rango INT NOT NULL,
    nombre_completo VARCHAR(120) NOT NULL,
    correo_electronico VARCHAR(150) NOT NULL UNIQUE,
    hash_contrasena VARCHAR(255) NULL,
    proveedor_auth VARCHAR(30) NOT NULL DEFAULT 'LOCAL'
        CHECK (proveedor_auth IN ('LOCAL', 'GOOGLE', 'APPLE')),
    ciudad_referencia VARCHAR(80) NOT NULL DEFAULT 'Cali',
    ultima_ciudad VARCHAR(80) NOT NULL DEFAULT 'Cali',
    url_foto_perfil VARCHAR(500) NULL,
    puntos_experiencia INT NOT NULL DEFAULT 0 CHECK (puntos_experiencia >= 0),
    fecha_registro TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    activo BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT fk_usuario_rango 
        FOREIGN KEY (id_rango) 
        REFERENCES rango_civico (id_rango) 
        ON DELETE RESTRICT
);

-- 3. TABLA: insignia (Catálogo Maestro de Medallas Cívicas)
CREATE TABLE insignia (
    id_insignia SERIAL PRIMARY KEY,
    codigo_clave VARCHAR(50) NOT NULL UNIQUE,
    nombre VARCHAR(80) NOT NULL,
    descripcion VARCHAR(255) NOT NULL,
    url_icono VARCHAR(500) NOT NULL
);

-- 4. TABLA: usuario_insignia (Relación N:M Usuario - Insignia)
CREATE TABLE usuario_insignia (
    id_usuario UUID NOT NULL,
    id_insignia INT NOT NULL,
    fecha_obtencion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_usuario, id_insignia),
    
    CONSTRAINT fk_usuario_insignia_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_usuario_insignia_insignia 
        FOREIGN KEY (id_insignia) 
        REFERENCES insignia (id_insignia) 
        ON DELETE CASCADE
);

-- 5. TABLA: categoria_reporte (Taxonomía de Incidencias)
CREATE TABLE categoria_reporte (
    id_categoria SERIAL PRIMARY KEY,
    nombre VARCHAR(80) NOT NULL UNIQUE,
    icono VARCHAR(50) NOT NULL,
    descripcion VARCHAR(255) NULL
);

-- 6. TABLA: reporte (Publicación de Incidencia Vial)
CREATE TABLE reporte (
    id_reporte UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    radicado_codigo VARCHAR(30) NOT NULL UNIQUE,
    id_usuario_reportante UUID NOT NULL,
    id_categoria INT NOT NULL,
    titulo VARCHAR(180) NOT NULL,
    descripcion TEXT NOT NULL,
    prioridad VARCHAR(20) NOT NULL DEFAULT 'MEDIA' 
        CHECK (prioridad IN ('BAJA', 'MEDIA', 'ALTA', 'CRITICA')),
    estado_actual VARCHAR(30) NOT NULL DEFAULT 'REPORTADO'
        CHECK (estado_actual IN ('REPORTADO', 'EN_REVISION', 'VALIDADO_COMUNIDAD', 'RESUELTO')),
    dimensiones_estimadas VARCHAR(100) NULL,
    latitud DECIMAL(10, 8) NOT NULL CHECK (latitud BETWEEN -90.00000000 AND 90.00000000),
    longitud DECIMAL(11, 8) NOT NULL CHECK (longitud BETWEEN -180.00000000 AND 180.00000000),
    direccion_formateada VARCHAR(255) NOT NULL,
    barrio VARCHAR(100) NOT NULL,
    ciudad VARCHAR(80) NOT NULL DEFAULT 'Cali',
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_actualizacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMPTZ NULL,
    id_usuario_resolucion UUID NULL,
    
    CONSTRAINT fk_reporte_usuario 
        FOREIGN KEY (id_usuario_reportante) 
        REFERENCES usuario (id_usuario)
        ON DELETE RESTRICT,

    CONSTRAINT fk_reporte_usuario_resolucion
        FOREIGN KEY (id_usuario_resolucion)
        REFERENCES usuario (id_usuario)
        ON DELETE SET NULL,

    CONSTRAINT fk_reporte_categoria 
        FOREIGN KEY (id_categoria) 
        REFERENCES categoria_reporte (id_categoria) 
        ON DELETE RESTRICT
);

-- 7. TABLA: foto_reporte (Evidencias de la Vía - 1:N)
CREATE TABLE foto_reporte (
    id_foto_reporte UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_reporte UUID NOT NULL,
    url_archivo VARCHAR(500) NOT NULL,
    es_principal BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_subida TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_foto_reporte_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE
);

-- 8. TABLA: comentario (Hilo de Discusión Ciudadana)
CREATE TABLE comentario (
    id_comentario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_reporte UUID NOT NULL,
    id_usuario UUID NOT NULL,
    contenido TEXT NOT NULL,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_comentario_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_comentario_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE
);

-- 9. TABLA: foto_comentario (Foto Opcional en Comentarios - 0..1:1)
CREATE TABLE foto_comentario (
    id_comentario UUID PRIMARY KEY,
    url_archivo VARCHAR(500) NOT NULL,
    fecha_subida TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_foto_comentario_comentario 
        FOREIGN KEY (id_comentario) 
        REFERENCES comentario (id_comentario) 
        ON DELETE CASCADE
);

-- 10. TABLA: resolucion_reporte (Propuesta Formal de Cierre y Verificación Comunitaria)
CREATE TABLE resolucion_reporte (
    id_resolucion UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_reporte UUID NOT NULL,
    id_usuario_proponente UUID NOT NULL,
    url_foto_evidencia VARCHAR(500) NOT NULL,
    descripcion TEXT NOT NULL,
    estado VARCHAR(30) NOT NULL DEFAULT 'PENDIENTE'
        CHECK (estado IN ('PENDIENTE', 'APROBADA_AUTOR', 'APROBADA_COMUNIDAD', 'RECHAZADA')),
    votos_confirmacion INT NOT NULL DEFAULT 0 CHECK (votos_confirmacion >= 0),
    fecha_propuesta TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    fecha_resolucion TIMESTAMPTZ NULL,
    id_usuario_aprobador UUID NULL,
    motivo_rechazo TEXT NULL,
    
    CONSTRAINT fk_resolucion_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_resolucion_proponente 
        FOREIGN KEY (id_usuario_proponente) 
        REFERENCES usuario (id_usuario) 
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_resolucion_aprobador 
        FOREIGN KEY (id_usuario_aprobador) 
        REFERENCES usuario (id_usuario) 
        ON DELETE SET NULL
);

-- 11. TABLA: confirmacion_resolucion (Votos de Verificación Ciudadana - N:M)
CREATE TABLE confirmacion_resolucion (
    id_usuario UUID NOT NULL,
    id_resolucion UUID NOT NULL,
    fecha_confirmacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_usuario, id_resolucion),
    
    CONSTRAINT fk_confirmacion_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_confirmacion_resolucion 
        FOREIGN KEY (id_resolucion) 
        REFERENCES resolucion_reporte (id_resolucion) 
        ON DELETE CASCADE
);

-- 12. TABLA: apoyo_reporte (Votos Comunitarios / Upvotes - N:M)
CREATE TABLE apoyo_reporte (
    id_usuario UUID NOT NULL,
    id_reporte UUID NOT NULL,
    fecha_apoyo TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_usuario, id_reporte),
    
    CONSTRAINT fk_apoyo_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_apoyo_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE
);

-- 13. TABLA: seguimiento_reporte (Campanita de Alertas - N:M)
CREATE TABLE seguimiento_reporte (
    id_usuario UUID NOT NULL,
    id_reporte UUID NOT NULL,
    fecha_seguimiento TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_usuario, id_reporte),
    
    CONSTRAINT fk_seguimiento_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_seguimiento_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE
);

-- 14. TABLA: notificacion (Alertas y Novedades del Ciudadano)
CREATE TABLE notificacion (
    id_notificacion UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_usuario UUID NOT NULL,
    id_reporte UUID NULL,
    tipo VARCHAR(50) NOT NULL 
        CHECK (tipo IN ('VALIDACION_COMUNITARIA', 'NUEVO_APOYO', 'NUEVO_COMENTARIO', 'PROPUESTA_RESOLUCION', 'REPORTE_RESUELTO', 'SUBIDA_RANGO', 'NUEVA_INSIGNIA')),
    titulo VARCHAR(120) NOT NULL,
    mensaje TEXT NOT NULL,
    leida BOOLEAN NOT NULL DEFAULT FALSE,
    fecha_creacion TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_notificacion_usuario 
        FOREIGN KEY (id_usuario) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_notificacion_reporte 
        FOREIGN KEY (id_reporte) 
        REFERENCES reporte (id_reporte) 
        ON DELETE CASCADE
);

-- ÍNDICES ESTRATÉGICOS
CREATE INDEX idx_reporte_coordenadas ON reporte (latitud, longitud);
CREATE INDEX idx_reporte_barrio ON reporte (barrio);
CREATE INDEX idx_reporte_categoria ON reporte (id_categoria);
CREATE INDEX idx_reporte_fecha_creacion ON reporte (fecha_creacion DESC);
CREATE INDEX idx_reporte_usuario ON reporte (id_usuario_reportante);
CREATE INDEX idx_comentario_reporte ON comentario (id_reporte, fecha_creacion ASC);
CREATE INDEX idx_apoyo_reporte_id ON apoyo_reporte (id_reporte);
CREATE INDEX idx_notificacion_usuario ON notificacion (id_usuario, leida, fecha_creacion DESC);
CREATE INDEX idx_resolucion_reporte ON resolucion_reporte (id_reporte, estado);

-- Índice único parcial: asegura que solo haya como máximo 1 foto principal por reporte
CREATE UNIQUE INDEX idx_foto_principal_unica ON foto_reporte (id_reporte) WHERE es_principal = TRUE;


-- =============================================================================
-- DATOS SEMILLA
-- =============================================================================

-- Rangos cívicos
INSERT INTO rango_civico (nombre, xp_minimo, url_icono) VALUES
    ('Observador Urbano', 0, NULL),
    ('Vecino Activo', 1000, NULL),
    ('Guardián Vial', 2500, NULL),
    ('Veedor Maestro', 4000, NULL)
ON CONFLICT (nombre) DO NOTHING;

-- Categorías de reporte (icono = nombre de ícono Material)
INSERT INTO categoria_reporte (nombre, icono, descripcion) VALUES
    ('Hueco o Bache', 'warning', 'Huecos, baches o hundimientos en la calzada.'),
    ('Semáforo', 'traffic', 'Semáforos dañados, apagados o desincronizados.'),
    ('Obra Paralizada', 'construction', 'Obras viales detenidas o abandonadas.'),
    ('Andén', 'directions_walk', 'Andenes deteriorados u obstruidos para el peatón.'),
    ('Fuga de Agua', 'water_drop', 'Fugas de agua potable o aguas residuales en la vía.'),
    ('Señalización', 'signpost', 'Señales de tránsito ausentes, dañadas o ilegibles.'),
    ('Otro', 'more_horiz', 'Otras incidencias viales no clasificadas.')
ON CONFLICT (nombre) DO NOTHING;

-- Insignias
INSERT INTO insignia (codigo_clave, nombre, descripcion, url_icono) VALUES
    ('PRIMER_PASO_CIVICO', 'Primer Paso Cívico', 'Publicaste tu primer reporte.', 'https://example.com/insignias/primer_paso_civico.png'),
    ('VOZ_ACTIVA', 'Voz Activa', 'Realizaste 10 comentarios en discusiones comunitarias.', 'https://example.com/insignias/voz_activa.png'),
    ('CAZADOR_DE_BACHES', 'Cazador de Baches', 'Publicaste 5 reportes en la categoría Hueco o Bache.', 'https://example.com/insignias/cazador_de_baches.png'),
    ('REPORTE_DE_ALTO_IMPACTO', 'Reporte de Alto Impacto', 'Uno de tus reportes alcanzó 10 apoyos.', 'https://example.com/insignias/reporte_de_alto_impacto.png'),
    ('GUARDIAN_COMUNITARIO', 'Guardián Comunitario', 'Otorgaste 50 apoyos a reportes de otros vecinos.', 'https://example.com/insignias/guardian_comunitario.png')
ON CONFLICT (codigo_clave) DO NOTHING;

-- Ciudades de Cobertura Urbana (32 Capitales + Ciudades Principales > 100k hab DANE)
INSERT INTO ciudad_cobertura (nombre, departamento, latitud_centro, longitud_centro, es_capital) VALUES
    ('Cali', 'Valle del Cauca', 3.45160000, -76.53200000, TRUE),
    ('Bogotá', 'Bogotá D.C.', 4.71100000, -74.07210000, TRUE),
    ('Medellín', 'Antioquia', 6.24420000, -75.58120000, TRUE),
    ('Barranquilla', 'Atlántico', 10.96850000, -74.78130000, TRUE),
    ('Cartagena', 'Bolívar', 10.39100000, -75.47940000, TRUE),
    ('Bucaramanga', 'Santander', 7.12540000, -73.11980000, TRUE),
    ('Cúcuta', 'Norte de Santander', 7.89390000, -72.50780000, TRUE),
    ('Pereira', 'Risaralda', 4.81330000, -75.69610000, TRUE),
    ('Santa Marta', 'Magdalena', 11.24080000, -74.19900000, TRUE),
    ('Ibagué', 'Tolima', 4.43890000, -75.23220000, TRUE),
    ('Pasto', 'Nariño', 1.21360000, -77.28110000, TRUE),
    ('Manizales', 'Caldas', 5.06890000, -75.51740000, TRUE),
    ('Neiva', 'Huila', 2.92730000, -75.28190000, TRUE),
    ('Villavicencio', 'Meta', 4.14200000, -73.62660000, TRUE),
    ('Armenia', 'Quindío', 4.53390000, -75.68110000, TRUE),
    ('Valledupar', 'Cesar', 10.46310000, -73.25320000, TRUE),
    ('Montería', 'Córdoba', 8.74790000, -75.88140000, TRUE),
    ('Sincelejo', 'Sucre', 9.30470000, -75.39780000, TRUE),
    ('Popayán', 'Cauca', 2.44480000, -76.61470000, TRUE),
    ('Tunja', 'Boyacá', 5.53530000, -73.36780000, TRUE),
    ('Riohacha', 'La Guajira', 11.54440000, -72.90720000, TRUE),
    ('Florencia', 'Caquetá', 1.61440000, -75.60620000, TRUE),
    ('Quibdó', 'Chocó', 5.69470000, -76.66110000, TRUE),
    ('Yopal', 'Casanare', 5.33780000, -72.39590000, TRUE),
    ('San Andrés', 'San Andrés y Providencia', 12.58470000, -81.70060000, TRUE),
    ('Mocoa', 'Putumayo', 1.14780000, -76.64640000, TRUE),
    ('Arauca', 'Arauca', 7.08470000, -70.75910000, TRUE),
    ('San José del Guaviare', 'Guaviare', 2.57290000, -72.64590000, TRUE),
    ('Leticia', 'Amazonas', -4.21530000, -69.94060000, TRUE),
    ('Inírida', 'Guainía', 3.86530000, -67.92390000, TRUE),
    ('Mitú', 'Vaupés', 1.25280000, -70.23330000, TRUE),
    ('Puerto Carreño', 'Vichada', 6.18900000, -67.48590000, TRUE),
    -- Municipios no capitales > 100k hab / Áreas Metropolitanas
    ('Palmira', 'Valle del Cauca', 3.53940000, -76.30360000, FALSE),
    ('Buenaventura', 'Valle del Cauca', 3.88010000, -77.03120000, FALSE),
    ('Tuluá', 'Valle del Cauca', 4.08470000, -76.19540000, FALSE),
    ('Cartago', 'Valle del Cauca', 4.74640000, -75.91170000, FALSE),
    ('Jamundí', 'Valle del Cauca', 3.26060000, -76.54140000, FALSE),
    ('Yumbo', 'Valle del Cauca', 3.58220000, -76.49580000, FALSE),
    ('Bello', 'Antioquia', 6.33730000, -75.55790000, FALSE),
    ('Itagüí', 'Antioquia', 6.18460000, -75.59910000, FALSE),
    ('Envigado', 'Antioquia', 6.16900000, -75.58740000, FALSE),
    ('Rionegro', 'Antioquia', 6.15520000, -75.37370000, FALSE),
    ('Soledad', 'Atlántico', 10.91850000, -74.76460000, FALSE),
    ('Floridablanca', 'Santander', 7.06220000, -73.08640000, FALSE),
    ('Barrancabermeja', 'Santander', 7.06530000, -73.85470000, FALSE),
    ('Soacha', 'Cundinamarca', 4.58040000, -74.21690000, FALSE),
    ('Chía', 'Cundinamarca', 4.86140000, -74.05920000, FALSE),
    ('Zipaquirá', 'Cundinamarca', 5.02610000, -74.00390000, FALSE),
    ('Facatativá', 'Cundinamarca', 4.81420000, -74.35420000, FALSE),
    ('Duitama', 'Boyacá', 5.82450000, -73.03410000, FALSE),
    ('Sogamoso', 'Boyacá', 5.71450000, -72.93390000, FALSE)
ON CONFLICT (nombre, departamento) DO NOTHING;