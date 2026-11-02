-- =============================================================================
-- VIGÍA - CIVIC ROAD AUDITING & CITIZEN OVERSIGHT PLATFORM
-- RELATIONAL SCHEMA (DDL) - THIRD NORMAL FORM (3NF)
-- ENGINE: PostgreSQL 14+
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- 1. TABLE: civic_rank (Master Catalog of Civic Progression Ranks)
CREATE TABLE civic_rank (
    id_rank SERIAL PRIMARY KEY,
    name VARCHAR(50) NOT NULL UNIQUE,
    min_xp INT NOT NULL CHECK (min_xp >= 0),
    icon_url VARCHAR(500) NULL
);

-- 2. TABLE: coverage_city (Official DANE Urban Municipalities Coverage Catalog)
CREATE TABLE coverage_city (
    id_city SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL,
    department VARCHAR(80) NOT NULL,
    center_latitude DECIMAL(10, 8) NOT NULL,
    center_longitude DECIMAL(11, 8) NOT NULL,
    is_capital BOOLEAN NOT NULL DEFAULT FALSE,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT uq_city_department UNIQUE (name, department)
);

-- 3. TABLE: user_profile (Registered Citizen Profiles)
CREATE TABLE user_profile (
    id_user UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_rank INT NOT NULL,
    full_name VARCHAR(120) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NULL,
    auth_provider VARCHAR(30) NOT NULL DEFAULT 'LOCAL'
        CHECK (auth_provider IN ('LOCAL', 'GOOGLE', 'APPLE')),
    reference_city VARCHAR(80) NOT NULL,
    last_city VARCHAR(80) NOT NULL,
    profile_picture_url VARCHAR(500) NULL,
    experience_points INT NOT NULL DEFAULT 0 CHECK (experience_points >= 0),
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    
    CONSTRAINT fk_user_rank 
        FOREIGN KEY (id_rank) 
        REFERENCES civic_rank (id_rank) 
        ON DELETE RESTRICT
);

-- 4. TABLE: civic_badge (Master Catalog of Civic Badges & Medals)
CREATE TABLE civic_badge (
    id_badge SERIAL PRIMARY KEY,
    key_code VARCHAR(50) NOT NULL UNIQUE,
    name VARCHAR(80) NOT NULL,
    description VARCHAR(255) NOT NULL,
    icon_url VARCHAR(500) NOT NULL
);

-- 5. TABLE: user_badge (Many-to-Many Relationship: User - Badge)
CREATE TABLE user_badge (
    id_user UUID NOT NULL,
    id_badge INT NOT NULL,
    earned_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_badge),
    
    CONSTRAINT fk_user_badge_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_user_badge_badge 
        FOREIGN KEY (id_badge) 
        REFERENCES civic_badge (id_badge) 
        ON DELETE CASCADE
);

-- 6. TABLE: incident_category (Taxonomy of Road Hazards and Infrastructure Damages)
CREATE TABLE incident_category (
    id_category SERIAL PRIMARY KEY,
    name VARCHAR(80) NOT NULL UNIQUE,
    icon VARCHAR(50) NOT NULL,
    description VARCHAR(255) NULL
);

-- 7. TABLE: road_incident (Public Road Infrastructure Hazard Report)
CREATE TABLE road_incident (
    id_incident UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
        REFERENCES user_profile (id_user)
        ON DELETE RESTRICT,

    CONSTRAINT fk_incident_resolver_user
        FOREIGN KEY (id_resolver_user) 
        REFERENCES user_profile (id_user)
        ON DELETE SET NULL,

    CONSTRAINT fk_incident_category 
        FOREIGN KEY (id_category) 
        REFERENCES incident_category (id_category) 
        ON DELETE RESTRICT
);

