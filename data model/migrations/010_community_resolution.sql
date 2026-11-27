-- =============================================================================
-- Migration: 010_community_resolution.sql
-- Description: Server-side rules for the community resolution of a report
--              (HU-25, RN-11):
--              * any signed-in citizen proposes that the damage was repaired,
--                with 1 photo and a description; only one PENDING proposal per
--                report (idx_single_active_resolution);
--              * the report author's own proposal closes the report at once
--                (APPROVED_BY_AUTHOR, no XP: nobody rewards themselves);
--              * a neighbor's proposal puts the report UNDER_REVIEW and notifies
--                the author, who may accept it or reject it with a reason;
--              * 3 confirmations -> APPROVED_BY_COMMUNITY, report RESOLVED and
--                +50 XP to the proponent (RN-08);
--              * 3 objections -> REJECTED_BY_COMMUNITY, the report goes back to
--                its previous status and the slot is free again;
--              * a PENDING proposal older than 7 days is EXPIRED. There is no
--                cron: it is marked when somebody proposes again, and votes or
--                decisions on it are refused;
--              * RLS on the three resolution tables.
--              It also adjusts two functions of earlier migrations:
--              * on_incident_upvote_inserted (004): the 10th endorsement no
--                longer overwrites UNDER_REVIEW (validated_at and +500 XP stay);
--              * take_back_incident_xp (007): deleting a report also takes back
--                the +50 XP of an accepted neighbor's resolution.
-- Requires: migrations 004, 006 and 007.
-- Idempotent: safe to run more than once.
-- Run it, then run `data model/tests/010_community_resolution_smoke_test.sql`.
--
-- "Direct" means the citizen's own request (pg_trigger_depth() = 1); changes
-- the triggers make by themselves run deeper and are not blocked, and neither
-- is the SQL Editor (no signed-in user), which keeps its freedom for seeds.
-- =============================================================================

-- 1. Is a PENDING proposal still inside its 7 days?
CREATE OR REPLACE FUNCTION public.is_resolution_open(p_resolution UUID)
RETURNS BOOLEAN
LANGUAGE sql
STABLE
SECURITY DEFINER
SET search_path = public
AS $$
  SELECT EXISTS (
    SELECT 1 FROM incident_resolution
     WHERE id_resolution = p_resolution
       AND status = 'PENDING'
       AND now() - proposed_at <= interval '7 days'
  );
$$;

-- 2. Before a proposal is created: it starts clean, there is room for it and
--    the report can still be resolved.
CREATE OR REPLACE FUNCTION public.guard_resolution_insert()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_status TEXT;
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    NEW.id_proponent_user := auth.uid();
    NEW.status := 'PENDING';
    NEW.confirmation_votes := 0;
    NEW.objection_votes := 0;
    NEW.proposed_at := now();
    NEW.resolved_at := NULL;
    NEW.id_approver_user := NULL;
    NEW.rejection_reason := NULL;
  END IF;

  IF NEW.status <> 'PENDING' THEN
    RETURN NEW;
  END IF;

  IF NULLIF(btrim(NEW.photo_evidence_url), '') IS NULL THEN
    RAISE EXCEPTION 'La propuesta necesita una foto de la reparación.';
  END IF;
  IF NULLIF(btrim(NEW.description), '') IS NULL THEN
    RAISE EXCEPTION 'Describe cómo quedó la vía.';
  END IF;
  IF char_length(NEW.description) > 500 THEN
    RAISE EXCEPTION 'La descripción no puede superar los 500 caracteres.';
  END IF;

  SELECT current_status INTO v_status FROM road_incident WHERE id_incident = NEW.id_incident FOR UPDATE;
  IF v_status IS NULL THEN
    RAISE EXCEPTION 'El reporte no existe o fue retirado.';
  END IF;
  IF v_status = 'RESOLVED' THEN
    RAISE EXCEPTION 'Este reporte ya está resuelto.';
  END IF;

  -- Lazy expiration: a forgotten proposal frees the slot here.
  UPDATE incident_resolution
     SET status = 'EXPIRED', resolved_at = now()
   WHERE id_incident = NEW.id_incident
     AND status = 'PENDING'
     AND now() - proposed_at > interval '7 days';

  IF EXISTS (SELECT 1 FROM incident_resolution
              WHERE id_incident = NEW.id_incident AND status = 'PENDING') THEN
    RAISE EXCEPTION 'Ya hay una propuesta de reparación en verificación para este reporte.';
  END IF;

  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_resolution_insert_guard ON public.incident_resolution;
