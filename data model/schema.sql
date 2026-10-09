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

-- 2. TABLA: usuario (Ciudadanos Registrados)
CREATE TABLE usuario (
    id_usuario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_rango INT NOT NULL,
    nombre_completo VARCHAR(120) NOT NULL,
    correo_electronico VARCHAR(150) NOT NULL UNIQUE,
    hash_contrasena VARCHAR(255) NULL,
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
    
    CONSTRAINT fk_reporte_usuario 
        FOREIGN KEY (id_usuario_reportante) 
        REFERENCES usuario (id_usuario) 
        ON DELETE CASCADE,
        
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
    id_foto_comentario UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_comentario UUID NOT NULL UNIQUE,
    url_archivo VARCHAR(500) NOT NULL,
    fecha_subida TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_foto_comentario_comentario 
        FOREIGN KEY (id_comentario) 
        REFERENCES comentario (id_comentario) 
        ON DELETE CASCADE
);

-- 10. TABLA: apoyo_reporte (Votos Comunitarios / Upvotes - N:M)
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

-- 11. TABLA: seguimiento_reporte (Campanita de Alertas - N:M)
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

-- ÍNDICES ESTRATÉGICOS
CREATE INDEX idx_reporte_coordenadas ON reporte (latitud, longitud);
CREATE INDEX idx_reporte_barrio ON reporte (barrio);
CREATE INDEX idx_reporte_categoria ON reporte (id_categoria);
CREATE INDEX idx_reporte_fecha_creacion ON reporte (fecha_creacion DESC);
CREATE INDEX idx_reporte_usuario ON reporte (id_usuario_reportante);
CREATE INDEX idx_comentario_reporte ON comentario (id_reporte, fecha_creacion ASC);
CREATE INDEX idx_apoyo_reporte_id ON apoyo_reporte (id_reporte);