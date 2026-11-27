-- =============================================================================
-- Smoke test for migration 011 (push notifications, HU-24). Run it AFTER
-- migrations 004, 005, 009, 010 and 011 and after creating the two Vault
-- secrets the migration describes.
--
-- It always ends with an exception, on purpose: PostgreSQL then rolls back every
-- row the test created, and the push requests queued by pg_net with them (pg_net
-- only sends after a commit), so no phone receives anything. The exception text
-- is the report: every line starts with PASS or FAIL.
-- =============================================================================

CREATE OR REPLACE FUNCTION pg_temp.chk(p_name TEXT, p_expected TEXT, p_actual TEXT)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT CASE WHEN p_expected = p_actual THEN 'PASS ' ELSE 'FAIL ' END
         || p_name || ' (expected ' || p_expected || ', got ' || COALESCE(p_actual, 'NULL') || ')' || chr(10)
$$;

DO $$
DECLARE
  v_author  CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_visible CONSTANT UUID := '00000000-0000-0000-0000-000000000001';
  v_hidden  CONSTANT UUID := '00000000-0000-0000-0000-000000000002';
  v_report  CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_queued_before INT;
  v_report_text TEXT := '';
BEGIN
  v_report_text := v_report_text || pg_temp.chk('the push trigger exists', '1',
    (SELECT count(*)::text FROM pg_trigger WHERE tgname = 'trg_notification_push'));
  v_report_text := v_report_text || pg_temp.chk('the Vault secrets exist', '2',
    (SELECT count(*)::text FROM vault.decrypted_secrets WHERE name IN ('push_function_url', 'push_webhook_secret')));

  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, show_real_name)
  VALUES (v_author,  1, 'Smoke Autora',  'smoke0@vigia.test', 'Cali', 'Cali', true),
         (v_visible, 1, 'Smoke Visible', 'smoke1@vigia.test', 'Cali', 'Cali', true),
         (v_hidden,  1, 'Smoke Oculta',  'smoke2@vigia.test', 'Cali', 'Cali', false);

  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_report, '#VIG-PUSH', v_author, 1, 'Hueco', 'Rolled back.', 'LOW', 3.4516, -76.5320,
          'Calle 1 # 1-1', 'Centro', 'Cali');

  -- 1. A new notification queues one push request.
  SELECT count(*) INTO v_queued_before FROM net.http_request_queue;
  INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_report, v_visible, 'Sigue igual.');
  v_report_text := v_report_text || pg_temp.chk('a comment notifies the author', '1',
    (SELECT count(*)::text FROM notification WHERE id_incident = v_report AND id_user = v_author AND type = 'NEW_COMMENT'));
  v_report_text := v_report_text || pg_temp.chk('the notification queued one push', '1',
    ((SELECT count(*) FROM net.http_request_queue) - v_queued_before)::text);

  -- 2. The text respects the commenter's privacy (HU-01).
  v_report_text := v_report_text || pg_temp.chk('a visible commenter is named',
    'Nuevo comentario en el reporte #VIG-PUSH: Smoke Visible aportó a la discusión.',
    (SELECT message FROM notification WHERE id_incident = v_report ORDER BY created_at LIMIT 1));
  INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_report, v_hidden, 'También lo vi.');
  v_report_text := v_report_text || pg_temp.chk('a hidden commenter is anonymous', '1',
    (SELECT count(*)::text FROM notification
      WHERE id_incident = v_report AND message LIKE '%Ciudadano anónimo aportó a la discusión.'));
  v_report_text := v_report_text || pg_temp.chk('the hidden name never reaches the text', '0',
    (SELECT count(*)::text FROM notification WHERE id_incident = v_report AND message LIKE '%Smoke Oculta%'));

  -- 3. Nobody is notified of their own comment.
  INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_report, v_author, 'Gracias.');
  v_report_text := v_report_text || pg_temp.chk('the author is not told about their own comment', '2',
    (SELECT count(*)::text FROM notification WHERE id_incident = v_report AND type = 'NEW_COMMENT'));

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report_text || 'Everything above was rolled back on purpose.';
END
$$;