CREATE TRIGGER trg_incident_resolution_insert_guard
  BEFORE INSERT ON public.incident_resolution
  FOR EACH ROW EXECUTE FUNCTION public.guard_resolution_insert();

-- 3. After a proposal is created: the author's own closes the report; a
--    neighbor's one puts it under review and tells the author.
CREATE OR REPLACE FUNCTION public.on_resolution_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident road_incident%ROWTYPE;
BEGIN
  IF NEW.status <> 'PENDING' THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_incident FROM road_incident WHERE id_incident = NEW.id_incident;

  IF NEW.id_proponent_user = v_incident.id_reporter_user THEN
    UPDATE incident_resolution
       SET status = 'APPROVED_BY_AUTHOR', id_approver_user = NEW.id_proponent_user, resolved_at = now()
     WHERE id_resolution = NEW.id_resolution;
    RETURN NULL;
  END IF;

  UPDATE road_incident
     SET current_status = 'UNDER_REVIEW', updated_at = now()
   WHERE id_incident = NEW.id_incident AND current_status IN ('REPORTED', 'COMMUNITY_VALIDATED');

  INSERT INTO notification (id_user, id_incident, type, title, message)
  VALUES (v_incident.id_reporter_user, v_incident.id_incident, 'RESOLUTION_PROPOSAL',
          'Propuesta de reparación',
          'Un ciudadano envió una foto de la reparación de tu reporte '
            || v_incident.tracking_code || '. Revísala para aceptarla o rechazarla.');

  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_resolution_inserted ON public.incident_resolution;
CREATE TRIGGER trg_incident_resolution_inserted
  AFTER INSERT ON public.incident_resolution
  FOR EACH ROW EXECUTE FUNCTION public.on_resolution_inserted();

-- 4. Before a citizen changes a proposal: only the report author decides, only
--    on an open proposal, and only accept or reject (with a reason).
CREATE OR REPLACE FUNCTION public.guard_resolution_update()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_reporter UUID;
BEGIN
  IF auth.uid() IS NOT NULL AND pg_trigger_depth() = 1 THEN
    SELECT id_reporter_user INTO v_reporter FROM road_incident WHERE id_incident = OLD.id_incident;

    IF v_reporter IS DISTINCT FROM auth.uid() THEN
      RAISE EXCEPTION 'Solo quien publicó el reporte puede aceptar o rechazar la propuesta.';
    END IF;
    IF NOT public.is_resolution_open(OLD.id_resolution) THEN
      RAISE EXCEPTION 'Esta propuesta ya no está en verificación.';
    END IF;
    IF NEW.id_resolution IS DISTINCT FROM OLD.id_resolution
       OR NEW.id_incident IS DISTINCT FROM OLD.id_incident
       OR NEW.id_proponent_user IS DISTINCT FROM OLD.id_proponent_user
       OR NEW.photo_evidence_url IS DISTINCT FROM OLD.photo_evidence_url
       OR NEW.description IS DISTINCT FROM OLD.description
       OR NEW.confirmation_votes IS DISTINCT FROM OLD.confirmation_votes
       OR NEW.objection_votes IS DISTINCT FROM OLD.objection_votes
       OR NEW.proposed_at IS DISTINCT FROM OLD.proposed_at THEN
      RAISE EXCEPTION 'Ese dato de la propuesta no se puede cambiar.';
    END IF;
    IF NEW.status NOT IN ('APPROVED_BY_AUTHOR', 'REJECTED_BY_AUTHOR') THEN
      RAISE EXCEPTION 'Solo puedes aceptar o rechazar la propuesta.';
    END IF;

    IF NEW.status = 'REJECTED_BY_AUTHOR' THEN
      IF NULLIF(btrim(NEW.rejection_reason), '') IS NULL THEN
        RAISE EXCEPTION 'Escribe por qué rechazas la propuesta.';
      END IF;
    ELSE
      NEW.rejection_reason := NULL;
    END IF;

    NEW.id_approver_user := auth.uid();
    NEW.resolved_at := now();
  END IF;
  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_resolution_update_guard ON public.incident_resolution;