-- 8. TABLE: incident_photo (Road Damage Photographic Evidence - 1:N)
CREATE TABLE incident_photo (
    id_photo UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_incident UUID NOT NULL,
    file_url VARCHAR(500) NOT NULL,
    is_primary BOOLEAN NOT NULL DEFAULT FALSE,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_incident_photo_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 9. TABLE: incident_comment (Citizen Discussion Thread on Report)
CREATE TABLE incident_comment (
    id_comment UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    id_incident UUID NOT NULL,
    id_user UUID NOT NULL,
    content TEXT NOT NULL,
    created_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_comment_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_comment_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE
);

-- 10. TABLE: comment_photo (Optional Single Photo Attachment in Comments - 0..1:1)
CREATE TABLE comment_photo (
    id_comment UUID PRIMARY KEY,
    file_url VARCHAR(500) NOT NULL,
    uploaded_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_comment_photo_comment 
        FOREIGN KEY (id_comment) 
        REFERENCES incident_comment (id_comment) 
        ON DELETE CASCADE
);

-- 11. TABLE: incident_resolution (Formal Repair Proposal & Community Verification)
CREATE TABLE incident_resolution (
    id_resolution UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_resolution_proponent_user 
        FOREIGN KEY (id_proponent_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE RESTRICT,
        
    CONSTRAINT fk_resolution_approver_user 
        FOREIGN KEY (id_approver_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE SET NULL
);

-- 12. TABLE: resolution_confirmation (Citizen Verification Votes - N:M)
CREATE TABLE resolution_confirmation (
    id_user UUID NOT NULL,
    id_resolution UUID NOT NULL,
    confirmed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_resolution),
    
    CONSTRAINT fk_confirmation_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_confirmation_resolution 
        FOREIGN KEY (id_resolution) 
        REFERENCES incident_resolution (id_resolution) 
        ON DELETE CASCADE
);

-- 13. TABLE: resolution_objection (Citizen Objections for Invalid/Fraudulent Evidence - N:M)
CREATE TABLE resolution_objection (
    id_user UUID NOT NULL,
    id_resolution UUID NOT NULL,
    reason TEXT NULL,
    objected_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_resolution),
    
    CONSTRAINT fk_objection_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_objection_resolution 
        FOREIGN KEY (id_resolution) 
        REFERENCES incident_resolution (id_resolution) 
        ON DELETE CASCADE
);

-- 14. TABLE: incident_upvote (Community Backing Votes / Upvotes - N:M)
CREATE TABLE incident_upvote (
    id_user UUID NOT NULL,
    id_incident UUID NOT NULL,
    upvoted_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_incident),
    
    CONSTRAINT fk_upvote_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_upvote_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 15. TABLE: incident_follow (Followed Reports / Notifications Bell - N:M)
CREATE TABLE incident_follow (
    id_user UUID NOT NULL,
    id_incident UUID NOT NULL,
    followed_at TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    
    PRIMARY KEY (id_user, id_incident),
    
    CONSTRAINT fk_follow_user 
        FOREIGN KEY (id_user) 
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_follow_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE
);

-- 16. TABLE: notification (Citizen Alerts & System Notifications)
CREATE TABLE notification (
    id_notification UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
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
        REFERENCES user_profile (id_user) 
        ON DELETE CASCADE,
        
    CONSTRAINT fk_notification_incident 
        FOREIGN KEY (id_incident) 
        REFERENCES road_incident (id_incident) 
        ON DELETE CASCADE
);

-- =============================================================================
-- PERFORMANCE & INTEGRITY INDEXES
-- =============================================================================

CREATE INDEX idx_incident_coordinates ON road_incident (latitude, longitude);
CREATE INDEX idx_incident_neighborhood ON road_incident (neighborhood);
CREATE INDEX idx_incident_category ON road_incident (id_category);
CREATE INDEX idx_incident_created_at ON road_incident (created_at DESC);
CREATE INDEX idx_incident_reporter ON road_incident (id_reporter_user);
CREATE INDEX idx_comment_incident ON incident_comment (id_incident, created_at ASC);
CREATE INDEX idx_upvote_incident_id ON incident_upvote (id_incident);
CREATE INDEX idx_notification_user ON notification (id_user, is_read, created_at DESC);
CREATE INDEX idx_resolution_incident ON incident_resolution (id_incident, status);

-- Partial Unique Index: ensures at most 1 primary photo per incident report
CREATE UNIQUE INDEX idx_single_primary_photo ON incident_photo (id_incident) WHERE is_primary = TRUE;

-- Partial Unique Index: ensures at most 1 active pending resolution proposal per incident report (No-Bifurcation Rule)
CREATE UNIQUE INDEX idx_single_active_resolution ON incident_resolution (id_incident) WHERE status = 'PENDING';

-- =============================================================================
-- SUPABASE POSTGREST ROLE PERMISSIONS (GRANT)
-- =============================================================================

GRANT USAGE ON SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO postgres, anon, authenticated, service_role;
GRANT ALL ON ALL ROUTINES IN SCHEMA public TO postgres, anon, authenticated, service_role;

ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO postgres, anon, authenticated, service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON ROUTINES TO postgres, anon, authenticated, service_role;

-- =============================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =============================================================================

-- Master Catalogs (Read-only for public and authenticated citizens)
ALTER TABLE public.civic_rank ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.coverage_city ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.incident_category ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.civic_badge ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on civic_rank" ON public.civic_rank;
CREATE POLICY "Public read access on civic_rank"
  ON public.civic_rank FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Public read access on coverage_city" ON public.coverage_city;
CREATE POLICY "Public read access on coverage_city"
  ON public.coverage_city FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Public read access on incident_category" ON public.incident_category;
CREATE POLICY "Public read access on incident_category"
  ON public.incident_category FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Public read access on civic_badge" ON public.civic_badge;
CREATE POLICY "Public read access on civic_badge"
  ON public.civic_badge FOR SELECT TO authenticated, anon USING (true);

-- User Profile Policies
ALTER TABLE public.user_profile ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on user_profile" ON public.user_profile;
CREATE POLICY "Public read access on user_profile"
  ON public.user_profile FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Users can insert own profile" ON public.user_profile;
CREATE POLICY "Users can insert own profile"
  ON public.user_profile FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

DROP POLICY IF EXISTS "Users can update own profile" ON public.user_profile;
CREATE POLICY "Users can update own profile"
  ON public.user_profile FOR UPDATE TO authenticated USING (auth.uid() = id_user);

-- User Badges Policies
ALTER TABLE public.user_badge ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on user_badge" ON public.user_badge;
CREATE POLICY "Public read access on user_badge"
  ON public.user_badge FOR SELECT TO authenticated, anon USING (true);

-- Road Incidents Policies
ALTER TABLE public.road_incident ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on road_incident" ON public.road_incident;
CREATE POLICY "Public read access on road_incident"
  ON public.road_incident FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Authenticated users can create road_incident" ON public.road_incident;
CREATE POLICY "Authenticated users can create road_incident"
  ON public.road_incident FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_reporter_user);

