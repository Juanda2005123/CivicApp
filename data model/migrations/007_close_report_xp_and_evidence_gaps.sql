-- =============================================================================
-- Migration: 007_close_report_xp_and_evidence_gaps.sql
-- Description: Three gaps found reviewing migration 006 (HU-18):
--              1. XP farming through delete. Deleting a report took back only the
--                 100 XP of publishing, while the XP of its comments (+15 each)
--                 and of its endorsements (+10 to the voter and +10 to the
--                 author) stayed. Now deleting a report takes back all the XP it
--                 produced, before its comments and endorsements are cascaded.
--              2. Evidence escaping a frozen report. The photo guard looked at
--                 the report a photo was moving TO, so an author could move a
--                 photo out of a frozen report into a fresh one. Now the report a
--                 photo belongs to is checked and a photo can never change report.
--              3. Born-frozen or born-validated reports. A signed-in citizen could
--                 publish with a past created_at or a COMMUNITY_VALIDATED status.
--                 Now a direct publish always starts as REPORTED, created now,
--                 with no validation or resolution.
-- Requires: migrations 004, 005 and 006.
-- Idempotent: safe to run more than once.
-- Run in the Supabase SQL Editor, then run
-- `data model/tests/007_close_report_xp_and_evidence_gaps_smoke_test.sql`.
--
-- "Direct" means the citizen's own request (pg_trigger_depth() = 1); the SQL
-- Editor (no signed-in user) keeps its freedom for seeds and moderation.
-- =============================================================================

-- 1. Before a report is deleted, take back the XP its comments and endorsements
--    produced. It runs while they still exist: the cascade that follows does not
--    deduct again (migrations 004 and 005 skip it when the report is gone).
CREATE OR REPLACE FUNCTION public.take_back_incident_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r RECORD;
  v_votes INT;
BEGIN
  FOR r IN
    SELECT id_user, count(*)::int AS n FROM incident_comment
     WHERE id_incident = OLD.id_incident GROUP BY id_user
  LOOP
    PERFORM add_xp(r.id_user, -15 * r.n);
  END LOOP;

  FOR r IN
    SELECT id_user FROM incident_upvote WHERE id_incident = OLD.id_incident
  LOOP
    PERFORM add_xp(r.id_user, -10);
  END LOOP;

  SELECT count(*)::int INTO v_votes FROM incident_upvote WHERE id_incident = OLD.id_incident;
  IF v_votes > 0 THEN
    PERFORM add_xp(OLD.id_reporter_user, -10 * v_votes);
  END IF;

  -- Only moderation can delete a validated report; the 500 XP goes back too.
  IF OLD.validated_at IS NOT NULL THEN
    PERFORM add_xp(OLD.id_reporter_user, -500);
  END IF;

  RETURN OLD;
END
$$;

DROP TRIGGER IF EXISTS trg_road_incident_take_back_xp ON public.road_incident;
CREATE TRIGGER trg_road_incident_take_back_xp
  BEFORE DELETE ON public.road_incident
  FOR EACH ROW EXECUTE FUNCTION public.take_back_incident_xp();

-- 2. A photo belongs to one report for good, and that report decides the window.
CREATE OR REPLACE FUNCTION public.guard_incident_photo_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident UUID := CASE WHEN TG_OP = 'INSERT' THEN NEW.id_incident ELSE OLD.id_incident END;
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    IF TG_OP = 'UPDATE' AND NEW.id_incident IS DISTINCT FROM OLD.id_incident THEN
      RAISE EXCEPTION 'Una foto no puede pasar de un reporte a otro.';
    END IF;

    IF NOT public.is_incident_editable(v_incident) THEN
      RAISE EXCEPTION 'Este reporte ya no se puede modificar: pasaron más de 30 minutos o tiene 5 apoyos o más.';
    END IF;

    IF TG_OP = 'INSERT'
       AND (SELECT count(*) FROM incident_photo WHERE id_incident = v_incident) >= 3 THEN
      RAISE EXCEPTION 'Un reporte admite hasta 3 fotos.';
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END
$$;

-- 3. A report published by a citizen starts clean.
CREATE OR REPLACE FUNCTION public.guard_incident_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    NEW.created_at := now();
    NEW.updated_at := now();
    NEW.current_status := 'REPORTED';
    NEW.validated_at := NULL;
    NEW.resolved_at := NULL;
    NEW.id_resolver_user := NULL;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_road_incident_insert_guard ON public.road_incident;
CREATE TRIGGER trg_road_incident_insert_guard
  BEFORE INSERT ON public.road_incident
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_insert();

REVOKE ALL ON FUNCTION public.take_back_incident_xp() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_incident_photo_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_incident_insert() FROM PUBLIC, anon, authenticated;
