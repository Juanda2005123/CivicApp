-- =============================================================================
-- Smoke test for migration 010 (community resolution of a report, HU-25).
-- Run it AFTER migrations 004, 006, 007 and 010.
--
-- It always ends with an exception, on purpose: PostgreSQL then rolls back every
-- row the test created, so nothing is left in the database. The exception text
-- is the report: every line starts with PASS or FAIL.
--
-- A signed-in citizen is simulated with set_config('request.jwt.claim.sub', ...);
-- an empty value is the SQL Editor (moderation), where the rules do not apply.
-- The last block runs as the `authenticated` role so row level security applies.
-- =============================================================================

CREATE OR REPLACE FUNCTION pg_temp.chk(p_name TEXT, p_expected TEXT, p_actual TEXT)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT CASE WHEN p_expected = p_actual THEN 'PASS ' ELSE 'FAIL ' END
         || p_name || ' (expected ' || p_expected || ', got ' || COALESCE(p_actual, 'NULL') || ')' || chr(10)
$$;

CREATE OR REPLACE FUNCTION pg_temp.as_user(p_user UUID)
RETURNS VOID LANGUAGE sql AS $$
  SELECT set_config('request.jwt.claim.sub', COALESCE(p_user::text, ''), true)
$$;

CREATE OR REPLACE FUNCTION pg_temp.xp(p_user UUID)
RETURNS TEXT LANGUAGE sql AS $$
  SELECT experience_points::text FROM user_profile WHERE id_user = p_user
$$;

DO $$
DECLARE
  v_author   CONSTANT UUID := '00000000-0000-0000-0000-000000000000';
  v_neighbor CONSTANT UUID := '00000000-0000-0000-0000-000000000001';
  v_voter1   CONSTANT UUID := '00000000-0000-0000-0000-000000000002';
  v_voter2   CONSTANT UUID := '00000000-0000-0000-0000-000000000003';
  v_voter3   CONSTANT UUID := '00000000-0000-0000-0000-000000000004';
  v_own      CONSTANT UUID := '11111111-1111-1111-1111-111111111111';
  v_quorum   CONSTANT UUID := '22222222-2222-2222-2222-222222222222';
  v_objected CONSTANT UUID := '33333333-3333-3333-3333-333333333333';
  v_decided  CONSTANT UUID := '44444444-4444-4444-4444-444444444444';
  v_old      CONSTANT UUID := '55555555-5555-5555-5555-555555555555';
  v_rls      CONSTANT UUID := '66666666-6666-6666-6666-666666666666';
  v_res      UUID;
  v_res2     UUID;
  v_rows     INT;
  v_report   TEXT := '';
