-- =============================================================================
-- Smoke test for migration 008 (the author can update their own report).
-- Run it in the Supabase SQL Editor AFTER migrations 006 and 008.
--
-- Unlike the other smoke tests this one runs as the `authenticated` role, so
-- row level security really applies. It always ends with an exception, on
-- purpose: PostgreSQL then rolls back every row the test created. The exception
-- text is the report: every line starts with PASS or FAIL.
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
  v_incident CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_rows     INT;
  v_report   TEXT := '';
BEGIN
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 0
    FROM generate_series(0, 1) AS g;

  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_incident, '#VIG-P1', v_author, 1, 'Original', 'Rolled back.', 'LOW', 3.4516, -76.5320, 'Calle 1 # 1-1', 'Centro', 'Cali');

  -- From here on row level security applies, as it does for the app.
  SET LOCAL ROLE authenticated;

  -- The author updates their own report: one row changes.
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  UPDATE road_incident SET title = 'Editado por la autora' WHERE id_incident = v_incident;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  v_report := v_report || pg_temp.chk('the author updates their own report', '1', v_rows::text);

  -- Another citizen cannot: the policy hides the row, no error, no change.
  PERFORM set_config('request.jwt.claim.sub', v_other::text, true);
  UPDATE road_incident SET title = 'Editado por otra persona' WHERE id_incident = v_incident;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  v_report := v_report || pg_temp.chk('another citizen updates nothing', '0', v_rows::text);

  -- The author cannot hand the report to someone else (WITH CHECK).
  PERFORM set_config('request.jwt.claim.sub', v_author::text, true);
  BEGIN
    UPDATE road_incident SET id_reporter_user = v_other WHERE id_incident = v_incident;
    v_report := v_report || pg_temp.chk('the author cannot give the report away', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('the author cannot give the report away', 'error', 'error');
  END;

  RESET ROLE;
  v_report := v_report || pg_temp.chk('only the author edit stayed', 'Editado por la autora',
    (SELECT title FROM road_incident WHERE id_incident = v_incident));
  v_report := v_report || pg_temp.chk('the report still belongs to the author', v_author::text,
    (SELECT id_reporter_user::text FROM road_incident WHERE id_incident = v_incident));

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report || 'Everything above was rolled back on purpose.';
END
$$;