CREATE TRIGGER trg_incident_resolution_update_guard
  BEFORE UPDATE ON public.incident_resolution
  FOR EACH ROW EXECUTE FUNCTION public.guard_resolution_update();

-- 5. After a proposal leaves PENDING: the one place that applies the outcome.
CREATE OR REPLACE FUNCTION public.on_resolution_status_changed()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident road_incident%ROWTYPE;
BEGIN
  IF OLD.status <> 'PENDING' OR NEW.status = 'PENDING' THEN
    RETURN NULL;
  END IF;

  SELECT * INTO v_incident FROM road_incident WHERE id_incident = NEW.id_incident FOR UPDATE;

  IF NEW.status IN ('APPROVED_BY_AUTHOR', 'APPROVED_BY_COMMUNITY') THEN
    UPDATE road_incident
       SET current_status = 'RESOLVED', resolved_at = now(), updated_at = now(),
           id_resolver_user = NEW.id_proponent_user
     WHERE id_incident = NEW.id_incident;

    IF NEW.id_proponent_user <> v_incident.id_reporter_user THEN
      PERFORM add_xp(NEW.id_proponent_user, 50);
    END IF;

    -- The author, the followers and the proponent; never who just decided.
    INSERT INTO notification (id_user, id_incident, type, title, message)
    SELECT recipient.id_user, NEW.id_incident, 'REPORT_RESOLVED',
           '¡Reporte resuelto!',
           'El reporte ' || v_incident.tracking_code || ' en ' || v_incident.neighborhood
             || ' fue verificado como reparado.'
      FROM (
        SELECT v_incident.id_reporter_user AS id_user
        UNION
        SELECT NEW.id_proponent_user
        UNION
        SELECT id_user FROM incident_follow WHERE id_incident = NEW.id_incident
      ) AS recipient
     WHERE recipient.id_user IS DISTINCT FROM NEW.id_approver_user;
  ELSE
    UPDATE road_incident
       SET current_status = CASE WHEN validated_at IS NOT NULL THEN 'COMMUNITY_VALIDATED' ELSE 'REPORTED' END,
           updated_at = now()
     WHERE id_incident = NEW.id_incident AND current_status = 'UNDER_REVIEW';
  END IF;

  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_incident_resolution_status_changed ON public.incident_resolution;
CREATE TRIGGER trg_incident_resolution_status_changed
  AFTER UPDATE OF status ON public.incident_resolution
  FOR EACH ROW EXECUTE FUNCTION public.on_resolution_status_changed();

-- 6. Before a confirmation or an objection: an open proposal, a neighbor who is
--    neither the proponent nor the author, and one kind of vote per person.
CREATE OR REPLACE FUNCTION public.guard_resolution_vote()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_resolution incident_resolution%ROWTYPE;
  v_reporter UUID;
BEGIN
  SELECT * INTO v_resolution FROM incident_resolution WHERE id_resolution = NEW.id_resolution;
  IF v_resolution.id_resolution IS NULL THEN
    RAISE EXCEPTION 'La propuesta no existe.';
  END IF;
  IF NOT public.is_resolution_open(NEW.id_resolution) THEN
    RAISE EXCEPTION 'Esta propuesta ya no está en verificación.';
  END IF;
  IF v_resolution.id_proponent_user = NEW.id_user THEN
    RAISE EXCEPTION 'No puedes votar tu propia propuesta.';
  END IF;

  SELECT id_reporter_user INTO v_reporter FROM road_incident WHERE id_incident = v_resolution.id_incident;
  IF v_reporter = NEW.id_user THEN
    RAISE EXCEPTION 'Como autor del reporte, acepta o rechaza la propuesta.';
  END IF;

  IF (TG_TABLE_NAME = 'resolution_confirmation' AND EXISTS (
        SELECT 1 FROM resolution_objection WHERE id_resolution = NEW.id_resolution AND id_user = NEW.id_user))
     OR (TG_TABLE_NAME = 'resolution_objection' AND EXISTS (
        SELECT 1 FROM resolution_confirmation WHERE id_resolution = NEW.id_resolution AND id_user = NEW.id_user)) THEN
    RAISE EXCEPTION 'Ya votaste esta propuesta.';
  END IF;

  RETURN NEW;
END
$$;

