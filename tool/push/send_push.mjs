// Sends one push notification through FCM HTTP v1, as the backend does (HU-24,
// lesson K4). For testing from a computer; the app never holds this key.
//
//   node tool/push/send_push.mjs <user|topic> "<title>" "<body>" [#VIG-code]
//
// <user> is a demo user key from tool/seed/seed_data.json (ana, luis, marta…)
// or a full topic (user_<uuid>). The optional report code adds the report id,
// so tapping the push opens it. The service account key is read from
// $FCM_SERVICE_ACCOUNT or ~/.config/vigia/fcm-service-account.json (lesson K2:
// never in the repo).

import { createSign } from 'node:crypto';
import { existsSync, readFileSync } from 'node:fs';
import { homedir } from 'node:os';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..');

function env() {
  const values = { ...process.env };
  const file = join(root, '.env');
  if (existsSync(file)) {
    for (const line of readFileSync(file, 'utf8').split('\n')) {
      const m = line.match(/^\s*([A-Z_]+)\s*=\s*(.*)\s*$/);
      if (m && values[m[1]] === undefined) values[m[1]] = m[2].replace(/^["']|["']$/g, '');
    }
  }
  return values;
}

function topicOf(who) {
  if (who.startsWith('user_')) return who;
  const state = join(root, 'tool', 'seed', 'out', 'state.json');
  const users = existsSync(state) ? JSON.parse(readFileSync(state, 'utf8')).users : {};
  if (!users[who]) throw new Error(`No conozco al usuario "${who}". Usa una clave de la seed (ana, luis…) o un topic user_<uuid>.`);
  return `user_${users[who].id}`;
}

async function incidentId(code) {
  const { SUPABASE_URL: url, SUPABASE_ANON_KEY: key } = env();
  const response = await fetch(`${url}/rest/v1/road_incident?tracking_code=eq.${encodeURIComponent(code)}&select=id_incident`, {
    headers: { apikey: key, Authorization: `Bearer ${key}` },
  });
  const rows = await response.json();
  if (!rows.length) throw new Error(`No existe el reporte ${code}.`);
  return rows[0].id_incident;
}

const b64 = (value) => Buffer.from(value).toString('base64url');

async function accessToken(account) {
  const now = Math.floor(Date.now() / 1000);
  const unsigned = `${b64(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: account.token_uri,
    iat: now,
    exp: now + 3600,
  }))}`;
  const signature = createSign('RSA-SHA256').update(unsigned).sign(account.private_key, 'base64url');
  const response = await fetch(account.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${unsigned}.${signature}`,
  });
  const json = await response.json();
  if (!json.access_token) throw new Error(`Google no dio el token: ${JSON.stringify(json)}`);
  return json.access_token;
}

const [who, title, body, code] = process.argv.slice(2);
if (!who || !title || !body) {
  console.error('Uso: node tool/push/send_push.mjs <usuario|topic> "<título>" "<texto>" [#VIG-código]');
  process.exit(1);
}
try {
  const keyPath = process.env.FCM_SERVICE_ACCOUNT ?? join(homedir(), '.config', 'vigia', 'fcm-service-account.json');
  if (!existsSync(keyPath)) throw new Error(`No encuentro la llave de servicio en ${keyPath} (lección K2).`);
  const account = JSON.parse(readFileSync(keyPath, 'utf8'));
  const topic = topicOf(who);
  const data = code ? { incidentId: await incidentId(code) } : {};
  const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${await accessToken(account)}` },
    body: JSON.stringify({
      message: {
        topic,
        notification: { title, body },
        data,
        android: { priority: 'high', notification: { channel_id: 'vigia_alerts' } },
      },
    }),
  });
  const answer = await response.text();
  if (!response.ok) throw new Error(`FCM respondió ${response.status}: ${answer.slice(0, 300)}`);
  console.log(`Enviada a ${topic}${code ? ` (abre ${code})` : ''}.`);
} catch (error) {
  console.error(error.message);
  process.exit(1);
}
