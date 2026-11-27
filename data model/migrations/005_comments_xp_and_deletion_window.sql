-- =============================================================================
-- Migration: 005_comments_xp_and_deletion_window.sql
-- Description: Server-side rules for comments (HU-17): +15 XP per comment
--              (RN-08), immutable comments (RN-06: no UPDATE policy exists),
--              deletion only within 5 minutes of publishing with -15 XP, a text
--              length limit, notification rows for the report author and the
--              citizens who follow it (HU-24), and RLS on comment_photo.
-- Requires: migration 004 (add_xp, RLS on notification and incident_follow).
-- Idempotent: safe to run more than once.
-- Run in the Supabase SQL Editor, then run
-- `data model/tests/005_comments_smoke_test.sql` to check it.
-- =============================================================================

-- 1. Before a comment is published: the text has a limit (the app allows 500)
CREATE OR REPLACE FUNCTION public.guard_incident_comment()
RETURNS trigger
LANGUAGE plpgsql
SET search_path = public
AS $$
BEGIN
  IF char_length(NEW.content) > 500 THEN
    RAISE EXCEPTION 'El comentario no puede superar los 500 caracteres.';
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_comment_guard ON public.incident_comment;
CREATE TRIGGER trg_incident_comment_guard
  BEFORE INSERT ON public.incident_comment
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_comment();

-- 2. After a comment is published: +15 XP to the commenter and a NEW_COMMENT
--    notification for the report author and the followers, never for the
--    commenter themselves.
CREATE OR REPLACE FUNCTION public.on_incident_comment_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident road_incident%ROWTYPE;
  v_name TEXT;
BEGIN
  SELECT * INTO v_incident FROM road_incident WHERE id_incident = NEW.id_incident;
  SELECT full_name INTO v_name FROM user_profile WHERE id_user = NEW.id_user;

  PERFORM add_xp(NEW.id_user, 15);

  INSERT INTO notification (id_user, id_incident, type, title, message)
  SELECT recipient.id_user, NEW.id_incident, 'NEW_COMMENT',
         'Nuevo comentario',
         'Nuevo comentario en el reporte ' || v_incident.tracking_code || ': '
           || COALESCE(v_name, 'Un ciudadano') || ' aportó a la discusión.'
    FROM (
      SELECT v_incident.id_reporter_user AS id_user
      UNION
      SELECT id_user FROM incident_follow WHERE id_incident = NEW.id_incident
    ) AS recipient
   WHERE recipient.id_user <> NEW.id_user;

  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_comment_inserted ON public.incident_comment;
CREATE TRIGGER trg_incident_comment_inserted
  AFTER INSERT ON public.incident_comment
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_comment_inserted();

-- 3. Before a comment is deleted: only within 5 minutes (RN-06). It does not
--    apply when there is no signed-in user (SQL Editor, moderation) nor when
--    the whole report or the account is being deleted (the cascade).
CREATE OR REPLACE FUNCTION public.guard_incident_comment_delete()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF auth.uid() IS NOT NULL
     AND now() - OLD.created_at > interval '5 minutes'
     AND EXISTS (SELECT 1 FROM road_incident WHERE id_incident = OLD.id_incident)
     AND EXISTS (SELECT 1 FROM user_profile WHERE id_user = OLD.id_user) THEN
    RAISE EXCEPTION 'Solo puedes eliminar tu comentario durante los primeros 5 minutos.';
  END IF;
  RETURN OLD;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_comment_delete_guard ON public.incident_comment;
CREATE TRIGGER trg_incident_comment_delete_guard
  BEFORE DELETE ON public.incident_comment
  FOR EACH ROW EXECUTE FUNCTION public.guard_incident_comment_delete();

-- 4. After a comment is deleted: -15 XP (never below 0). When the whole report
--    is deleted nothing is deducted, like the endorsements of migration 004.
CREATE OR REPLACE FUNCTION public.on_incident_comment_deleted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
  IF EXISTS (SELECT 1 FROM road_incident WHERE id_incident = OLD.id_incident) THEN
    PERFORM add_xp(OLD.id_user, -15);
  END IF;
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_comment_deleted ON public.incident_comment;
CREATE TRIGGER trg_incident_comment_deleted
  AFTER DELETE ON public.incident_comment
  FOR EACH ROW EXECUTE FUNCTION public.on_incident_comment_deleted();

REVOKE ALL ON FUNCTION public.guard_incident_comment() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_comment_inserted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_incident_comment_delete() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_comment_deleted() FROM PUBLIC, anon, authenticated;

-- 5. Policies. A comment has no UPDATE policy on purpose: it is immutable (RN-06).
DROP POLICY IF EXISTS "Authors can delete own comments" ON public.incident_comment;
CREATE POLICY "Authors can delete own comments"
  ON public.incident_comment FOR DELETE TO authenticated USING (auth.uid() = id_user);

ALTER TABLE public.comment_photo ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on comment_photo" ON public.comment_photo;
CREATE POLICY "Public read access on comment_photo"
  ON public.comment_photo FOR SELECT TO authenticated, anon USING (true);

DROP POLICY IF EXISTS "Authors can attach a photo to own comment" ON public.comment_photo;
CREATE POLICY "Authors can attach a photo to own comment"
  ON public.comment_photo FOR INSERT TO authenticated
  WITH CHECK (EXISTS (
    SELECT 1 FROM public.incident_comment c
     WHERE c.id_comment = comment_photo.id_comment AND c.id_user = auth.uid()
  ));
