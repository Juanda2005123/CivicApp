-- =============================================================================
-- VIGÍA - SUPABASE SETUP SCRIPT (COMPLETE CLEAN SLATE & SEEDING)
-- RUN THIS ENTIRE SCRIPT IN SUPABASE SQL EDITOR (Dashboard -> SQL Editor -> New Query)
-- =============================================================================

-- 0. CLEAN RESET OF PUBLIC SCHEMA
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Grant required standard permissions
GRANT ALL ON SCHEMA public TO postgres;
GRANT ALL ON SCHEMA public TO anon;
GRANT ALL ON SCHEMA public TO authenticated;
GRANT ALL ON SCHEMA public TO service_role;

CREATE EXTENSION IF NOT EXISTS "uuid-ossp" WITH SCHEMA extensions;

-- =============================================================================
-- 1. RELATIONAL SCHEMA TABLES
-- =============================================================================

-- 1.1. Master Catalog of Civic Progression Ranks
CREATE TABLE public.civic_rank (
    id_rank SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    min_xp INT NOT NULL CHECK (min_xp >= 0),
    icon_url VARCHAR(500) NULL
);

-- 1.2. Official DANE Urban Municipalities Coverage Catalog
CREATE TABLE public.coverage_city (
    id_city SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    department VARCHAR(80) NOT NULL,
    center_latitude DECIMAL(10, 8) NOT NULL,
    center_longitude DECIMAL(11, 8) NOT NULL,
    is_capital BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT uq_city_department UNIQUE (name, department)
);

-- 1.3. Registered Citizen Profiles
CREATE TABLE public.user_profile (
    id_user UUID PRIMARY KEY, -- Corresponds directly to auth.users.id
    id_rank INT NOT NULL DEFAULT 1,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    auth_provider VARCHAR(30) NOT NULL DEFAULT 'LOCAL'
        CHECK (auth_provider IN ('LOCAL', 'GOOGLE', 'APPLE')),
    reference_city VARCHAR(80) NOT NULL DEFAULT 'Cali',
    last_city VARCHAR(80) NOT NULL DEFAULT 'Cali',
    profile_picture_url VARCHAR(500) NULL,
    experience_points INT NOT NULL DEFAULT 0 CHECK (experience_points >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT fk_user_rank 
        FOREIGN KEY (id_rank) 
        REFERENCES public.civic_rank (id_rank) 
        ON DELETE RESTRICT
);

-- 1.4. Master Catalog of Civic Badges & Medals
CREATE TABLE public.civic_badge (
    id_badge SERIAL PRIMARY KEY,
    key_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    description VARCHAR(255) NOT NULL,
    icon_url VARCHAR(500) NOT NULL
);

-- 1.5. Many-to-Many Relationship: User - Badge
CREATE TABLE public.user_badge (
    id_user UUID NOT NULL,
    id_badge INT NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_badge),
    
    CONSTRAINT fk_user_badge_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_user_badge_badge 
        FOREIGN KEY (id_badge) 
        REFERENCES public.civic_badge (id_badge) 
        ON DELETE CASCADE
);

-- 1.6. Taxonomy of Road Hazards and Infrastructure Damages
CREATE TABLE public.incident_category (
    id_category SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    icon VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL
);

