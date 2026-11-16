-- =============================================================================
-- Smoke test for migration 005 (comments, XP, deletion window, notifications).
-- Run it in the Supabase SQL Editor AFTER migrations 004 and 005.
--
-- It always ends with an exception, on purpose: PostgreSQL then rolls back every
-- row the test created, so nothing is left in the database. The exception text
-- is the report: every line starts with PASS or FAIL.
-- =============================================================================

CREATE OR REPLACE FUNCTION pg_temp.chk(p_name TEXT, p_expected TEXT, p_actual TEXT)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT CASE WHEN p_expected = p_actual THEN 'PASS ' ELSE 'FAIL ' END
         || p_name || ' (expected ' || p_expected || ', got ' || p_actual || ')' || chr(10)
$$;

DO $$
DECLARE
  v_author    CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_commenter CONSTANT UUID := '00000000-0000-0000-0000-000000000001';
  v_follower  CONSTANT UUID := '00000000-0000-0000-0000-000000000002';
  v_incident  CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_comment   UUID;
  v_old       UUID;
  v_report    TEXT := '';
BEGIN
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 0
    FROM generate_series(0, 2) AS g;

  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_incident, '#VIG-SMOKE', v_author, 1, 'Smoke test report', 'Rolled back.',
          'LOW', 3.4516, -76.5320, 'Calle 1 # 1-1', 'Centro', 'Cali');

  INSERT INTO incident_follow (id_user, id_incident) VALUES (v_follower, v_incident);

  -- A comment: +15 XP and a notification for the author and the follower, not for the commenter.
  INSERT INTO incident_comment (id_incident, id_user, content)
  VALUES (v_incident, v_commenter, 'Sigue igual de mal.') RETURNING id_comment INTO v_comment;
  v_report := v_report || pg_temp.chk('commenter earns 15 XP', '15',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_commenter));
  v_report := v_report || pg_temp.chk('author is notified', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_author AND type = 'NEW_COMMENT'));
  v_report := v_report || pg_temp.chk('follower is notified', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_follower AND type = 'NEW_COMMENT'));
  v_report := v_report || pg_temp.chk('commenter is not notified', '0',
    (SELECT count(*)::text FROM notification WHERE id_user = v_commenter AND type = 'NEW_COMMENT'));
  v_report := v_report || pg_temp.chk('notification names the commenter', 'true',
    (SELECT (message LIKE '%Smoke User 1%')::text FROM notification WHERE id_user = v_author AND type = 'NEW_COMMENT'));

  -- The author commenting on their own report notifies the follower only.
  INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_incident, v_author, 'Gracias por avisar.');
  v_report := v_report || pg_temp.chk('author earns 15 XP too', '15',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('author is not notified of their own comment', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_author AND type = 'NEW_COMMENT'));

  -- A photo-only comment is valid: empty text.
  INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_incident, v_commenter, '');
  v_report := v_report || pg_temp.chk('photo-only comment earns 15 XP', '30',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_commenter));

  -- The text has a limit.
  BEGIN
    INSERT INTO incident_comment (id_incident, id_user, content) VALUES (v_incident, v_commenter, repeat('x', 501));
    v_report := v_report || pg_temp.chk('501 characters are rejected', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('501 characters are rejected',
      'El comentario no puede superar los 500 caracteres.', SQLERRM);
  END;

  -- Deleting inside the window: -15 XP, text and photo go.
  INSERT INTO comment_photo (id_comment, file_url) VALUES (v_comment, 'https://example.com/p.jpg');
  PERFORM set_config('request.jwt.claim.sub', v_commenter::text, true);
  DELETE FROM incident_comment WHERE id_comment = v_comment;
  v_report := v_report || pg_temp.chk('deleting costs 15 XP', '15',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_commenter));
  v_report := v_report || pg_temp.chk('the photo goes with the comment', '0',
    (SELECT count(*)::text FROM comment_photo WHERE id_comment = v_comment));

  -- Deleting after 5 minutes is refused for a signed-in citizen.
  INSERT INTO incident_comment (id_incident, id_user, content, created_at)
  VALUES (v_incident, v_commenter, 'Comentario viejo.', now() - interval '6 minutes') RETURNING id_comment INTO v_old;
  BEGIN
    DELETE FROM incident_comment WHERE id_comment = v_old;
    v_report := v_report || pg_temp.chk('late delete is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('late delete is refused',
      'Solo puedes eliminar tu comentario durante los primeros 5 minutos.', SQLERRM);
  END;
  v_report := v_report || pg_temp.chk('the late comment is still there', '1',
    (SELECT count(*)::text FROM incident_comment WHERE id_comment = v_old));

  -- With no signed-in user (SQL Editor, moderation) the window does not apply.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  DELETE FROM incident_comment WHERE id_comment = v_old;
  v_report := v_report || pg_temp.chk('moderation can delete an old comment', '0',
    (SELECT count(*)::text FROM incident_comment WHERE id_comment = v_old));

  -- Deleting the whole report (HU-18) cascades old comments without error or XP changes.
  INSERT INTO incident_comment (id_incident, id_user, content, created_at)
  VALUES (v_incident, v_commenter, 'Otro viejo.', now() - interval '10 minutes');
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  DELETE FROM road_incident WHERE id_incident = v_incident;
  v_report := v_report || pg_temp.chk('cascade delete removes every comment', '0',
    (SELECT count(*)::text FROM incident_comment WHERE id_incident = v_incident));

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report || 'Everything above was rolled back on purpose.';
END
$$;
