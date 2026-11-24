-- =============================================================================
-- Smoke test for migration 006 (edit and delete window, publish XP, photos,
-- protected experience points). Run it in the Supabase SQL Editor AFTER
-- migrations 004, 005 and 006.
--
-- It always ends with an exception, on purpose: PostgreSQL then rolls back every
-- row the test created, so nothing is left in the database. The exception text
-- is the report: every line starts with PASS or FAIL.
--
-- A signed-in citizen is simulated with set_config('request.jwt.claim.sub', ...);
-- an empty value is the SQL Editor (moderation), where the rules do not apply.
-- =============================================================================

CREATE OR REPLACE FUNCTION pg_temp.chk(p_name TEXT, p_expected TEXT, p_actual TEXT)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT CASE WHEN p_expected = p_actual THEN 'PASS ' ELSE 'FAIL ' END
         || p_name || ' (expected ' || p_expected || ', got ' || p_actual || ')' || chr(10)
$$;

DO $$
DECLARE
  v_author   CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_other    CONSTANT UUID := '00000000-0000-0000-0000-000000000001';
  v_fresh    CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_old      CONSTANT UUID := '22222222-2222-2222-2222-222222222222';
  v_busy     CONSTANT UUID := '33333333-3333-3333-3333-333333333333';
  v_report   TEXT := '';
  v_photo    UUID;
  v_before   TIMESTAMPTZ;
  v_xp       INT;
