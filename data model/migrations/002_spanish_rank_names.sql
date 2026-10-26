-- =============================================================================
-- Migration 002: civic rank names in Spanish
-- =============================================================================
-- The interface is now fully in Spanish (docs/design/03-design-system.md, 8),
-- and the rank name shown in the profile comes from civic_rank.name.
--
-- HOW TO APPLY (once per Supabase project):
--   Supabase dashboard > SQL Editor > New query > paste this file > Run.
--
-- Safe to repeat: it only renames the four ranks by their min_xp (RN-09).
-- Profiles keep pointing to the same rank (id_rank does not change).
-- =============================================================================

UPDATE civic_rank SET name = 'Observador Urbano' WHERE min_xp = 0;
UPDATE civic_rank SET name = 'Vecino Activo'     WHERE min_xp = 1000;
UPDATE civic_rank SET name = 'Guardián Vial'     WHERE min_xp = 2500;
UPDATE civic_rank SET name = 'Veedor Mayor'      WHERE min_xp = 4000;