DROP POLICY IF EXISTS "Reporters can update own road_incident" ON public.road_incident;
CREATE POLICY "Reporters can update own road_incident"
  ON public.road_incident FOR UPDATE TO authenticated USING (auth.uid() = id_reporter_user);

-- Incident Photos Policies
ALTER TABLE public.incident_photo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on incident_photo" ON public.incident_photo;
CREATE POLICY "Public read access on incident_photo"
  ON public.incident_photo FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Authenticated users can insert incident_photo" ON public.incident_photo;
CREATE POLICY "Authenticated users can insert incident_photo"
  ON public.incident_photo FOR INSERT TO authenticated WITH CHECK (true);

-- Comments Policies
ALTER TABLE public.incident_comment ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on incident_comment" ON public.incident_comment;
CREATE POLICY "Public read access on incident_comment"
  ON public.incident_comment FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Authenticated users can create comments" ON public.incident_comment;
CREATE POLICY "Authenticated users can create comments"
  ON public.incident_comment FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

-- Upvotes Policies
ALTER TABLE public.incident_upvote ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on incident_upvote" ON public.incident_upvote;
CREATE POLICY "Public read access on incident_upvote"
  ON public.incident_upvote FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Authenticated users can upvote" ON public.incident_upvote;
CREATE POLICY "Authenticated users can upvote"
  ON public.incident_upvote FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

DROP POLICY IF EXISTS "Authenticated users can remove upvote" ON public.incident_upvote;
CREATE POLICY "Authenticated users can remove upvote"
  ON public.incident_upvote FOR DELETE TO authenticated USING (auth.uid() = id_user);

-- Follows Policies
ALTER TABLE public.incident_follow ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own follows" ON public.incident_follow;
CREATE POLICY "Users can read own follows"
  ON public.incident_follow FOR SELECT TO authenticated USING (auth.uid() = id_user);

DROP POLICY IF EXISTS "Users can create follow" ON public.incident_follow;
CREATE POLICY "Users can create follow"
  ON public.incident_follow FOR INSERT TO authenticated WITH CHECK (auth.uid() = id_user);

DROP POLICY IF EXISTS "Users can remove follow" ON public.incident_follow;
CREATE POLICY "Users can remove follow"
  ON public.incident_follow FOR DELETE TO authenticated USING (auth.uid() = id_user);

-- Notifications Policies
ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notification;
CREATE POLICY "Users can read own notifications"
  ON public.notification FOR SELECT TO authenticated USING (auth.uid() = id_user);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notification;
CREATE POLICY "Users can update own notifications"
  ON public.notification FOR UPDATE TO authenticated USING (auth.uid() = id_user);