DROP TRIGGER IF EXISTS trg_resolution_confirmation_guard ON public.resolution_confirmation;
CREATE TRIGGER trg_resolution_confirmation_guard
  BEFORE INSERT ON public.resolution_confirmation
  FOR EACH ROW EXECUTE FUNCTION public.guard_resolution_vote();

DROP TRIGGER IF EXISTS trg_resolution_objection_guard ON public.resolution_objection;
CREATE TRIGGER trg_resolution_objection_guard
  BEFORE INSERT ON public.resolution_objection
  FOR EACH ROW EXECUTE FUNCTION public.guard_resolution_vote();

-- 7. After a vote: count it and, at 3, decide. The row lock serializes
--    concurrent votes so the outcome is applied once.
CREATE OR REPLACE FUNCTION public.on_resolution_vote_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_votes INT;
BEGIN
  PERFORM 1 FROM incident_resolution WHERE id_resolution = NEW.id_resolution FOR UPDATE;

  IF TG_TABLE_NAME = 'resolution_confirmation' THEN
    SELECT count(*)::int INTO v_votes FROM resolution_confirmation WHERE id_resolution = NEW.id_resolution;
    UPDATE incident_resolution
       SET confirmation_votes = v_votes,
           status = CASE WHEN v_votes >= 3 THEN 'APPROVED_BY_COMMUNITY' ELSE status END,
           resolved_at = CASE WHEN v_votes >= 3 THEN now() ELSE resolved_at END
     WHERE id_resolution = NEW.id_resolution;
  ELSE
    SELECT count(*)::int INTO v_votes FROM resolution_objection WHERE id_resolution = NEW.id_resolution;
    UPDATE incident_resolution
       SET objection_votes = v_votes,
           status = CASE WHEN v_votes >= 3 THEN 'REJECTED_BY_COMMUNITY' ELSE status END,
           resolved_at = CASE WHEN v_votes >= 3 THEN now() ELSE resolved_at END
     WHERE id_resolution = NEW.id_resolution;
  END IF;

  RETURN NULL;
END
$$;

DROP TRIGGER IF EXISTS trg_resolution_confirmation_inserted ON public.resolution_confirmation;
CREATE TRIGGER trg_resolution_confirmation_inserted
  AFTER INSERT ON public.resolution_confirmation
  FOR EACH ROW EXECUTE FUNCTION public.on_resolution_vote_inserted();

DROP TRIGGER IF EXISTS trg_resolution_objection_inserted ON public.resolution_objection;
CREATE TRIGGER trg_resolution_objection_inserted
  AFTER INSERT ON public.resolution_objection
  FOR EACH ROW EXECUTE FUNCTION public.on_resolution_vote_inserted();

-- 8. Migration 004, adjusted: the 10th endorsement validates the report but
--    does not take it out of UNDER_REVIEW; step 5 restores COMMUNITY_VALIDATED
--    from validated_at if the proposal fails.
CREATE OR REPLACE FUNCTION public.on_incident_upvote_inserted()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  v_incident road_incident%ROWTYPE;
  v_votes INT;
BEGIN
  SELECT * INTO v_incident FROM road_incident WHERE id_incident = NEW.id_incident FOR UPDATE;

  PERFORM add_xp(NEW.id_user, 10);
  PERFORM add_xp(v_incident.id_reporter_user, 10);

  INSERT INTO notification (id_user, id_incident, type, title, message)
  VALUES (v_incident.id_reporter_user, v_incident.id_incident, 'NEW_UPVOTE',
          'Nuevo apoyo',
          'Un ciudadano apoyó tu reporte ' || v_incident.tracking_code || '.');

  SELECT count(*) INTO v_votes FROM incident_upvote WHERE id_incident = NEW.id_incident;

  IF v_votes >= 10 AND v_incident.validated_at IS NULL THEN
    UPDATE road_incident
       SET validated_at = now(),
           updated_at = now(),
           current_status = CASE WHEN current_status = 'REPORTED'
                                 THEN 'COMMUNITY_VALIDATED' ELSE current_status END
     WHERE id_incident = v_incident.id_incident;

    PERFORM add_xp(v_incident.id_reporter_user, 500);

    INSERT INTO notification (id_user, id_incident, type, title, message)
    VALUES (v_incident.id_reporter_user, v_incident.id_incident, 'COMMUNITY_VALIDATION',
            '¡Reporte validado por la comunidad!',
            'Tu reporte ' || v_incident.tracking_code || ' alcanzó 10 apoyos (+500 XP).');
  END IF;

  RETURN NULL;
