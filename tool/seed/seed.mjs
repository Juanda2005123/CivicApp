// Demo data for the VIGÍA presentation (Node 20+, no dependencies).
//
// Every step is a separate command, so nothing is written to Supabase without
// asking for it by name:
//
//   node tool/seed/seed.mjs plan             what the seed contains; touches nothing
//   node tool/seed/seed.mjs users            signs the demo users up (or in) like the app does
//   node tool/seed/seed.mjs photos:download  downloads the Wikimedia photos to tool/seed/out/photos
//   node tool/seed/seed.mjs photos:upload    uploads them to the incident-evidence bucket (seed/ folder)
//   node tool/seed/seed.mjs sql              writes "data model/demo_data.sql" (does not run it)
//
// Then run the SQL with the Supabase CLI (an organization member, no database password):
//   supabase db query --linked --project-ref <ref> -f "$(pwd)/data model/demo_data.sql"
//
// It reads SUPABASE_URL, SUPABASE_ANON_KEY and SEED_DEMO_PASSWORD from .env. The
// demo users are real accounts (so they can sign in during the demo); their
// ids and the photo URLs are kept in tool/seed/out/state.json (git-ignored).
// The SQL only deletes reports whose tracking code starts with the seed prefix,
// so running it again replaces the demo data and never touches anyone else's.

import { spawnSync } from 'node:child_process';
import { existsSync, mkdirSync, readFileSync, writeFileSync } from 'node:fs';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
const root = join(here, '..', '..');
const outDir = join(here, 'out');
const photosDir = join(outDir, 'photos');
const statePath = join(outDir, 'state.json');
const sqlPath = join(root, 'data model', 'demo_data.sql');
const bucket = 'incident-evidence';
const userAgent = 'VIGIA-student-demo-seed/1.0';

const data = JSON.parse(readFileSync(join(here, 'seed_data.json'), 'utf8'));
const usersByKey = Object.fromEntries(data.users.map((u) => [u.key, u]));

// ---------------------------------------------------------------- helpers

