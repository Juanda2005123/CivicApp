-- =============================================================================
-- Migration 012: Spanish names for the incident categories
-- Migration 003 meant to do this, but its first step (DELETE FROM
-- incident_category) cannot run once reports point at the categories, so the
-- live project still shows "Water Leak" and the rest in English. This only
-- updates the rows in place: ids, icons and the reports that use them stay.
-- Safe to run more than once.
-- =============================================================================

UPDATE public.incident_category AS c
SET name = v.name, description = v.description
FROM (VALUES
    ('warning',         'Hueco o bache en calzada',      'Huecos, grietas, cráteres o hundimientos en el pavimento.'),
    ('traffic',         'Semáforo dañado o apagado',     'Semáforos apagados, intermitentes o dañados.'),
    ('construction',    'Obra pública abandonada',       'Obras viales paralizadas, sin señalización o abandonadas.'),
    ('directions_walk', 'Andén o paso peatonal roto',    'Andenes destruidos, baldosas sueltas o pasos peatonales bloqueados.'),
    ('water_drop',      'Fuga de agua o alcantarillado', 'Fugas de acueducto, tapas de alcantarilla rotas o desbordamientos.'),
    ('signpost',        'Señalización vial dañada',      'Señales de tránsito caídas, grafiteadas, invisibles o ausentes.'),
    ('more_horiz',      'Otro daño vial',                'Otros peligros o deterioros de la infraestructura vial urbana.')
) AS v(icon, name, description)
WHERE c.icon = v.icon;

-- Check: the seven categories, in Spanish.
SELECT id_category, name, icon FROM public.incident_category ORDER BY id_category;