BEGIN
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 0
    FROM generate_series(0, 12) AS g;

  -- 1. Publishing pays +100 XP (RN-08), by trigger.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_fresh, '#VIG-S1', v_author, 1, 'Hueco', 'Original.', 'LOW', 3.4516, -76.5320, 'Calle 1 # 1-1', 'Centro', 'Cali');
  v_report := v_report || pg_temp.chk('publishing pays 100 XP', '100',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));

  -- 2. The author edits inside the window: the code stays, updated_at moves.
  SELECT updated_at INTO v_before FROM road_incident WHERE id_incident = v_fresh;
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  UPDATE road_incident SET title = 'Hueco profundo', description = 'Corregido.' WHERE id_incident = v_fresh;
  v_report := v_report || pg_temp.chk('the author can edit inside the window', 'Hueco profundo',
    (SELECT title FROM road_incident WHERE id_incident = v_fresh));
  v_report := v_report || pg_temp.chk('the tracking code is kept', '#VIG-S1',
    (SELECT tracking_code FROM road_incident WHERE id_incident = v_fresh));
  v_report := v_report || pg_temp.chk('updated_at moved', 'true',
    (SELECT (updated_at >= v_before)::text FROM road_incident WHERE id_incident = v_fresh));

  -- 3. Fields a citizen never edits.
  BEGIN
    UPDATE road_incident SET tracking_code = '#VIG-HACK' WHERE id_incident = v_fresh;
    v_report := v_report || pg_temp.chk('tracking code is immutable', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('tracking code is immutable', 'Ese dato del reporte no se puede cambiar.', SQLERRM);
  END;
  BEGIN
    UPDATE road_incident SET current_status = 'RESOLVED' WHERE id_incident = v_fresh;
    v_report := v_report || pg_temp.chk('status is immutable', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('status is immutable', 'Ese dato del reporte no se puede cambiar.', SQLERRM);
  END;

  -- 4. Someone else cannot edit it.
  PERFORM set_config('request.jwt.claim.sub', v_other::text, true);
  BEGIN
    UPDATE road_incident SET title = 'De otro' WHERE id_incident = v_fresh;
    v_report := v_report || pg_temp.chk('another citizen cannot edit', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('another citizen cannot edit', 'Solo quien publicó el reporte puede modificarlo.', SQLERRM);
  END;

  -- 5. Photos: at most 3, only the author inside the window.
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  INSERT INTO incident_photo (id_incident, file_url, is_primary) VALUES (v_fresh, 'https://example.com/1.jpg', true);
  INSERT INTO incident_photo (id_incident, file_url) VALUES (v_fresh, 'https://example.com/2.jpg');
  INSERT INTO incident_photo (id_incident, file_url) VALUES (v_fresh, 'https://example.com/3.jpg')
  RETURNING id_photo INTO v_photo;
  BEGIN
    INSERT INTO incident_photo (id_incident, file_url) VALUES (v_fresh, 'https://example.com/4.jpg');
    v_report := v_report || pg_temp.chk('a 4th photo is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a 4th photo is refused', 'Un reporte admite hasta 3 fotos.', SQLERRM);
  END;
  DELETE FROM incident_photo WHERE id_photo = v_photo;
  v_report := v_report || pg_temp.chk('a photo can be removed inside the window', '2',
    (SELECT count(*)::text FROM incident_photo WHERE id_incident = v_fresh));

  -- 6. Experience points and rank are not the citizen's to write.
  BEGIN
    UPDATE user_profile SET experience_points = 99999 WHERE id_user = v_author;
    v_report := v_report || pg_temp.chk('a citizen cannot raise their own XP', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a citizen cannot raise their own XP',
      'Los puntos y el nivel los calcula VIGÍA; no se pueden cambiar a mano.', SQLERRM);
  END;
  BEGIN
    UPDATE user_profile SET id_rank = 4 WHERE id_user = v_author;
    v_report := v_report || pg_temp.chk('a citizen cannot raise their own rank', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a citizen cannot raise their own rank',
      'Los puntos y el nivel los calcula VIGÍA; no se pueden cambiar a mano.', SQLERRM);
  END;
  UPDATE user_profile SET last_city = 'Bogotá' WHERE id_user = v_author;
  v_report := v_report || pg_temp.chk('other profile fields still update', 'Bogotá',
    (SELECT last_city FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('XP is untouched', '100',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  BEGIN
    INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
    VALUES (v_author, 1, 'Nuevo', 'nuevo@vigia.test', 'Cali', 'Cali', 500);
    v_report := v_report || pg_temp.chk('a new account cannot start with XP', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    -- The guard comes first; a duplicate key would be a different message.
    v_report := v_report || pg_temp.chk('a new account cannot start with XP',
      'Los puntos de reputación los calcula VIGÍA; una cuenta nueva empieza en 0.', SQLERRM);
  END;

  -- 7. A report older than 30 minutes is frozen.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city, created_at)
  VALUES (v_old, '#VIG-S2', v_author, 1, 'Viejo', 'Hace rato.', 'LOW', 3.4516, -76.5320, 'Calle 2 # 2-2', 'Centro', 'Cali',
          now() - interval '31 minutes');
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  BEGIN
    UPDATE road_incident SET title = 'Tarde' WHERE id_incident = v_old;
    v_report := v_report || pg_temp.chk('edit after 30 minutes is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('edit after 30 minutes is refused',
      'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.', SQLERRM);
  END;
  BEGIN
    DELETE FROM road_incident WHERE id_incident = v_old;
    v_report := v_report || pg_temp.chk('delete after 30 minutes is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('delete after 30 minutes is refused',
      'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.', SQLERRM);
  END;
  BEGIN
    INSERT INTO incident_photo (id_incident, file_url) VALUES (v_old, 'https://example.com/late.jpg');
    v_report := v_report || pg_temp.chk('a photo after 30 minutes is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a photo after 30 minutes is refused',
      'Este reporte ya no se puede modificar: pasaron más de 30 minutos o tiene 5 apoyos o más.', SQLERRM);
  END;
  v_report := v_report || pg_temp.chk('the old report is still there', '1',
    (SELECT count(*)::text FROM road_incident WHERE id_incident = v_old));

  -- 8. Moderation (no signed-in user) can still delete an old report.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  DELETE FROM road_incident WHERE id_incident = v_old;
  v_report := v_report || pg_temp.chk('moderation can delete an old report', '0',
    (SELECT count(*)::text FROM road_incident WHERE id_incident = v_old));

  -- 9. A report with 5 endorsements is frozen; with 4 it is not.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_busy, '#VIG-S3', v_author, 1, 'Muy apoyado', 'Con apoyos.', 'LOW', 3.4516, -76.5320, 'Calle 3 # 3-3', 'Centro', 'Cali');
  INSERT INTO incident_upvote (id_user, id_incident)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, v_busy FROM generate_series(1, 4) AS g;
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  UPDATE road_incident SET title = 'Con 4 apoyos' WHERE id_incident = v_busy;
  v_report := v_report || pg_temp.chk('4 endorsements still allow editing', 'Con 4 apoyos',
    (SELECT title FROM road_incident WHERE id_incident = v_busy));

  PERFORM set_config('request.jwt.claim.sub', '', true);
  INSERT INTO incident_upvote (id_user, id_incident) VALUES ('00000000-0000-0000-0000-000000000005', v_busy);
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  BEGIN
    UPDATE road_incident SET title = 'Con 5 apoyos' WHERE id_incident = v_busy;
    v_report := v_report || pg_temp.chk('5 endorsements freeze the report', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('5 endorsements freeze the report',
      'Este reporte ya no se puede modificar ni eliminar: pasaron más de 30 minutos o tiene 5 apoyos o más.', SQLERRM);
  END;

  -- 10. A frozen report still validates by itself at the 10th endorsement
  --     (the trigger of migration 004 is not blocked by the freeze).
  PERFORM set_config('request.jwt.claim.sub', '', true);
  INSERT INTO incident_upvote (id_user, id_incident)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, v_busy FROM generate_series(6, 9) AS g;
  PERFORM set_config('request.jwt.claim.sub', '00000000-0000-0000-0000-000000000010', true);
  INSERT INTO incident_upvote (id_user, id_incident) VALUES ('00000000-0000-0000-0000-000000000010', v_busy);
  v_report := v_report || pg_temp.chk('the 10th endorsement validates a frozen report', 'COMMUNITY_VALIDATED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_busy));

  -- 11. Deleting inside the window takes the 100 XP back and the photos go.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  SELECT experience_points INTO v_xp FROM user_profile WHERE id_user = v_author;
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  DELETE FROM road_incident WHERE id_incident = v_fresh;
  v_report := v_report || pg_temp.chk('deleting costs 100 XP', (v_xp - 100)::text,
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('the report is gone', '0',
    (SELECT count(*)::text FROM road_incident WHERE id_incident = v_fresh));
  v_report := v_report || pg_temp.chk('its photos are gone', '0',
    (SELECT count(*)::text FROM incident_photo WHERE id_incident = v_fresh));

  -- 12. The XP never goes below zero when the bonus was already spent.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES ('44444444-4444-4444-4444-444444444444', '#VIG-S4', v_other, 1, 'Otro', 'Otro.', 'LOW', 3.4516, -76.5320, 'Calle 4 # 4-4', 'Centro', 'Cali');
  UPDATE user_profile SET experience_points = 40 WHERE id_user = v_other;
  PERFORM set_config('request.jwt.claim.sub', v_other::text, true);
  DELETE FROM road_incident WHERE id_incident = '44444444-4444-4444-4444-444444444444';
  v_report := v_report || pg_temp.chk('XP floors at 0 when deleting', '0',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_other));

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report || 'Everything above was rolled back on purpose.';
END
$$;
