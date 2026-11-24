-- =============================================================================
-- Migration: 006_report_edit_window_and_publish_xp.sql
-- Description: Server-side rules for editing and deleting a report (HU-18,
--              RN-03) and for the XP of publishing (RN-08):
--              * the author may edit or delete the report only during the first
--                30 minutes AND while it has fewer than 5 endorsements; after
--                that it is frozen, and the server says so;
--              * a signed-in citizen cannot change the tracking code, the
--                creation date, the status or the resolution of a report;
--              * the +100 XP for publishing is paid by a trigger (the app used to
--                write it) and deleting the report takes the 100 XP back;
--              * a citizen can no longer write their own experience points or
--                rank (the "Users can update own profile" policy allowed it);
--              * photos: only the author, only inside the window, at most 3;
--              * DELETE policy on road_incident and ownership policies on
--                incident_photo (it accepted any insert before).
-- Requires: migration 004 (add_xp and the rank sync trigger).
-- Idempotent: safe to run more than once.
-- Run in the Supabase SQL Editor, then run
-- `data model/tests/006_report_edit_window_smoke_test.sql` to check it.
--
-- "Direct" means the citizen's own request (pg_trigger_depth() = 1). Changes a
-- trigger makes by itself (status and validation date of migration 004, the
-- cascade of a deleted report) run deeper and are never blocked here, and
-- neither is the SQL Editor (no signed-in user).
-- =============================================================================

-- 1. Is the report still inside its edit window (RN-03)?
CREATE OR REPLACE FUNCTION public.is_incident_editable(p_incident UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1
      FROM road_incident i
     WHERE i.id_incident = p_incident
       AND now() - i.created_at <= interval '30 minutes'
       AND (SELECT count(*) FROM incident_upvote u WHERE u.id_incident = i.id_incident) < 5
  );
$$;

REVOKE ALL ON FUNCTION public.is_incident_editable(UUID) FROM PUBLIC, anon, authenticated;

-- 2. Before a report is edited or deleted by its author (RN-03)
CREATE OR REPLACE FUNCTION public.guard_incident_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    IF OLD.id_reporter_user <> auth.uid() THEN
      RAISE EXCEPTION 'Solo quien publicó el reporte puede modificarlo.';
    END IF;

    IF NOT public.is_incident_editable(OLD.id_incident) THEN
      RAISE EXCEPTION 'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.';
    END IF;

    IF TG_OP = 'UPDATE' THEN
      IF NEW.id_incident IS DISTINCT FROM OLD.id_incident
         OR NEW.tracking_code IS DISTINCT FROM OLD.tracking_code
         OR NEW.id_reporter_user IS DISTINCT FROM OLD.id_reporter_user
         OR NEW.created_at IS DISTINCT FROM OLD.created_at
         OR NEW.current_status IS DISTINCT FROM OLD.current_status
         OR NEW.validated_at IS DISTINCT FROM OLD.validated_at
         OR NEW.resolved_at IS DISTINCT FROM OLD.resolved_at
         OR NEW.id_resolver_user IS DISTINCT FROM OLD.id_resolver_user THEN
        RAISE EXCEPTION 'Ese dato del reporte no se puede cambiar.';
      END IF;
      NEW.updated_at := now();
    END IF;
  END IF;

  IF TG_OP = 'DELETE' THEN
    RETURN OLD;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_road_incident_change_guard ON public.road_incident;
CREATE TRIGGER trg_road_incident_change_guard
  BEFORE UPDATE OR DELETE ON public.road_incident
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_change();

-- 3. +100 XP when a report is published and -100 XP when it is deleted (RN-08).
--    The XP of endorsements and comments already given stays, as in 004 and 005.
CREATE OR REPLACE FUNCTION public.on_incident_published()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM add_xp(NEW.id_reporter_user, 100);
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_road_incident_published ON public.road_incident;
CREATE TRIGGER trg_road_incident_published
  AFTER INSERT ON public.road_incident
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_published();

CREATE OR REPLACE FUNCTION public.on_incident_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  PERFORM add_xp(OLD.id_reporter_user, -100);
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_road_incident_deleted ON public.road_incident;
CREATE TRIGGER trg_road_incident_deleted
  AFTER DELETE ON public.road_incident
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_deleted();

-- 4. Before a photo of a report changes: inside the window, and at most 3 (RN-02)
CREATE OR REPLACE FUNCTION public.guard_incident_photo_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident UUID := CASE WHEN TG_OP = 'DELETE' THEN OLD.id_incident ELSE NEW.id_incident END;
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
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

DROP TRIGGER IF EXISTS trg_incident_photo_change_guard ON public.incident_photo;
CREATE TRIGGER trg_incident_photo_change_guard
  BEFORE INSERT OR UPDATE OR DELETE ON public.incident_photo
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_photo_change();

-- 5. Experience points and rank belong to the server (RN-08, RN-09). A citizen
--    cannot start with points nor change them by hand; the triggers that call
--    add_xp run deeper and are not affected.
CREATE OR REPLACE FUNCTION public.guard_user_profile_progress()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    IF TG_OP = 'INSERT' THEN
      IF NEW.experience_points <> 0 THEN
        RAISE EXCEPTION 'Los puntos de reputación los calcula VIGÍA; una cuenta nueva empieza en 0.';
      END IF;
    ELSIF NEW.experience_points IS DISTINCT FROM OLD.experience_points
          OR NEW.id_rank IS DISTINCT FROM OLD.id_rank THEN
      RAISE EXCEPTION 'Los puntos y el nivel los calcula VIGÍA; no se pueden cambiar a mano.';
    END IF;
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_user_profile_guard_progress ON public.user_profile;
CREATE TRIGGER trg_user_profile_guard_progress
  BEFORE INSERT OR UPDATE OF experience_points, id_rank ON public.user_profile
  FOR EACH ROW EXECUTE FUNCTION public.guard_user_profile_progress();

REVOKE ALL ON FUNCTION public.guard_incident_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_published() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_deleted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_incident_photo_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_user_profile_progress() FROM PUBLIC, anon, authenticated;

-- 6. Policies. The window is the triggers' job; the policies say whose rows.
DROP POLICY IF EXISTS "Reporters can delete own road_incident" ON public.road_incident;
CREATE POLICY "Reporters can delete own road_incident"
  ON public.road_incident FOR DELETE TO authenticated USING (auth.uid() = id_reporter_user);

DROP POLICY IF EXISTS "Authenticated users can insert incident_photo" ON public.incident_photo;
DROP POLICY IF EXISTS "Reporters can insert photo of own incident" ON public.incident_photo;
CREATE POLICY "Reporters can insert photo of own incident"
  ON public.incident_photo FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.road_incident i
     WHERE i.id_incident = incident_photo.id_incident AND i.id_reporter_user = auth.uid()
  ));

DROP POLICY IF EXISTS "Reporters can update photo of own incident" ON public.incident_photo;
CREATE POLICY "Reporters can update photo of own incident"
  ON public.incident_photo FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.road_incident i
     WHERE i.id_incident = incident_photo.id_incident AND i.id_reporter_user = auth.uid()
  ));

DROP POLICY IF EXISTS "Reporters can delete photo of own incident" ON public.incident_photo;
CREATE POLICY "Reporters can delete photo of own incident"
  ON public.incident_photo FOR DELETE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.road_incident i
     WHERE i.id_incident = incident_photo.id_incident AND i.id_reporter_user = auth.uid()
  ));
