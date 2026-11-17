-- =============================================================================
-- Migration: 003_spanish_categories_and_storage_bucket.sql
-- Description: Standardize road incident categories to official Colombian Spanish
--              and create the public storage bucket for photographic evidence.
-- =============================================================================

-- 1. Standardize incident_category records
DELETE FROM incident_category;

INSERT INTO incident_category (id_category, name, icon, description) VALUES
    (1, 'Hueco o bache en calzada', 'warning', 'Huecos, grietas, cráteres o hundimientos en el pavimento.'),
    (2, 'Semáforo dañado o apagado', 'traffic', 'Semáforos apagados, intermitentes o dañados.'),
    (3, 'Obra pública abandonada', 'construction', 'Obras viales paralizadas, sin señalización o abandonadas.'),
    (4, 'Andén o paso peatonal roto', 'directions_walk', 'Andenes destruidos, baldosas sueltas o pasos peatonales bloqueados.'),
    (5, 'Fuga de agua o alcantarillado', 'water_drop', 'Fugas de acueducto, tapas de alcantarilla rotas o desbordamientos.'),
    (6, 'Señalización vial dañada', 'signpost', 'Señales de tránsito caídas, grafiteadas, invisibles o ausentes.'),
    (7, 'Otro daño vial', 'more_horiz', 'Otros peligros o deterioros de la infraestructura vial urbana.')
ON CONFLICT (id_category) DO UPDATE 
SET name = EXCLUDED.name, icon = EXCLUDED.icon, description = EXCLUDED.description;

-- 2. Create public storage bucket for photographic evidence
INSERT INTO storage.buckets (id, name, public) 
VALUES ('incident-evidence', 'incident-evidence', true)
ON CONFLICT (id) DO UPDATE SET public = true;

-- 3. Storage RLS policies
DROP POLICY IF EXISTS "Authenticated users can upload incident evidence" ON storage.objects;
CREATE POLICY "Authenticated users can upload incident evidence"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (bucket_id = 'incident-evidence');

DROP POLICY IF EXISTS "Public can view incident evidence" ON storage.objects;
CREATE POLICY "Public can view incident evidence"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'incident-evidence');