END
$$;

-- 9. Migration 007, adjusted: deleting a report also takes back the +50 XP of
--    an accepted neighbor's resolution, before the cascade removes it.
CREATE OR REPLACE FUNCTION public.take_back_incident_xp()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
  r RECORD;
  v_votes INT;
BEGIN
  FOR r IN
    SELECT id_user, count(*)::int AS n FROM incident_comment
     WHERE id_incident = OLD.id_incident GROUP BY id_user
  LOOP
    PERFORM add_xp(r.id_user, -15 * r.n);
  END LOOP;

  FOR r IN
    SELECT id_user FROM incident_upvote WHERE id_incident = OLD.id_incident
  LOOP
    PERFORM add_xp(r.id_user, -10);
  END LOOP;

  SELECT count(*)::int INTO v_votes FROM incident_upvote WHERE id_incident = OLD.id_incident;
  IF v_votes > 0 THEN
    PERFORM add_xp(OLD.id_reporter_user, -10 * v_votes);
  END IF;

  -- Only moderation can delete a validated report; the 500 XP goes back too.
  IF OLD.validated_at IS NOT NULL THEN
    PERFORM add_xp(OLD.id_reporter_user, -500);
  END IF;

  FOR r IN
    SELECT id_proponent_user FROM incident_resolution
     WHERE id_incident = OLD.id_incident
       AND status IN ('APPROVED_BY_AUTHOR', 'APPROVED_BY_COMMUNITY')
       AND id_proponent_user <> OLD.id_reporter_user
  LOOP
    PERFORM add_xp(r.id_proponent_user, -50);
  END LOOP;

  RETURN OLD;
END
$$;

REVOKE ALL ON FUNCTION public.is_resolution_open(UUID) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_resolution_insert() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_resolution_inserted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_resolution_update() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_resolution_status_changed() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.guard_resolution_vote() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_resolution_vote_inserted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.on_incident_upvote_inserted() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.take_back_incident_xp() FROM PUBLIC, anon, authenticated;

-- 10. Policies. Anyone (guests too) reads; the triggers above hold the rules,
--     the policies say whose rows. Votes are final: there is no DELETE policy.
GRANT SELECT ON public.incident_resolution, public.resolution_confirmation, public.resolution_objection
  TO anon, authenticated;
GRANT INSERT ON public.incident_resolution, public.resolution_confirmation, public.resolution_objection
  TO authenticated;
GRANT UPDATE ON public.incident_resolution TO authenticated;

ALTER TABLE public.incident_resolution ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on incident_resolution" ON public.incident_resolution;
CREATE POLICY "Public read access on incident_resolution"
  ON public.incident_resolution FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Citizens can propose a resolution" ON public.incident_resolution;
CREATE POLICY "Citizens can propose a resolution"
  ON public.incident_resolution FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id_proponent_user);

DROP POLICY IF EXISTS "Report authors can decide on a resolution" ON public.incident_resolution;
CREATE POLICY "Report authors can decide on a resolution"
  ON public.incident_resolution FOR UPDATE TO authenticated
  USING (EXISTS (
    SELECT 1 FROM public.road_incident i
     WHERE i.id_incident = incident_resolution.id_incident AND i.id_reporter_user = auth.uid()
  ));

ALTER TABLE public.resolution_confirmation ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on resolution_confirmation" ON public.resolution_confirmation;
CREATE POLICY "Public read access on resolution_confirmation"
  ON public.resolution_confirmation FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Citizens can confirm a resolution" ON public.resolution_confirmation;
CREATE POLICY "Citizens can confirm a resolution"
  ON public.resolution_confirmation FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id_user);

ALTER TABLE public.resolution_objection ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS "Public read access on resolution_objection" ON public.resolution_objection;
CREATE POLICY "Public read access on resolution_objection"
  ON public.resolution_objection FOR SELECT TO anon, authenticated USING (true);

DROP POLICY IF EXISTS "Citizens can object to a resolution" ON public.resolution_objection;
CREATE POLICY "Citizens can object to a resolution"
  ON public.resolution_objection FOR INSERT TO authenticated
  WITH CHECK (auth.uid() = id_user);
