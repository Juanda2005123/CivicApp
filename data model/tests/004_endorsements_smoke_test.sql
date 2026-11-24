-- =============================================================================
-- Smoke test for migration 004 (endorsements, XP, validation, rank).
-- Run it in the Supabase SQL Editor AFTER the migration.
--
-- It always ends with an exception, on purpose: PostgreSQL then rolls back every
-- row the test created, so nothing is left in the database. The exception text
-- is the report: every line starts with PASS or FAIL.
-- =============================================================================

CREATE OR REPLACE FUNCTION pg_temp.chk(p_name TEXT, p_expected TEXT, p_actual TEXT)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT CASE WHEN p_expected = p_actual THEN 'PASS ' ELSE 'FAIL ' END
         || p_name || ' (expected ' || p_expected || ', got ' || p_actual || E')\n'
$$;

DO $$
DECLARE
  v_author   CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_incident CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_report   TEXT := '';
  v_voter    UUID;
  i          INT;
  v_msg      TEXT;
BEGIN
  -- Fixtures: one author (i = 0) and eleven voters, all inside this transaction.
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 0
    FROM generate_series(0, 11) AS g;

  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  VALUES (v_incident, '#VIG-SMOKE', v_author, 1, 'Smoke test report', 'Rolled back.',
          'LOW', 3.4516, -76.5320, 'Calle 1 # 1-1', 'Centro', 'Cali');

  -- Since migration 006 publishing pays +100 XP; this test measures only its own XP.
  UPDATE user_profile SET experience_points = 0 WHERE id_user = v_author;

  -- RN-05: the author cannot endorse their own report.
  BEGIN
    INSERT INTO incident_upvote (id_user, id_incident) VALUES (v_author, v_incident);
    v_report := v_report || pg_temp.chk('self-vote is rejected', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('self-vote is rejected', 'No puedes apoyar tu propio reporte.', SQLERRM);
  END;

  -- First endorsement: +10 XP to voter and author, one NEW_UPVOTE notification.
  INSERT INTO incident_upvote (id_user, id_incident)
  VALUES ('00000000-0000-0000-0000-000000000001', v_incident);
  v_report := v_report || pg_temp.chk('voter earns 10 XP', '10',
    (SELECT experience_points::text FROM user_profile WHERE id_user = '00000000-0000-0000-0000-000000000001'));
  v_report := v_report || pg_temp.chk('author earns 10 XP', '10',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('author gets a NEW_UPVOTE notification', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_author AND type = 'NEW_UPVOTE'));

  -- Votes 2 to 9: still not validated.
  FOR i IN 2..9 LOOP
    INSERT INTO incident_upvote (id_user, id_incident)
    VALUES (('00000000-0000-0000-0000-' || lpad(i::text, 12, '0'))::uuid, v_incident);
  END LOOP;
  v_report := v_report || pg_temp.chk('9 votes keep REPORTED', 'REPORTED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_incident));

  -- Vote 10: validation, +500 XP once, one COMMUNITY_VALIDATION notification.
  INSERT INTO incident_upvote (id_user, id_incident)
  VALUES ('00000000-0000-0000-0000-000000000010', v_incident);
  v_report := v_report || pg_temp.chk('10th vote validates the report', 'COMMUNITY_VALIDATED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_incident));
  v_report := v_report || pg_temp.chk('validated_at is set', 'true',
    (SELECT (validated_at IS NOT NULL)::text FROM road_incident WHERE id_incident = v_incident));
  v_report := v_report || pg_temp.chk('author has 10 x 10 + 500 XP', '600',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('author gets one COMMUNITY_VALIDATION notification', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_author AND type = 'COMMUNITY_VALIDATION'));

  -- Revoking: -10 XP to both, the bonus and the status stay.
  DELETE FROM incident_upvote
   WHERE id_user = '00000000-0000-0000-0000-000000000010' AND id_incident = v_incident;
  v_report := v_report || pg_temp.chk('revoking costs the author 10 XP', '590',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('revoking returns the voter to 0 XP', '0',
    (SELECT experience_points::text FROM user_profile WHERE id_user = '00000000-0000-0000-0000-000000000010'));
  v_report := v_report || pg_temp.chk('status stays COMMUNITY_VALIDATED', 'COMMUNITY_VALIDATED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_incident));

  -- Endorsing again reaches 10 votes again: no second +500.
  INSERT INTO incident_upvote (id_user, id_incident)
  VALUES ('00000000-0000-0000-0000-000000000010', v_incident);
  v_report := v_report || pg_temp.chk('bonus is not paid twice', '600',
    (SELECT experience_points::text FROM user_profile WHERE id_user = v_author));
  v_report := v_report || pg_temp.chk('still a single COMMUNITY_VALIDATION notification', '1',
    (SELECT count(*)::text FROM notification WHERE id_user = v_author AND type = 'COMMUNITY_VALIDATION'));

  -- Duplicate endorsement is rejected by the primary key (HU-15, criterion 4).
  BEGIN
    INSERT INTO incident_upvote (id_user, id_incident)
    VALUES ('00000000-0000-0000-0000-000000000010', v_incident);
    v_report := v_report || pg_temp.chk('duplicate vote is rejected', 'error', 'no error');
  EXCEPTION WHEN unique_violation THEN
    v_report := v_report || pg_temp.chk('duplicate vote is rejected', 'error', 'error');
  END;

  -- XP never goes below zero, and the rank follows the XP (RN-09).
  PERFORM add_xp('00000000-0000-0000-0000-000000000011', -50);
  v_report := v_report || pg_temp.chk('XP floors at 0', '0',
    (SELECT experience_points::text FROM user_profile WHERE id_user = '00000000-0000-0000-0000-000000000011'));
  UPDATE user_profile SET experience_points = 1000 WHERE id_user = v_author;
  v_report := v_report || pg_temp.chk('1000 XP is rank 2', '2',
    (SELECT id_rank::text FROM user_profile WHERE id_user = v_author));
  UPDATE user_profile SET experience_points = 999 WHERE id_user = v_author;
  v_report := v_report || pg_temp.chk('999 XP is rank 1', '1',
    (SELECT id_rank::text FROM user_profile WHERE id_user = v_author));

  -- Deleting the report (HU-18) takes back the XP its endorsements produced (migration 007).
  SELECT experience_points INTO i FROM user_profile WHERE id_user = '00000000-0000-0000-0000-000000000001';
  DELETE FROM road_incident WHERE id_incident = v_incident;
  v_report := v_report || pg_temp.chk('deleting the report takes back the voter XP', GREATEST(0, i - 10)::text,
    (SELECT experience_points::text FROM user_profile WHERE id_user = '00000000-0000-0000-0000-000000000001'));

  v_msg := E'\n' || v_report || E'\nEverything above was rolled back on purpose.';
  RAISE EXCEPTION 'SMOKE TEST REPORT:%', v_msg;
END
$$;
