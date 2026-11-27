-- =============================================================================
-- Migration 009: Civic privacy setting (HU-01)
-- Adds `show_real_name` to `user_profile` so citizens can hide their real name
-- across reports and comments while keeping their civic rank visible.
-- =============================================================================

ALTER TABLE public.user_profile
  ADD COLUMN IF NOT EXISTS show_real_name BOOLEAN NOT NULL DEFAULT TRUE;
