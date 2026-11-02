-- =============================================================================
-- VIGÍA - CIVIC ROAD AUDITING & CITIZEN OVERSIGHT PLATFORM
-- INITIAL SEED DATA (DML) - MASTER CATALOGS & OFFICIAL DANE URBAN COVERAGE
-- ENGINE: PostgreSQL 14+
-- =============================================================================

-- 1. CIVIC PROGRESSION RANKS (RN-09)
INSERT INTO civic_rank (name, min_xp, icon_url) VALUES
    ('Observador Urbano', 0, NULL),
    ('Vecino Activo', 1000, NULL),
    ('Guardián Vial', 2500, NULL),
    ('Veedor Mayor', 4000, NULL)
ON CONFLICT (name) DO NOTHING;

-- 2. ROAD INCIDENT CATEGORIES (Urban Infrastructure Taxonomy)
INSERT INTO incident_category (name, icon, description) VALUES
    ('Pothole or Road Hazard', 'warning', 'Potholes, cracks, craters, or pavement depressions.'),
    ('Traffic Light', 'traffic', 'Damaged, unlit, or desynchronized traffic signals.'),
    ('Abandoned Public Work', 'construction', 'Halted, abandoned, or delayed public road construction.'),
    ('Damaged Sidewalk', 'directions_walk', 'Deteriorated, broken, or obstructed pedestrian walkways.'),
    ('Water Leak', 'water_drop', 'Potable water main breaks or wastewater leaks on the road.'),
    ('Road Signage', 'signpost', 'Missing, damaged, obstructed, or illegible traffic signs.'),
    ('Other', 'more_horiz', 'Other unclassified public infrastructure hazards.')
ON CONFLICT (name) DO NOTHING;

-- 3. CIVIC BADGES (RN-10)
INSERT INTO civic_badge (key_code, name, description, icon_url) VALUES
    ('FIRST_CIVIC_STEP', 'First Civic Step', 'Published your first road incident report.', 'https://example.com/badges/first_step.png'),
    ('ACTIVE_VOICE', 'Active Voice', 'Posted 10 constructive comments in community discussions.', 'https://example.com/badges/active_voice.png'),
    ('POTHOLE_HUNTER', 'Pothole Hunter', 'Reported 5 road hazards in the Pothole category.', 'https://example.com/badges/pothole_hunter.png'),
    ('HIGH_IMPACT_REPORT', 'High Impact Report', 'One of your reports achieved community validation with 10 upvotes.', 'https://example.com/badges/high_impact.png'),
    ('COMMUNITY_GUARDIAN', 'Community Guardian', 'Granted 50 upvotes to back fellow citizens reports.', 'https://example.com/badges/community_guardian.png')
ON CONFLICT (key_code) DO NOTHING;

-- 4. OFFICIAL DANE URBAN COVERAGE CITIES (32 Capitals + Municipalities > 100k Inhabitants)
INSERT INTO coverage_city (name, department, center_latitude, center_longitude, is_capital) VALUES
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
    -- Non-capital metropolitan municipalities & cities > 100k hab
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
ON CONFLICT (name, department) DO NOTHING;
