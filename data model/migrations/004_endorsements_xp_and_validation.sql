-- =============================================================================
-- Migration: 004_endorsements_xp_and_validation.sql
-- Description: Server-side rules for endorsements (HU-15) and community
--              validation (HU-16): self-vote ban (RN-05), +/-10 XP per vote
--              (RN-08), one-time +500 XP bonus at the 10th vote, automatic
--              rank (RN-09) and the notification rows that HU-24 will push.
--              Also enables RLS on `notification` and `incident_follow`,
--              which schema.sql already declares but the live project lacks.
-- Idempotent: safe to run more than once.
-- Run in the Supabase SQL Editor, then run
-- `data model/tests/004_endorsements_smoke_test.sql` to check it.
-- =============================================================================

-- 1. One-time validation marker (HU-16, criterion 5: the +500 XP is never paid twice)
ALTER TABLE public.road_incident ADD COLUMN IF NOT EXISTS validated_at TIMESTAMPTZ NULL;

-- 2. Rank from XP (RN-09): the highest civic_rank.min_xp not above the XP
CREATE OR REPLACE FUNCTION public.rank_for_xp(p_xp INT)
RETURNS INT
LANGUAGE sql STABLE
SET search_path = public
AS $$
  SELECT id_rank FROM civic_rank WHERE min_xp <= GREATEST(p_xp, 0) ORDER BY min_xp DESC LIMIT 1
$$;

CREATE OR REPLACE FUNCTION public.sync_user_rank()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  NEW.id_rank := COALESCE(rank_for_xp(NEW.experience_points), NEW.id_rank);
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_user_profile_sync_rank ON public.user_profile;
CREATE TRIGGER trg_user_profile_sync_rank
  BEFORE INSERT OR UPDATE OF experience_points ON public.user_profile
  FOR EACH ROW EXECUTE FUNCTION public.sync_user_rank();

-- 3. XP helper. Only the triggers below call it: clients can never reach it.
CREATE OR REPLACE FUNCTION public.add_xp(p_user UUID, p_delta INT)
RETURNS VOID
LANGUAGE sql
SECURITY DEFINER
SET search_path = public
AS $$
  UPDATE user_profile
     SET experience_points = GREATEST(0, experience_points + p_delta)
   WHERE id_user = p_user;
$$;

REVOKE ALL ON FUNCTION public.add_xp(UUID, INT) FROM PUBLIC, anon, authenticated;

-- 4. Before an endorsement: nobody endorses their own report (RN-05)
CREATE OR REPLACE FUNCTION public.guard_incident_upvote()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reporter UUID;
BEGIN
  SELECT id_reporter_user INTO v_reporter
    FROM road_incident WHERE id_incident = NEW.id_incident;

  IF v_reporter IS NULL THEN
    RAISE EXCEPTION 'El reporte no existe o fue retirado.';
  END IF;
  IF v_reporter = NEW.id_user THEN
    RAISE EXCEPTION 'No puedes apoyar tu propio reporte.';
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_upvote_guard ON public.incident_upvote;
CREATE TRIGGER trg_incident_upvote_guard
  BEFORE INSERT ON public.incident_upvote
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_upvote();

-- 5. After an endorsement: +10 XP to voter and author, notify the author and,
--    on the 10th vote for the first time, validate the report (+500 XP).
--    The row lock serializes concurrent votes so the bonus is paid only once.
CREATE OR REPLACE FUNCTION public.on_incident_upvote_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident road_incident%ROWTYPE;
  v_votes INT;
BEGIN
  SELECT * INTO v_incident FROM road_incident WHERE id_incident = NEW.id_incident FOR UPDATE;

  PERFORM add_xp(NEW.id_user, 10);
  PERFORM add_xp(v_incident.id_reporter_user, 10);

  INSERT INTO notification (id_user, id_incident, type, title, message)
  VALUES (v_incident.id_reporter_user, v_incident.id_incident, 'NEW_UPVOTE',
          'Nuevo apoyo',
          'Un ciudadano apoyó tu reporte ' || v_incident.tracking_code || '.');

  SELECT count(*) INTO v_votes FROM incident_upvote WHERE id_incident = NEW.id_incident;

  IF v_votes >= 10 AND v_incident.validated_at IS NULL THEN
    UPDATE road_incident
       SET validated_at = now(),
           updated_at = now(),
           current_status = CASE WHEN current_status IN ('REPORTED', 'UNDER_REVIEW')
                                 THEN 'COMMUNITY_VALIDATED' ELSE current_status END
     WHERE id_incident = v_incident.id_incident;

    PERFORM add_xp(v_incident.id_reporter_user, 500);

    INSERT INTO notification (id_user, id_incident, type, title, message)
    VALUES (v_incident.id_reporter_user, v_incident.id_incident, 'COMMUNITY_VALIDATION',
            '¡Reporte validado por la comunidad!',
            'Tu reporte ' || v_incident.tracking_code || ' alcanzó 10 apoyos (+500 XP).');
  END IF;

  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_upvote_inserted ON public.incident_upvote;
CREATE TRIGGER trg_incident_upvote_inserted
  AFTER INSERT ON public.incident_upvote
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_upvote_inserted();

-- 6. After a revoked endorsement: -10 XP to both (never below 0). The +500
--    bonus stays. When the whole report is deleted (cascade) nothing is
--    deducted here: HU-18 revokes only the publication XP.
CREATE OR REPLACE FUNCTION public.on_incident_upvote_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reporter UUID;
BEGIN
  SELECT id_reporter_user INTO v_reporter
    FROM road_incident WHERE id_incident = OLD.id_incident;

  IF v_reporter IS NOT NULL THEN
    PERFORM add_xp(OLD.id_user, -10);
    PERFORM add_xp(v_reporter, -10);
  END IF;
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_upvote_deleted ON public.incident_upvote;
CREATE TRIGGER trg_incident_upvote_deleted
  AFTER DELETE ON public.incident_upvote
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_upvote_deleted();

REVOKE ALL ON FUNCTION public.guard_incident_upvote() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_upvote_inserted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_upvote_deleted() FROM PUBLIC, anon, authenticated;

-- 7. Existing profiles: recompute their rank once (fires the trigger of step 2)
UPDATE public.user_profile SET experience_points = experience_points;

-- 8. RLS that schema.sql declares but the live project did not have.
--    Notifications are written only by the SECURITY DEFINER triggers above.
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

ALTER TABLE public.notification ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Users can read own notifications" ON public.notification;
CREATE POLICY "Users can read own notifications"
  ON public.notification FOR SELECT TO authenticated USING (auth.uid() = id_user);

DROP POLICY IF EXISTS "Users can update own notifications" ON public.notification;
CREATE POLICY "Users can update own notifications"
  ON public.notification FOR UPDATE TO authenticated USING (auth.uid() = id_user);
