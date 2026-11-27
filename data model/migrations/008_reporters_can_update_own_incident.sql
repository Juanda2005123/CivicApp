-- =============================================================================
-- Migration: 008_reporters_can_update_own_incident.sql
-- Description: The author could not save an edited report (HU-18). The policy
--              "Reporters can update own road_incident" is declared in
--              schema.sql but the live project never had it, so with RLS on,
--              every UPDATE by a citizen matched no row and the app answered
--              "el reporte ya no es tuyo o fue retirado". Found on 2026-11-24
--              testing develop with a signed-in session.
--              The policy says whose rows; the 30 minute window, the 5
--              endorsements and the immutable columns are the triggers of
--              migration 006.
-- Requires: migration 006.
-- Idempotent: safe to run more than once.
-- Run in the Supabase SQL Editor, then run
-- `data model/tests/008_reporters_can_update_own_incident_smoke_test.sql`.
-- =============================================================================

DROP POLICY IF EXISTS "Reporters can update own road_incident" ON public.road_incident;
CREATE POLICY "Reporters can update own road_incident"
  ON public.road_incident FOR UPDATE TO authenticated
  USING (auth.uid() = id_reporter_user)
  WITH CHECK (auth.uid() = id_reporter_user);
