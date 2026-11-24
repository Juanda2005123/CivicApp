-- =============================================================================
-- Smoke test for migration 007 (XP taken back on delete, photos that cannot
-- change report, reports that start clean). Run it in the Supabase SQL Editor
-- AFTER migrations 004, 005, 006 and 007.
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
  v_author    CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_commenter CONSTANT UUID := '00000000-0000-0000-0000-000000000001';
  v_voter1    CONSTANT UUID := '00000000-0000-0000-0000-000000000002';
  v_voter2    CONSTANT UUID := '00000000-0000-0000-0000-000000000003';
  v_farm      CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_frozen    CONSTANT UUID := '22222222-2222-2222-2222-222222222222';
  v_fresh     CONSTANT UUID := '33333333-3333-3333-3333-333333333333';
  v_born      CONSTANT UUID := '44444444-4444-4444-4444-444444444444';
  v_seed      CONSTANT UUID := '55555555-5555-5555-5555-555555555555';
  v_photo     UUID;
  v_report    TEXT := '';
BEGIN
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 1000
    FROM generate_series(0, 3) AS g;

  -- 1. Deleting a report takes back everything it produced, not only the 100 XP.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_farm, '#VIG-F1', v_author, 1, 'Farm', 'Rolled back.', 'LOW', 3.4516, -76.5320, 'Calle 1 # 1-1', 'Centro', 'Cali');
  INSERT INTO incident_comment (id_incident, id_user, content)
  SELECT v_farm, v_author, 'Comentario ' || g FROM generate_series(1, 3) AS g;
  INSERT INTO incident_comment (id_incident, id_user, content)
  SELECT v_farm, v_commenter, 'Otro ' || g FROM generate_series(1, 2) AS g;
  INSERT INTO incident_upvote (id_user, id_incident) VALUES (v_voter1, v_farm), (v_voter2, v_farm);

  -- 1000 + 100 publish + 3 x 15 comments + 2 x 10 votes received.
  v_report := v_report || pg_temp.chk('the author earned from the report', '1165',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('the commenter earned from the report', '1030',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_commenter));

  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  DELETE FROM road_incident WHERE id_incident = v_farm;
  PERFORM set_config('request.jwt.claim.sub', '', true);

  v_report := v_report || pg_temp.chk('the author is back to where they started', '1000',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('the commenter is back to where they started', '1000',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_commenter));
  v_report := v_report || pg_temp.chk('the first voter is back to where they started', '1000',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_voter1));
  v_report := v_report || pg_temp.chk('the second voter is back to where they started', '1000',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_voter2));
  v_report := v_report || pg_temp.chk('its comments are gone', '0',
    (SELECT count(*)::text FROM incident_comment WHERE id_incident = v_farm));

  -- A report nobody touched still costs exactly the 100 XP.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_fresh, '#VIG-F3', v_author, 1, 'Limpio', 'Sin nada.', 'LOW', 3.4516, -76.5320, 'Calle 3 # 3-3', 'Centro', 'Cali');
  v_report := v_report || pg_temp.chk('publishing still pays 100 XP', '1100',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));

  -- 2. A photo cannot leave a frozen report for a fresh one.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city, created_at)
  VALUES (v_frozen, '#VIG-F2', v_author, 1, 'Congelado', 'Hace rato.', 'LOW', 3.4516, -76.5320, 'Calle 2 # 2-2', 'Centro', 'Cali',
          now() - interval '40 minutes');
  INSERT INTO incident_photo (id_incident, file_url, is_primary)
  VALUES (v_frozen, 'https://example.com/evidence.jpg', true) RETURNING id_photo INTO v_photo;

  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  BEGIN
    UPDATE incident_photo SET id_incident = v_fresh WHERE id_photo = v_photo;
    v_report := v_report || pg_temp.chk('moving a photo out of a frozen report is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('moving a photo out of a frozen report is refused',
      'Una foto no puede pasar de un reporte a otro.', SQLERRM);
  END;
  v_report := v_report || pg_temp.chk('the evidence stays where it was', v_frozen::text,
    (SELECT id_incident::text FROM incident_photo WHERE id_photo = v_photo));

  -- Editing a photo of a fresh report is still allowed.
  INSERT INTO incident_photo (id_incident, file_url, is_primary) VALUES (v_fresh, 'https://example.com/mine.jpg', false)
  RETURNING id_photo INTO v_photo;
  UPDATE incident_photo SET is_primary = true WHERE id_photo = v_photo;
  v_report := v_report || pg_temp.chk('a photo of a fresh report can still be made the cover', 'true',
    (SELECT is_primary::text FROM incident_photo WHERE id_photo = v_photo));

  -- A photo of a frozen report cannot be changed either.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  SELECT id_photo INTO v_photo FROM incident_photo WHERE id_incident = v_frozen;
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  BEGIN
    UPDATE incident_photo SET is_primary = false WHERE id_photo = v_photo;
    v_report := v_report || pg_temp.chk('editing a photo of a frozen report is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('editing a photo of a frozen report is refused',
      'Este reporte ya no se puede modificar: pasaron más de 30 minutos o tiene 5 apoyos o más.', SQLERRM);
  END;

  -- 3. A report published by a citizen starts clean.
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city,
                             created_at, current_status, validated_at)
  VALUES (v_born, '#VIG-F4', v_author, 1, 'Nacido validado', 'Con trampa.', 'LOW', 3.4516, -76.5320, 'Calle 4 # 4-4', 'Centro', 'Cali',
          now() - interval '2 days', 'COMMUNITY_VALIDATED', now() - interval '1 day');
  v_report := v_report || pg_temp.chk('a citizen cannot publish a validated report', 'REPORTED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_born));
  v_report := v_report || pg_temp.chk('a citizen cannot publish with a validation date', 'true',
    (SELECT (validated_at IS NULL)::text FROM road_incident WHERE id_incident = v_born));
  v_report := v_report || pg_temp.chk('a citizen cannot publish in the past', 'true',
    (SELECT (created_at > now() - interval '1 minute')::text FROM road_incident WHERE id_incident = v_born));

  -- The SQL Editor (seeds, moderation) keeps its freedom.
  PERFORM set_config('request.jwt.claim.sub', '', true);
  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city,
                             created_at, current_status)
  VALUES (v_seed, '#VIG-F5', v_author, 1, 'Semilla', 'Del editor.', 'LOW', 3.4516, -76.5320, 'Calle 5 # 5-5', 'Centro', 'Cali',
          now() - interval '2 days', 'RESOLVED');
  v_report := v_report || pg_temp.chk('the SQL Editor can still seed an old resolved report', 'RESOLVED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_seed));

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report || 'Everything above was rolled back on purpose.';
END
$$;