BEGIN
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city, experience_points)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke User ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali', 0
    FROM generate_series(0, 4) AS g;

  INSERT INTO road_incident (id_incident, tracking_code, id_reporter_user, id_category, title, description,
                             severity, latitude, longitude, formatted_address, neighborhood, city)
  SELECT v.id, v.code, v_author, 1, 'Hueco ' || v.code, 'Rolled back.', 'LOW', 3.4516, -76.5320,
         'Calle 1 # 1-1', 'Centro', 'Cali'
    FROM (VALUES (v_own, '#VIG-R1'), (v_quorum, '#VIG-R2'), (v_objected, '#VIG-R3'),
                 (v_decided, '#VIG-R4'), (v_old, '#VIG-R5'), (v_rls, '#VIG-R6')) AS v(id, code);
  -- Publishing paid +100 XP each; start every XP check from 0.
  UPDATE user_profile SET experience_points = 0 WHERE id_user = v_author;

  -- 1. The author's own proposal closes the report at once, with no XP.
  PERFORM pg_temp.as_user(v_author);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_own, v_author, 'https://example.com/fixed.jpg', 'Ya taparon el hueco.')
  RETURNING id_resolution INTO v_res;
  v_report := v_report || pg_temp.chk('the author''s proposal is approved by the author', 'APPROVED_BY_AUTHOR',
    (SELECT status FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('the author''s proposal resolves the report', 'RESOLVED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_own));
  v_report := v_report || pg_temp.chk('the report remembers who resolved it', v_author::text,
    (SELECT id_resolver_user::text FROM road_incident WHERE id_incident = v_own));
  v_report := v_report || pg_temp.chk('closing your own report pays no XP', '0', pg_temp.xp(v_author));

  -- Nobody proposes on a resolved report.
  PERFORM pg_temp.as_user(v_neighbor);
  BEGIN
    INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
    VALUES (v_own, v_neighbor, 'https://example.com/x.jpg', 'Otra vez.');
    v_report := v_report || pg_temp.chk('a resolved report takes no proposal', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a resolved report takes no proposal',
      'Este reporte ya está resuelto.', SQLERRM);
  END;

  -- 2. A neighbor's proposal: the report goes under review, the author is told.
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description, status, confirmation_votes)
  VALUES (v_quorum, v_voter3, 'https://example.com/fixed.jpg', 'Lo repavimentaron.', 'APPROVED_BY_COMMUNITY', 99)
  RETURNING id_resolution INTO v_res;
  v_report := v_report || pg_temp.chk('the proponent is whoever is signed in', v_neighbor::text,
    (SELECT id_proponent_user::text FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('a proposal always starts pending with no votes', 'PENDING/0',
    (SELECT status || '/' || confirmation_votes FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('the report is under review', 'UNDER_REVIEW',
    (SELECT current_status FROM road_incident WHERE id_incident = v_quorum));
  v_report := v_report || pg_temp.chk('the author is told about the proposal', '1',
    (SELECT count(*)::text FROM notification
      WHERE id_user = v_author AND id_incident = v_quorum AND type = 'RESOLUTION_PROPOSAL'));

  -- Only one pending proposal per report.
  PERFORM pg_temp.as_user(v_voter1);
  BEGIN
    INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
    VALUES (v_quorum, v_voter1, 'https://example.com/y.jpg', 'También lo vi.');
    v_report := v_report || pg_temp.chk('a second pending proposal is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a second pending proposal is refused',
      'Ya hay una propuesta de reparación en verificación para este reporte.', SQLERRM);
  END;

  -- The proponent and the author cannot vote.
  PERFORM pg_temp.as_user(v_neighbor);
  BEGIN
    INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_neighbor, v_res);
    v_report := v_report || pg_temp.chk('the proponent cannot confirm', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('the proponent cannot confirm',
      'No puedes votar tu propia propuesta.', SQLERRM);
  END;
  PERFORM pg_temp.as_user(v_author);
  BEGIN
    INSERT INTO resolution_objection (id_user, id_resolution) VALUES (v_author, v_res);
    v_report := v_report || pg_temp.chk('the author cannot object', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('the author cannot object',
      'Como autor del reporte, acepta o rechaza la propuesta.', SQLERRM);
  END;

  -- One vote per person, and never both kinds.
  PERFORM pg_temp.as_user(v_voter1);
  INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter1, v_res);
  BEGIN
    INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter1, v_res);
    v_report := v_report || pg_temp.chk('confirming twice is refused', 'error', 'no error');
  EXCEPTION WHEN unique_violation THEN
    v_report := v_report || pg_temp.chk('confirming twice is refused', 'error', 'error');
  END;
  BEGIN
    INSERT INTO resolution_objection (id_user, id_resolution) VALUES (v_voter1, v_res);
    v_report := v_report || pg_temp.chk('confirming and objecting is refused', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('confirming and objecting is refused', 'Ya votaste esta propuesta.', SQLERRM);
  END;

  -- 3. Three confirmations resolve the report and pay +50 XP to the proponent.
  PERFORM pg_temp.as_user(v_voter2);
  INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter2, v_res);
  v_report := v_report || pg_temp.chk('two confirmations are not enough', 'PENDING/2',
    (SELECT status || '/' || confirmation_votes FROM incident_resolution WHERE id_resolution = v_res));
  PERFORM pg_temp.as_user(v_voter3);
  INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter3, v_res);
  v_report := v_report || pg_temp.chk('the third confirmation approves it', 'APPROVED_BY_COMMUNITY/3',
    (SELECT status || '/' || confirmation_votes FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('the report is resolved', 'RESOLVED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_quorum));
  v_report := v_report || pg_temp.chk('the proponent earns 50 XP', '50', pg_temp.xp(v_neighbor));
  v_report := v_report || pg_temp.chk('the author and the proponent are told', '2',
    (SELECT count(*)::text FROM notification WHERE id_incident = v_quorum AND type = 'REPORT_RESOLVED'));

  -- 4. Three objections reject it and the report goes back to where it was.
  PERFORM pg_temp.as_user(NULL);
  UPDATE road_incident SET validated_at = now(), current_status = 'COMMUNITY_VALIDATED' WHERE id_incident = v_objected;
  PERFORM pg_temp.as_user(v_neighbor);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_objected, v_neighbor, 'https://example.com/fake.jpg', 'Foto de otra calle.')
  RETURNING id_resolution INTO v_res;
  PERFORM pg_temp.as_user(v_voter1);
  INSERT INTO resolution_objection (id_user, id_resolution, reason) VALUES (v_voter1, v_res, 'No es esta calle');
  PERFORM pg_temp.as_user(v_voter2);
  INSERT INTO resolution_objection (id_user, id_resolution) VALUES (v_voter2, v_res);
  PERFORM pg_temp.as_user(v_voter3);
  INSERT INTO resolution_objection (id_user, id_resolution) VALUES (v_voter3, v_res);
  v_report := v_report || pg_temp.chk('the third objection rejects it', 'REJECTED_BY_COMMUNITY/3',
    (SELECT status || '/' || objection_votes FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('a validated report goes back to validated', 'COMMUNITY_VALIDATED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_objected));
  v_report := v_report || pg_temp.chk('a rejected proposal pays nothing', '50', pg_temp.xp(v_neighbor));
  BEGIN
    INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter3, v_res);
    v_report := v_report || pg_temp.chk('a closed proposal takes no votes', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('a closed proposal takes no votes',
      'Esta propuesta ya no está en verificación.', SQLERRM);
  END;
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_objected, v_voter3, 'https://example.com/real.jpg', 'Ahora sí la arreglaron.');
  v_report := v_report || pg_temp.chk('the slot is free for a new proposal', '1',
    (SELECT count(*)::text FROM incident_resolution WHERE id_incident = v_objected AND status = 'PENDING'));

  -- 5. The author decides: reject needs a reason, accept resolves and pays.
  PERFORM pg_temp.as_user(v_neighbor);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_decided, v_neighbor, 'https://example.com/a.jpg', 'Le echaron asfalto.')
  RETURNING id_resolution INTO v_res;

  -- Somebody else cannot decide (as the SQL Editor role the policy is skipped,
  -- so the trigger answers; the RLS block below checks the policy).
  PERFORM pg_temp.as_user(v_voter1);
  BEGIN
    UPDATE incident_resolution SET status = 'APPROVED_BY_AUTHOR' WHERE id_resolution = v_res;
    v_report := v_report || pg_temp.chk('only the author decides', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('only the author decides',
      'Solo quien publicó el reporte puede aceptar o rechazar la propuesta.', SQLERRM);
  END;

  PERFORM pg_temp.as_user(v_author);
  BEGIN
    UPDATE incident_resolution SET status = 'REJECTED_BY_AUTHOR', rejection_reason = '  ' WHERE id_resolution = v_res;
    v_report := v_report || pg_temp.chk('rejecting needs a reason', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('rejecting needs a reason', 'Escribe por qué rechazas la propuesta.', SQLERRM);
  END;
  BEGIN
    UPDATE incident_resolution SET confirmation_votes = 3 WHERE id_resolution = v_res;
    v_report := v_report || pg_temp.chk('the author cannot fake votes', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('the author cannot fake votes', 'Ese dato de la propuesta no se puede cambiar.', SQLERRM);
  END;
  UPDATE incident_resolution SET status = 'REJECTED_BY_AUTHOR', rejection_reason = 'Solo le echaron tierra.'
   WHERE id_resolution = v_res;
  v_report := v_report || pg_temp.chk('the author rejects with a reason', 'REJECTED_BY_AUTHOR',
    (SELECT status FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('a rejected report goes back to reported', 'REPORTED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_decided));

  PERFORM pg_temp.as_user(v_voter2);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_decided, v_voter2, 'https://example.com/b.jpg', 'Ahora sí con asfalto.')
  RETURNING id_resolution INTO v_res;
  PERFORM pg_temp.as_user(v_author);
  UPDATE incident_resolution SET status = 'APPROVED_BY_AUTHOR', rejection_reason = 'ignorado' WHERE id_resolution = v_res;
  v_report := v_report || pg_temp.chk('the author accepts', 'APPROVED_BY_AUTHOR/' || v_author,
    (SELECT status || '/' || id_approver_user FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('an accepted report is resolved', 'RESOLVED',
    (SELECT current_status FROM road_incident WHERE id_incident = v_decided));
  v_report := v_report || pg_temp.chk('an accepted neighbor earns 50 XP', '50', pg_temp.xp(v_voter2));

  -- 6. A proposal forgotten for 8 days expires when somebody proposes again.
  PERFORM pg_temp.as_user(v_neighbor);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_old, v_neighbor, 'https://example.com/old.jpg', 'Hace mucho.')
  RETURNING id_resolution INTO v_res;
  PERFORM pg_temp.as_user(NULL);
  UPDATE incident_resolution SET proposed_at = now() - interval '8 days' WHERE id_resolution = v_res;
  PERFORM pg_temp.as_user(v_voter1);
  BEGIN
    INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter1, v_res);
    v_report := v_report || pg_temp.chk('an expired proposal takes no votes', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('an expired proposal takes no votes',
      'Esta propuesta ya no está en verificación.', SQLERRM);
  END;
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_old, v_voter1, 'https://example.com/new.jpg', 'Recién arreglado.')
  RETURNING id_resolution INTO v_res2;
  v_report := v_report || pg_temp.chk('the forgotten proposal is marked expired', 'EXPIRED',
    (SELECT status FROM incident_resolution WHERE id_resolution = v_res));
  v_report := v_report || pg_temp.chk('the new proposal takes its place', 'PENDING',
    (SELECT status FROM incident_resolution WHERE id_resolution = v_res2));
  v_report := v_report || pg_temp.chk('the report stays under review', 'UNDER_REVIEW',
    (SELECT current_status FROM road_incident WHERE id_incident = v_old));

  -- 7. The 10th endorsement during the review validates without leaving it.
  PERFORM pg_temp.as_user(NULL);
  INSERT INTO user_profile (id_user, id_rank, full_name, email, reference_city, last_city)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, 1,
         'Smoke Voter ' || g, 'smoke' || g || '@vigia.test', 'Cali', 'Cali'
    FROM generate_series(10, 19) AS g;
  INSERT INTO incident_upvote (id_user, id_incident)
  SELECT ('00000000-0000-0000-0000-' || lpad(g::text, 12, '0'))::uuid, v_old FROM generate_series(10, 19) AS g;
  v_report := v_report || pg_temp.chk('the 10th vote validates but keeps the review', 'UNDER_REVIEW/true',
    (SELECT current_status || '/' || (validated_at IS NOT NULL) FROM road_incident WHERE id_incident = v_old));

  -- 8. Deleting a report takes back the 50 XP of an accepted neighbor.
  UPDATE user_profile SET experience_points = 50 WHERE id_user = v_neighbor;
  DELETE FROM road_incident WHERE id_incident = v_quorum;
  v_report := v_report || pg_temp.chk('deleting the report takes the 50 XP back', '0', pg_temp.xp(v_neighbor));

  -- 9. Row level security, as the app sees it.
  SET LOCAL ROLE authenticated;
  PERFORM pg_temp.as_user(v_voter1);
  BEGIN
    INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter2, v_res2);
    v_report := v_report || pg_temp.chk('nobody votes in someone else''s name', 'error', 'no error');
  EXCEPTION WHEN OTHERS THEN
    v_report := v_report || pg_temp.chk('nobody votes in someone else''s name', 'error', 'error');
  END;

  PERFORM pg_temp.as_user(v_neighbor);
  INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description)
  VALUES (v_rls, v_neighbor, 'https://example.com/rls.jpg', 'Con RLS.')
  RETURNING id_resolution INTO v_res;
  v_report := v_report || pg_temp.chk('a citizen proposes through RLS', 'PENDING',
    (SELECT status FROM incident_resolution WHERE id_resolution = v_res));

  UPDATE incident_resolution SET status = 'APPROVED_BY_AUTHOR' WHERE id_resolution = v_res;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  v_report := v_report || pg_temp.chk('a non-author updates no proposal', '0', v_rows::text);

  PERFORM pg_temp.as_user(v_voter2);
  INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (v_voter2, v_res);
  v_report := v_report || pg_temp.chk('a neighbor confirms through RLS', '1',
    (SELECT confirmation_votes::text FROM incident_resolution WHERE id_resolution = v_res));

  PERFORM pg_temp.as_user(v_author);
  UPDATE incident_resolution SET status = 'APPROVED_BY_AUTHOR' WHERE id_resolution = v_res;
  GET DIAGNOSTICS v_rows = ROW_COUNT;
  v_report := v_report || pg_temp.chk('the author accepts through RLS', '1', v_rows::text);
  RESET ROLE;

  RAISE EXCEPTION 'SMOKE TEST REPORT:%', chr(10) || v_report || 'Everything above was rolled back on purpose.';
END
$$;
