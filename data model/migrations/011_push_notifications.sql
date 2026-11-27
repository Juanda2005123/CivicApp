-- =============================================================================
-- Migration: 011_push_notifications.sql
-- Description: Push notifications (HU-24). Every new row of `notification`
--              (written by the triggers of migrations 004, 005 and 010: new
--              endorsement, new comment, community validation, repair proposal,
--              report resolved) calls the Edge Function `send-push`, which sends
--              it through Firebase Cloud Messaging to the citizen's devices.
--              The row stays in the table even when the push cannot be sent
--              (criterion 4: notifications disabled on the phone, no network).
--              Also: the "new comment" text respects the commenter's privacy
--              (HU-01): "Ciudadano anónimo" when they hide their real name.
-- Requires: migrations 004, 005, 009 and 010; the pg_net extension and two
--           Vault secrets, created once by hand (never in the repo):
--             select vault.create_secret('<random secret>', 'push_webhook_secret');
--             select vault.create_secret('https://<ref>.supabase.co/functions/v1/send-push', 'push_function_url');
--           Without them no push is sent and nothing fails.
-- Idempotent: safe to run more than once.
-- Run it, then run `data model/tests/011_push_notifications_smoke_test.sql`.
-- =============================================================================

CREATE EXTENSION IF NOT EXISTS pg_net;

-- 1. After a notification row is written: ask the Edge Function to push it.
--    pg_net sends the request after the transaction commits, so a slow or
--    failing push never delays or undoes what the citizen did.
CREATE OR REPLACE FUNCTION public.push_notification()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_url TEXT;
  v_secret TEXT;
BEGIN
  SELECT decrypted_secret INTO v_url FROM vault.decrypted_secrets WHERE name = 'push_function_url';
  SELECT decrypted_secret INTO v_secret FROM vault.decrypted_secrets WHERE name = 'push_webhook_secret';
  IF v_url IS NULL OR v_secret IS NULL THEN
    RETURN NULL;
  END IF;

  PERFORM net.http_post(
    url := v_url,
    body := jsonb_build_object('record', jsonb_build_object(
      'id_user', NEW.id_user,
      'id_incident', NEW.id_incident,
      'type', NEW.type,
      'title', NEW.title,
      'message', NEW.message)),
    headers := jsonb_build_object('Content-Type', 'application/json', 'x-push-secret', v_secret)
  );
  RETURN NULL;
EXCEPTION WHEN OTHERS THEN
  -- The notification is already saved; a push that cannot start is not an error.
  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_notification_push ON public.notification;
CREATE TRIGGER trg_notification_push
  AFTER INSERT ON public.notification
  FOR EACH ROW EXECUTE FUNCTION public.push_notification();

-- 2. Migration 005, adjusted: the commenter's name only when they show it (HU-01).
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
  SELECT CASE WHEN show_real_name THEN full_name END INTO v_name
    FROM user_profile WHERE id_user = NEW.id_user;

  PERFORM add_xp(NEW.id_user, 15);

  INSERT INTO notification (id_user, id_incident, type, title, message)
  SELECT recipient.id_user, NEW.id_incident, 'NEW_COMMENT',
         'Nuevo comentario',
         'Nuevo comentario en el reporte ' || v_incident.tracking_code || ': '
           || COALESCE(v_name, 'Ciudadano anónimo') || ' aportó a la discusión.'
    FROM (
      SELECT v_incident.id_reporter_user AS id_user
      UNION
      SELECT id_user FROM incident_follow WHERE id_incident = NEW.id_incident
    ) AS recipient
   WHERE recipient.id_user <> NEW.id_user;

  RETURN NULL;
END
$$;

REVOKE ALL ON FUNCTION public.push_notification() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_comment_inserted() FROM PUBLIC, anon, authenticated;