-- 1.7. Public Road Infrastructure Hazard Report
CREATE TABLE public.road_incident (
    id_incident UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    tracking_code VARCHAR(30) NOT NULL UNIQUE,
    id_reporter_user UUID NOT NULL,
    id_category INT NOT NULL,
    title VARCHAR(180) NOT NULL,
    description TEXT NOT NULL,
    severity VARCHAR(20) NOT NULL DEFAULT 'MEDIUM' 
        CHECK (severity IN ('LOW', 'MEDIUM', 'HIGH', 'CRITICAL')),
    current_status VARCHAR(30) NOT NULL DEFAULT 'REPORTED'
        CHECK (current_status IN ('REPORTED', 'UNDER_REVIEW', 'COMMUNITY_VALIDATED', 'RESOLVED')),
    estimated_dimensions VARCHAR(100) NULL,
    latitude DECIMAL(10, 8) NOT NULL CHECK (latitude BETWEEN -90.00000000 AND 90.00000000),
    longitude DECIMAL(11, 8) NOT NULL CHECK (longitude BETWEEN -180.00000000 AND 180.00000000),
    formatted_address VARCHAR(255) NOT NULL,
    neighborhood VARCHAR(100) NOT NULL,
    city VARCHAR(80) NOT NULL DEFAULT 'Cali',
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ NULL,
    id_resolver_user UUID NULL,
    
    CONSTRAINT fk_incident_reporter_user 
        FOREIGN KEY (id_reporter_user) 
        REFERENCES public.user_profile (id_user)
        ON DELETE RESTRICT,

    CONSTRAINT fk_incident_resolver_user
        FOREIGN KEY (id_resolver_user) 
        REFERENCES public.user_profile (id_user)
        ON DELETE SET NULL,

    CONSTRAINT fk_incident_category 
        FOREIGN KEY (id_category) 
        REFERENCES public.incident_category (id_category) 
        ON DELETE RESTRICT
);