function readEnv() {
  const env = { ...process.env };
  const file = join(root, '.env');
  if (existsSync(file)) {
    for (const line of readFileSync(file, 'utf8').split('\n')) {
      const match = line.match(/^\s*([A-Z_]+)\s*=\s*(.*)\s*$/);
      if (match && env[match[1]] === undefined) env[match[1]] = match[2].replace(/^["']|["']$/g, '');
    }
  }
  return env;
}

function requireEnv(env, ...keys) {
  const missing = keys.filter((k) => !env[k]);
  if (missing.length) {
    throw new Error(`Falta ${missing.join(', ')} en .env (SEED_DEMO_PASSWORD es la contraseña común de los usuarios demo).`);
  }
}

function loadState() {
  return existsSync(statePath) ? JSON.parse(readFileSync(statePath, 'utf8')) : { users: {}, photos: {} };
}

function saveState(state) {
  mkdirSync(outDir, { recursive: true });
  writeFileSync(statePath, JSON.stringify(state, null, 2));
}

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

function emailOf(user) {
  const local = user.key.normalize('NFD').replace(/[̀-ͯ]/g, '');
  return `${local}.demo@${data.emailDomain}`;
}

const trackingCode = (code) => `${data.trackingPrefix}${code}`;

/// Checks the rules the database will check, so a bad seed fails here and not halfway.
function validate() {
  const errors = [];
  const reports = new Map(data.reports.map((r) => [r.code, r]));
  const others = (author) => data.users.filter((u) => u.key !== author).length;
  for (const r of data.reports) {
    if (!usersByKey[r.author]) errors.push(`${r.code}: autor desconocido ${r.author}`);
    for (const p of r.photos) if (!data.photos[p]) errors.push(`${r.code}: foto desconocida ${p}`);
    if (r.photos.length > 3) errors.push(`${r.code}: más de 3 fotos`);
    if (r.upvotes > others(r.author)) errors.push(`${r.code}: más apoyos que vecinos`);
  }
  for (const c of data.comments) {
    if (!reports.has(c.report)) errors.push(`comentario en reporte desconocido ${c.report}`);
    if (!usersByKey[c.user]) errors.push(`comentario de usuario desconocido ${c.user}`);
    if (c.photo && !data.photos[c.photo]) errors.push(`comentario con foto desconocida ${c.photo}`);
    if (c.text.length > 500) errors.push(`comentario de más de 500 caracteres en ${c.report}`);
  }
  for (const res of data.resolutions) {
    const report = reports.get(res.report);
    if (!report) { errors.push(`propuesta en reporte desconocido ${res.report}`); continue; }
    if (!data.photos[res.photo]) errors.push(`propuesta ${res.report}: foto desconocida ${res.photo}`);
    if (res.proponent === report.author) errors.push(`propuesta ${res.report}: el autor no se propone a sí mismo en la seed`);
    for (const v of [...(res.confirmations ?? []), ...(res.objections ?? [])]) {
      if (v === report.author || v === res.proponent) errors.push(`propuesta ${res.report}: ${v} no puede votar`);
    }
    if (res.hoursAgo >= 7 * 24) errors.push(`propuesta ${res.report}: vencería (más de 7 días)`);
  }
  if (errors.length) throw new Error(`La seed tiene errores:\n- ${errors.join('\n- ')}`);
}

// ---------------------------------------------------------------- plan

function plan() {
  validate();
  const byCity = {};
  for (const r of data.reports) byCity[r.city] = (byCity[r.city] ?? 0) + 1;
  const validated = data.reports.filter((r) => r.upvotes >= 10).map((r) => trackingCode(r.code));
  const commentPhotos = data.comments.filter((c) => c.photo).length;

  console.log('Seed de demostración — no toca nada, solo describe.\n');
  console.log(`Usuarios (${data.users.length}), correo <nombre>.demo@${data.emailDomain}, contraseña SEED_DEMO_PASSWORD:`);
  for (const u of data.users) console.log(`  ${emailOf(u).padEnd(32)} ${u.name.padEnd(20)} ${u.city}${u.hideName ? '  (nombre oculto)' : ''}`);
  console.log(`\nReportes (${data.reports.length}): ${Object.entries(byCity).map(([c, n]) => `${c} ${n}`).join(', ')}`);
  console.log(`  códigos ${trackingCode(data.reports[0].code)} a ${trackingCode(data.reports.at(-1).code)}`);
  console.log(`  validados (10+ apoyos): ${validated.join(', ')}`);
  console.log(`Fotos distintas: ${Object.keys(data.photos).length} (Wikimedia Commons)`);
  console.log(`Comentarios: ${data.comments.length} (${commentPhotos} con foto)`);
  console.log(`Propuestas de reparación: ${data.resolutions.length}`);
  for (const r of data.resolutions) console.log(`  ${trackingCode(r.report)}  ${r.outcome}`);
  console.log('\nPasos, en orden: users → photos:download → photos:upload → sql → supabase db query.');
}

// ---------------------------------------------------------------- users

async function authRequest(env, path, body) {
  const response = await fetch(`${env.SUPABASE_URL}/auth/v1/${path}`, {
    method: 'POST',
    headers: { apikey: env.SUPABASE_ANON_KEY, 'Content-Type': 'application/json' },
    body: JSON.stringify(body),
  });
  return { ok: response.ok, json: await response.json().catch(() => ({})) };
}

async function signIn(env, email) {
  const res = await authRequest(env, 'token?grant_type=password', { email, password: env.SEED_DEMO_PASSWORD });
  if (!res.ok) throw new Error(`No pudimos iniciar sesión con ${email}: ${res.json.msg ?? res.json.error_description ?? JSON.stringify(res.json)}`);
  return { id: res.json.user.id, token: res.json.access_token };
}

/// Signs a demo user up, or in when the account already exists (re-runs).
async function session(env, user) {
  const email = emailOf(user);
  const up = await authRequest(env, 'signup', { email, password: env.SEED_DEMO_PASSWORD });
  if (up.ok && up.json.access_token) return { id: up.json.user.id, token: up.json.access_token, created: true };
  const text = JSON.stringify(up.json).toLowerCase();
  if (up.ok || text.includes('already') || text.includes('registered')) return { ...(await signIn(env, email)), created: false };
  throw new Error(`No pudimos registrar ${email}: ${up.json.msg ?? JSON.stringify(up.json)}`);
}

async function rest(env, token, path, options = {}) {
  return fetch(`${env.SUPABASE_URL}/rest/v1/${path}`, {
    ...options,
    headers: {
      apikey: env.SUPABASE_ANON_KEY,
      Authorization: `Bearer ${token}`,
      'Content-Type': 'application/json',
      ...(options.headers ?? {}),
    },
  });
}

/// The profile row, written as the app writes it right after signing up.
async function ensureProfile(env, user, auth) {
  const existing = await rest(env, auth.token, `user_profile?id_user=eq.${auth.id}&select=id_user`);
  if ((await existing.json()).length) return false;
  const response = await rest(env, auth.token, 'user_profile', {
    method: 'POST',
    body: JSON.stringify({
      id_user: auth.id,
      id_rank: 1,
      full_name: user.name,
      email: emailOf(user),
      reference_city: user.city,
      last_city: user.city,
      experience_points: 0,
      show_real_name: !user.hideName,
      is_active: true,
    }),
  });
  if (!response.ok) throw new Error(`No pudimos crear el perfil de ${user.name}: ${await response.text()}`);
  return true;
}

async function users() {
  validate();
  const env = readEnv();
  requireEnv(env, 'SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SEED_DEMO_PASSWORD');
  const state = loadState();
  for (const user of data.users) {
    const auth = await session(env, user);
    const createdProfile = await ensureProfile(env, user, auth);
    state.users[user.key] = { id: auth.id, email: emailOf(user) };
    saveState(state);
    console.log(`${auth.created ? 'creado   ' : 'ya existía'}  ${emailOf(user).padEnd(32)} ${createdProfile ? 'perfil creado' : 'perfil ya existía'}`);
    await sleep(400);
  }
  console.log(`\n${data.users.length} usuarios listos. Ids guardados en tool/seed/out/state.json.`);
}

// ---------------------------------------------------------------- photos

/// Wikimedia answers 429 when asked too fast: wait and try again.
async function politeFetch(url) {
  for (let attempt = 1; ; attempt++) {
    const response = await fetch(url, { headers: { 'User-Agent': userAgent } });
    if (response.status !== 429 || attempt === 6) return response;
    const wait = Math.min(Number(response.headers.get('retry-after')) * 1000 || attempt * 10000, 30000);
    console.log(`          Wikimedia pide esperar; reintento en ${Math.round(wait / 1000)} s`);
    await sleep(wait);
  }
}

async function commons(params) {
  const url = `https://commons.wikimedia.org/w/api.php?format=json&${new URLSearchParams(params)}`;
  const response = await politeFetch(url);
  if (!response.ok) throw new Error(`Wikimedia respondió ${response.status}`);
  return response.json();
}

const stripHtml = (value) => (value ?? '').replace(/<[^>]*>/g, '').replace(/\s+/g, ' ').trim();

/// The image info of a Commons file (a 1280 px thumbnail, author and license).
async function fileInfo(title) {
  const json = await commons({
    action: 'query', prop: 'imageinfo', titles: `File:${title}`,
    iiprop: 'url|mime|extmetadata', iiurlwidth: '1280',
  });
  const page = Object.values(json.query?.pages ?? {})[0];
  const info = page?.imageinfo?.[0];
  if (!info) return null;
  const meta = info.extmetadata ?? {};
  return {
    title,
    original: info.url,
    thumb: info.thumburl ?? info.url,
    page: info.descriptionurl,
    mime: info.mime,
    author: stripHtml(meta.Artist?.value) || 'Desconocido',
    license: stripHtml(meta.LicenseShortName?.value) || '?',
  };
}

/// The first JPEG with a free license among the Commons results of a search.
async function searchInfo(query) {
  const json = await commons({ action: 'query', list: 'search', srnamespace: '6', srlimit: '15', srsearch: query });
  for (const hit of json.query?.search ?? []) {
    await sleep(300);
    const info = await fileInfo(hit.title.replace(/^File:/, ''));
    if (info && info.mime === 'image/jpeg' && /^(CC|Public domain|PD)/i.test(info.license)) return info;
  }
  return null;
}

async function photosDownload() {
  validate();
  mkdirSync(photosDir, { recursive: true });
  const state = loadState();
  for (const [key, source] of Object.entries(data.photos)) {
    const file = join(photosDir, `${key}.jpg`);
    if (existsSync(file) && state.photos[key]?.title) { console.log(`ya está   ${key}`); continue; }
    const info = source.commons ? await fileInfo(source.commons) : await searchInfo(source.search);
    if (!info) { console.log(`NO HALLADA ${key} (${source.commons ?? source.search})`); continue; }
    // Thumbnails are rate limited hard; the original file is not, and ImageMagick
    // shrinks it here when it is installed.
    let image = await politeFetch(info.thumb);
    if (!image.ok) image = await politeFetch(info.original);
    if (!image.ok) { console.log(`FALLÓ     ${key}: ${image.status}`); continue; }
    writeFileSync(file, Buffer.from(await image.arrayBuffer()));
    shrink(file);
    state.photos[key] = { ...state.photos[key], title: info.title, page: info.page, author: info.author, license: info.license };
    saveState(state);
    console.log(`bajada    ${key.padEnd(20)} ${info.license.padEnd(14)} ${info.title}`);
    await sleep(3000);
  }
  writeCredits(state);
  console.log(`\nRevisa las fotos en tool/seed/out/photos antes de subirlas. Créditos en tool/seed/out/credits.md.`);
}

/// At most 1280 px on the long side, as a JPEG; skipped when ImageMagick is missing.
function shrink(file) {
  const result = spawnSync('magick', [file, '-auto-orient', '-resize', '1280x1280>', '-quality', '82', file]);
  if (result.error) console.log('          (sin ImageMagick: la foto queda en su tamaño original)');
}

function writeCredits(state) {
  const lines = ['# Créditos de las fotos de demostración', '', 'Fotos de Wikimedia Commons, usadas según su licencia.', '',
    '| Foto | Archivo | Autor | Licencia |', '|---|---|---|---|'];
  for (const [key, p] of Object.entries(state.photos)) {
    if (p.title && data.photos[key]) lines.push(`| ${key} | [${p.title}](${p.page}) | ${p.author} | ${p.license} |`);
  }
  writeFileSync(join(outDir, 'credits.md'), `${lines.join('\n')}\n`);
}

async function photosUpload() {
  const env = readEnv();
  requireEnv(env, 'SUPABASE_URL', 'SUPABASE_ANON_KEY', 'SEED_DEMO_PASSWORD');
  const state = loadState();
  const uploader = data.users[0];
  if (!state.users[uploader.key]) throw new Error('Primero corre el paso users.');
  const { token } = await signIn(env, emailOf(uploader));

  for (const key of Object.keys(data.photos)) {
    const file = join(photosDir, `${key}.jpg`);
    if (!existsSync(file)) { console.log(`falta     ${key} (corre photos:download)`); continue; }
    const path = `seed/${key}.jpg`;
    const response = await fetch(`${env.SUPABASE_URL}/storage/v1/object/${bucket}/${path}`, {
      method: 'POST',
      headers: { apikey: env.SUPABASE_ANON_KEY, Authorization: `Bearer ${token}`, 'Content-Type': 'image/jpeg' },
      body: readFileSync(file),
    });
    const body = await response.text();
    // The bucket has no update policy on purpose: an existing file stays as it is.
    const already = !response.ok && /duplicate|already exists/i.test(body);
    if (!response.ok && !already) { console.log(`FALLÓ     ${key}: ${response.status} ${body.slice(0, 120)} (vuelve a correr el paso)`); continue; }
    state.photos[key] = { ...state.photos[key], url: `${env.SUPABASE_URL}/storage/v1/object/public/${bucket}/${path}` };
    saveState(state);
    console.log(`${already ? 'ya estaba' : 'subida   '}  ${path}`);
  }
}

// ---------------------------------------------------------------- sql

const q = (value) => (value === null || value === undefined ? 'NULL' : `'${String(value).replace(/'/g, "''")}'`);

function sql() {
  validate();
  const state = loadState();
  const id = (key) => {
    const user = state.users[key];
    if (!user) throw new Error(`No hay id para ${key}: corre el paso users.`);
    return `${q(user.id)}::uuid`;
  };
  const url = (key) => {
    const photo = state.photos[key];
    if (!photo?.url) throw new Error(`La foto ${key} no está subida: corre photos:upload.`);
    return q(photo.url);
  };
  const incident = (code) => `(SELECT id_incident FROM road_incident WHERE tracking_code = ${q(trackingCode(code))})`;
  const pending = (code) => `(SELECT id_resolution FROM incident_resolution WHERE id_incident = ${incident(code)} AND status = 'PENDING')`;
  const voters = (report) => data.users.filter((u) => u.key !== report.author).slice(0, report.upvotes);

  const out = [];
  const add = (line = '') => out.push(line);
  add('-- =============================================================================');
  add('-- Demo data for the VIGÍA presentation. GENERATED by `node tool/seed/seed.mjs sql`');
  add('-- from tool/seed/seed_data.json: edit the JSON, not this file.');
  add('-- Run it as an administrator (SQL Editor or `supabase db query --linked`): the');
  add('-- triggers of migrations 004 to 010 still pay XP, validate reports and resolve them.');
  add(`-- It first deletes the reports whose code starts with ${data.trackingPrefix}, so it can run again.`);
  add('-- =============================================================================');
  add('BEGIN;');
  add();
  add('-- 1. Previous demo reports (their photos, comments, votes and proposals cascade;');
  add('--    migration 007 takes back the XP they produced).');
  add(`DELETE FROM road_incident WHERE tracking_code LIKE ${q(`${data.trackingPrefix}%`)};`);
  add();
  add('-- 2. Reports and their photos');
  for (const r of data.reports) {
    add(`INSERT INTO road_incident (tracking_code, id_reporter_user, id_category, title, description, severity, estimated_dimensions, latitude, longitude, formatted_address, neighborhood, city, created_at, updated_at)`);
    add(`VALUES (${q(trackingCode(r.code))}, ${id(r.author)}, ${r.category}, ${q(r.title)}, ${q(r.description)}, ${q(r.severity)}, ${q(r.dimensions ?? null)}, ${r.lat}, ${r.lng}, ${q(r.address)}, ${q(r.neighborhood)}, ${q(r.city)}, now() - interval '${r.daysAgo} days', now() - interval '${r.daysAgo} days');`);
    r.photos.forEach((p, i) => {
      add(`INSERT INTO incident_photo (id_incident, file_url, is_primary, uploaded_at) VALUES (${incident(r.code)}, ${url(p)}, ${i === 0}, now() - interval '${r.daysAgo} days');`);
    });
  }
  add();
  add('-- 3. Endorsements (the 10th one validates the report and pays +500 XP)');
  for (const r of data.reports) {
    voters(r).forEach((v, i) => {
      const hours = Math.max(1, r.daysAgo * 24 - (i + 1) * 3);
      add(`INSERT INTO incident_upvote (id_user, id_incident, upvoted_at) VALUES (${id(v.key)}, ${incident(r.code)}, now() - interval '${hours} hours');`);
    });
  }
  add();
  add('-- 4. Comments, some with a photo');
  for (const c of data.comments) {
    const insert = `INSERT INTO incident_comment (id_incident, id_user, content, created_at) VALUES (${incident(c.report)}, ${id(c.user)}, ${q(c.text)}, now() - interval '${c.hoursAgo} hours')`;
    if (c.photo) {
      add(`WITH c AS (${insert} RETURNING id_comment)`);
      add(`INSERT INTO comment_photo (id_comment, file_url, uploaded_at) SELECT id_comment, ${url(c.photo)}, now() - interval '${c.hoursAgo} hours' FROM c;`);
    } else {
      add(`${insert};`);
    }
  }
  add();
  add('-- 5. Repair proposals (HU-25). Each one is created pending and then voted or');
  add('--    decided, so the triggers of migration 010 apply the outcome.');
  for (const res of data.resolutions) {
    const report = data.reports.find((r) => r.code === res.report);
    add(`-- ${trackingCode(res.report)}: ${res.outcome}`);
    add(`INSERT INTO incident_resolution (id_incident, id_proponent_user, photo_evidence_url, description) VALUES (${incident(res.report)}, ${id(res.proponent)}, ${url(res.photo)}, ${q(res.description)});`);
    add(`UPDATE incident_resolution SET proposed_at = now() - interval '${res.hoursAgo} hours' WHERE id_resolution = ${pending(res.report)};`);
    for (const v of res.confirmations ?? []) {
      add(`INSERT INTO resolution_confirmation (id_user, id_resolution) VALUES (${id(v)}, ${pending(res.report)});`);
    }
    for (const v of res.objections ?? []) {
      add(`INSERT INTO resolution_objection (id_user, id_resolution, reason) VALUES (${id(v)}, ${pending(res.report)}, 'La foto no corresponde a este punto.');`);
    }
    if (res.outcome === 'author') {
      add(`UPDATE incident_resolution SET status = 'APPROVED_BY_AUTHOR', id_approver_user = ${id(report.author)}, resolved_at = now() WHERE id_resolution = ${pending(res.report)};`);
    }
  }
  add();
  add('COMMIT;');
  add();
  add('-- Check: one row per demo report with its status, photos, votes and comments.');
  add(`SELECT tracking_code, city, current_status,`);
  add(`       (SELECT count(*) FROM incident_photo p WHERE p.id_incident = i.id_incident) AS photos,`);
  add(`       (SELECT count(*) FROM incident_upvote u WHERE u.id_incident = i.id_incident) AS upvotes,`);
  add(`       (SELECT count(*) FROM incident_comment c WHERE c.id_incident = i.id_incident) AS comments`);
  add(`  FROM road_incident i WHERE tracking_code LIKE ${q(`${data.trackingPrefix}%`)} ORDER BY tracking_code;`);

  writeFileSync(sqlPath, `${out.join('\n')}\n`);
  console.log(`Escrito ${sqlPath} (${out.length} líneas). No se ha ejecutado.`);
  console.log('Para aplicarlo:');
  console.log(`  supabase db query --linked --project-ref <ref> -f "${sqlPath}"`);
}

// ---------------------------------------------------------------- main

const steps = { plan, users, 'photos:download': photosDownload, 'photos:upload': photosUpload, sql };
const step = process.argv[2] ?? 'plan';
if (!steps[step]) {
  console.error(`Paso desconocido: ${step}. Usa uno de: ${Object.keys(steps).join(', ')}`);
  process.exit(1);
}
try {
  await steps[step]();
} catch (error) {
  console.error(`\n${error.message}`);
  process.exit(1);
}
