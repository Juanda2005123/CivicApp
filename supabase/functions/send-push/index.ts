// Edge Function `send-push` (HU-24): sends one push notification through FCM
// HTTP v1 for every new row of the `notification` table (migration 011 calls
// it). The citizen's devices are subscribed to the topic `user_<id_user>`.
//
// Secrets (never in the app or the repo, lesson K2):
//   FCM_SERVICE_ACCOUNT  the service account key JSON of the Firebase project
//   PUSH_WEBHOOK_SECRET  shared with the database (Vault `push_webhook_secret`)
// Deployed with --no-verify-jwt: the database proves itself with the secret.

interface NotificationRow {
  id_user: string;
  id_incident: string | null;
  type: string;
  title: string;
  message: string;
}

interface ServiceAccount {
  client_email: string;
  private_key: string;
  project_id: string;
  token_uri: string;
}

const b64url = (data: ArrayBuffer | string) =>
  btoa(typeof data === 'string' ? data : String.fromCharCode(...new Uint8Array(data)))
    .replace(/=+$/, '').replace(/\+/g, '-').replace(/\//g, '_');

let cached: { token: string; expires: number } | null = null;

/// An OAuth access token for FCM, signed with the service account key (RS256).
async function accessToken(account: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  if (cached && cached.expires - 60 > now) return cached.token;

  const unsigned = `${b64url(JSON.stringify({ alg: 'RS256', typ: 'JWT' }))}.${b64url(JSON.stringify({
    iss: account.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: account.token_uri,
    iat: now,
    exp: now + 3600,
  }))}`;
  const pem = account.private_key.replace(/-----[^-]+-----/g, '').replace(/\s+/g, '');
  const der = Uint8Array.from(atob(pem), (c) => c.charCodeAt(0));
  const key = await crypto.subtle.importKey('pkcs8', der, { name: 'RSASSA-PKCS1-v1_5', hash: 'SHA-256' }, false, ['sign']);
  const signature = await crypto.subtle.sign('RSASSA-PKCS1-v1_5', key, new TextEncoder().encode(unsigned));

  const response = await fetch(account.token_uri, {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: `grant_type=urn%3Aietf%3Aparams%3Aoauth%3Agrant-type%3Ajwt-bearer&assertion=${unsigned}.${b64url(signature)}`,
  });
  const json = await response.json();
  if (!json.access_token) throw new Error(`token: ${JSON.stringify(json)}`);
  cached = { token: json.access_token, expires: now + (json.expires_in ?? 3600) };
  return cached.token;
}

Deno.serve(async (request) => {
  if (request.headers.get('x-push-secret') !== Deno.env.get('PUSH_WEBHOOK_SECRET')) {
    return new Response('forbidden', { status: 403 });
  }
  const { record } = (await request.json()) as { record?: NotificationRow };
  if (!record?.id_user) return new Response('no record', { status: 400 });

  const account = JSON.parse(Deno.env.get('FCM_SERVICE_ACCOUNT') ?? '{}') as ServiceAccount;
  const message = {
    message: {
      topic: `user_${record.id_user}`,
      notification: { title: record.title, body: record.message },
      // Tapping the push opens the report (criterion 3).
      data: { type: record.type, ...(record.id_incident ? { incidentId: record.id_incident } : {}) },
      android: { priority: 'high', notification: { channel_id: 'vigia_alerts' } },
    },
  };

  try {
    const response = await fetch(`https://fcm.googleapis.com/v1/projects/${account.project_id}/messages:send`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${await accessToken(account)}` },
      body: JSON.stringify(message),
    });
    const body = await response.text();
    if (!response.ok) console.error(`FCM ${response.status}: ${body}`);
    return new Response(body, { status: response.ok ? 200 : 502 });
  } catch (error) {
    console.error(error);
    return new Response(String(error), { status: 500 });
  }
});