-- 1.8. Road Damage Photographic Evidence - 1:N
CREATE TABLE public.incident_photo (
    id_photo UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_incident UUID NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_incident_photo_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 1.9. Citizen Discussion Thread on Report
CREATE TABLE public.incident_comment (
    id_comment UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_incident UUID NOT NULL,
    id_user UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_comment_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_comment_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE
);

-- 1.10. Optional Single Photo Attachment in Comments - 0..1:1
CREATE TABLE public.comment_photo (
    id_comment UUID PRIMARY KEY,
    file_url VARCHAR(500) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_comment_photo_comment 
        FOREIGN KEY (id_comment) 
        REFERENCES public.incident_comment (id_comment) 
        ON DELETE CASCADE
);

-- 1.11. Formal Repair Proposal & Community Verification
CREATE TABLE public.incident_resolution (
    id_resolution UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_incident UUID NOT NULL,
    id_proponent_user UUID NOT NULL,
    photo_evidence_url VARCHAR(500) NOT NULL,
    description TEXT NOT NULL,
    status VARCHAR(30) NOT NULL DEFAULT 'PENDING'
        CHECK (status IN ('PENDING', 'APPROVED_BY_AUTHOR', 'APPROVED_BY_COMMUNITY', 'REJECTED_BY_AUTHOR', 'REJECTED_BY_COMMUNITY', 'EXPIRED')),
    confirmation_votes INT NOT NULL DEFAULT 0 CHECK (confirmation_votes >= 0),
    objection_votes INT NOT NULL DEFAULT 0 CHECK (objection_votes >= 0),
    proposed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    resolved_at TIMESTAMPTZ NULL,
    id_approver_user UUID NULL,
    rejection_reason TEXT NULL,
    
    CONSTRAINT fk_resolution_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_resolution_proponent_user 
        FOREIGN KEY (id_proponent_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_resolution_approver_user 
        FOREIGN KEY (id_approver_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE SET NULL
);

-- 1.12. Citizen Verification Votes - N:M
CREATE TABLE public.resolution_confirmation (
    id_user UUID NOT NULL,
    id_resolution UUID NOT NULL,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_resolution),
    
    CONSTRAINT fk_confirmation_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_confirmation_resolution 
        FOREIGN KEY (id_resolution) 
        REFERENCES public.incident_resolution (id_resolution) 
        ON DELETE CASCADE
);

-- 1.13. Citizen Objections for Invalid/Fraudulent Evidence - N:M
CREATE TABLE public.resolution_objection (
    id_user UUID NOT NULL,
    id_resolution UUID NOT NULL,
    reason TEXT NULL,
    objected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_resolution),
    
    CONSTRAINT fk_objection_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_objection_resolution 
        FOREIGN KEY (id_resolution) 
        REFERENCES public.incident_resolution (id_resolution) 
        ON DELETE CASCADE
);

-- 1.14. Community Backing Votes / Upvotes - N:M
CREATE TABLE public.incident_upvote (
    id_user UUID NOT NULL,
    id_incident UUID NOT NULL,
    upvoted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_incident),
    
    CONSTRAINT fk_upvote_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_upvote_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 1.15. Followed Reports / Notifications Bell - N:M
CREATE TABLE public.incident_follow (
    id_user UUID NOT NULL,
    id_incident UUID NOT NULL,
    followed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_incident),
    
    CONSTRAINT fk_follow_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_follow_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 1.16. Citizen Alerts & System Notifications
CREATE TABLE public.notification (
    id_notification UUID PRIMARY KEY DEFAULT extensions.uuid_generate_v4(),
    id_user UUID NOT NULL,
    id_incident UUID NULL,
    type VARCHAR(50) NOT NULL 
        CHECK (type IN ('COMMUNITY_VALIDATION', 'NEW_UPVOTE', 'NEW_COMMENT', 'RESOLUTION_PROPOSAL', 'REPORT_RESOLVED', 'RANK_UP', 'NEW_BADGE')),
    title VARCHAR(120) NOT NULL,
    message TEXT NOT NULL,
    is_read BOOLEAN NOT NULL DEFAULT FALSE,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_notification_user 
        FOREIGN KEY (id_user) 
        REFERENCES public.user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_notification_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES public.road_incident (id_incident) 
        ON DELETE CASCADE
);

-- =============================================================================
-- 2. INDEXES
-- =============================================================================

CREATE INDEX idx_incident_coordinates ON public.road_incident (latitude, longitude);
CREATE INDEX idx_incident_neighborhood ON public.road_incident (neighborhood);
CREATE INDEX idx_incident_category ON public.road_incident (id_category);
CREATE INDEX idx_incident_created_at ON public.road_incident (created_at DESC);
CREATE INDEX idx_incident_reporter ON public.road_incident (id_reporter_user);
CREATE INDEX idx_comment_incident ON public.incident_comment (id_incident, created_at ASC);
CREATE INDEX idx_upvote_incident_id ON public.incident_upvote (id_incident);
CREATE INDEX idx_notification_user ON public.notification (id_user, is_read, created_at DESC);
CREATE INDEX idx_resolution_incident ON public.incident_resolution (id_incident, status);
CREATE UNIQUE INDEX idx_single_primary_photo ON public.incident_photo (id_incident) WHERE is_primary = TRUE;
CREATE UNIQUE INDEX idx_single_active_resolution ON public.incident_resolution (id_incident) WHERE status = 'PENDING';

-- =============================================================================
-- 3. INITIAL SEEDS (DANE Coverage & Master Catalogs)
-- =============================================================================

-- Civic Ranks
INSERT INTO public.civic_rank (name, min_xp, icon_url) VALUES
    ('Urban Observer', 0, NULL),
    ('Active Neighbor', 1000, NULL),
    ('Road Guardian', 2500, NULL),
    ('Master Overseer', 4000, NULL);

-- Incident Categories
INSERT INTO public.incident_category (name, icon, description) VALUES
    ('Pothole or Road Hazard', 'warning', 'Potholes, cracks, craters, or pavement depressions.'),
    ('Traffic Light', 'traffic', 'Damaged, unlit, or desynchronized traffic signals.'),
    ('Abandoned Public Work', 'construction', 'Halted, abandoned, or delayed public road construction.'),
    ('Damaged Sidewalk', 'directions_walk', 'Deteriorated, broken, or obstructed pedestrian walkways.'),
    ('Water Leak', 'water_drop', 'Potable water main breaks or wastewater leaks on the road.'),
    ('Road Signage', 'signpost', 'Missing, damaged, obstructed, or illegible traffic signs.'),
    ('Other', 'more_horiz', 'Other unclassified public infrastructure hazards.');

-- Civic Badges
INSERT INTO public.civic_badge (key_code, name, description, icon_url) VALUES
    ('FIRST_CIVIC_STEP', 'First Civic Step', 'Published your first road incident report.', 'https://example.com/badges/first_step.png'),
    ('ACTIVE_VOICE', 'Active Voice', 'Posted 10 constructive comments in community discussions.', 'https://example.com/badges/active_voice.png'),
    ('POTHOLE_HUNTER', 'Pothole Hunter', 'Reported 5 road hazards in the Pothole category.', 'https://example.com/badges/pothole_hunter.png'),
    ('HIGH_IMPACT_REPORT', 'High Impact Report', 'One of your reports achieved community validation with 10 upvotes.', 'https://example.com/badges/high_impact.png'),
    ('COMMUNITY_GUARDIAN', 'Community Guardian', 'Granted 50 upvotes to back fellow citizens reports.', 'https://example.com/badges/community_guardian.png');

-- DANE Urban Coverage Cities (51 Municipalities)
INSERT INTO public.coverage_city (name, department, center_latitude, center_longitude, is_capital) VALUES
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
    ('Sogamoso', 'Boyacá', 5.71450000, -72.93390000, FALSE);

-- =============================================================================
-- 4. AUTOMATIC AUTH SYNCHRONIZATION TRIGGER (Supabase auth.users -> user_profile)
-- =============================================================================

CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS trigger AS $$
BEGIN
  INSERT INTO public.user_profile (
    id_user,
    id_rank,
    full_name,
    email,
    auth_provider,
    reference_city,
    last_city,
    experience_points,
    is_active
  )
  VALUES (
    new.id,
    1,
    COALESCE(
      new.raw_user_meta_data->>'full_name',
      new.raw_user_meta_data->>'nombre_completo',
      'Citizen VIGÍA'
    ),
    COALESCE(new.email, ''),
    'LOCAL',
    COALESCE(
      new.raw_user_meta_data->>'city_name',
      new.raw_user_meta_data->>'ciudad_nombre',
      'Cali'
    ),
    COALESCE(
      new.raw_user_meta_data->>'city_name',
      new.raw_user_meta_data->>'ciudad_nombre',
      'Cali'
    ),
    0,
    TRUE
  );
  RETURN new;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Recreate trigger on auth.users
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;
CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- =============================================================================
-- 5. ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

ALTER TABLE public.civic_rank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coverage_city ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.civic_badge ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.road_incident ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_photo ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_comment ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_upvote ENABLE ROW LEVEL SECURITY;

-- Read policies for public catalogs (accessible by anonymous and authenticated users)
CREATE POLICY "Public read access on civic_rank"
  ON public.civic_rank FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Public read access on coverage_city"
  ON public.coverage_city FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Public read access on incident_category"
  ON public.incident_category FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Public read access on civic_badge"
  ON public.civic_badge FOR SELECT TO authenticated, anon USING (true);

-- User Profile policies
CREATE POLICY "Public read access on user_profile"
  ON public.user_profile FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Users can update own profile"
  ON public.user_profile FOR UPDATE TO authenticated USING (auth.uid() = id_user);

-- Road Incidents policies
CREATE POLICY "Public read access on road_incident"
  ON public.road_incident FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Authenticated users can create road_incident"
  ON public.road_incident FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_reporter_user);

-- Incident Photos policies
CREATE POLICY "Public read access on incident_photo"
  ON public.incident_photo FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Authenticated users can insert incident_photo"
  ON public.incident_photo FOR INSERT TO authenticated WITH CHECK (true);

-- Comments policies
CREATE POLICY "Public read access on incident_comment"
  ON public.incident_comment FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Authenticated users can create comments"
  ON public.incident_comment FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

-- Upvotes policies
CREATE POLICY "Public read access on incident_upvote"
  ON public.incident_upvote FOR SELECT TO authenticated, anon USING (true);

CREATE POLICY "Authenticated users can upvote"
  ON public.incident_upvote FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

CREATE POLICY "Authenticated users can remove upvote"
  ON public.incident_upvote FOR DELETE TO authenticated USING (auth.uid() = id_user);
