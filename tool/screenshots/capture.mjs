// Screenshots of the real web build, as a guest (HU-22), for Cali and Medellín in
// light and dark. No dependencies: it drives an installed Chrome through the
// DevTools protocol (Node 22+).
//
//   flutter build web
//   python -m http.server 8124 --bind 127.0.0.1 --directory build/web
//   node tool/screenshots/capture.mjs
//
// Env: BASE_URL, CHROME (path to Chrome or Edge), OUT (folder), CITY (only one).
// The simulated GPS picks the city; the colour scheme picks light or dark. The
// photo and greeting follow the clock of the machine, as in the app.
import { spawn } from 'node:child_process';
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const BASE_URL = process.env.BASE_URL ?? 'http://127.0.0.1:8124/';
const OUT = process.env.OUT ?? 'docs/design/screenshots/ciudad-viva';
const PORT = 9333;
const CHROME =
  process.env.CHROME ??
  [
    'C:/Program Files/Google/Chrome/Application/chrome.exe',
    '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome',
    '/usr/bin/google-chrome',
  ].find(existsSync);

const CITIES = [
  { slug: 'cali', name: 'Cali', latitude: 3.4516, longitude: -76.532 },
  { slug: 'medellin', name: 'Medellín', latitude: 6.2442, longitude: -75.5812 },
].filter((city) => !process.env.CITY || city.slug === process.env.CITY);
const THEMES = [
  { slug: 'claro', scheme: 'light' },
  { slug: 'oscuro', scheme: 'dark' },
];

const sleep = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/** A small DevTools protocol client over the built-in WebSocket. */
async function connect(url) {
  const socket = new WebSocket(url);
  await new Promise((resolve, reject) => {
    socket.onopen = resolve;
    socket.onerror = reject;
  });
  let id = 0;
  const pending = new Map();
  socket.onmessage = ({ data }) => {
    const message = JSON.parse(data);
    const waiter = pending.get(message.id);
    if (!waiter) return;
    pending.delete(message.id);
    message.error ? waiter.reject(new Error(message.error.message)) : waiter.resolve(message.result);
  };
  return {
    send(method, params = {}, sessionId) {
      return new Promise((resolve, reject) => {
        pending.set(++id, { resolve, reject });
        socket.send(JSON.stringify({ id, method, params, sessionId }));
      });
    },
    close: () => socket.close(),
  };
}

async function openPage(browser, city, theme) {
  const { browserContextId } = await browser.send('Target.createBrowserContext');
  await browser.send('Browser.grantPermissions', {
    browserContextId,
    origin: new URL(BASE_URL).origin,
    permissions: ['geolocation'],
  });
  const { targetId } = await browser.send('Target.createTarget', { url: 'about:blank', browserContextId });
  const { sessionId } = await browser.send('Target.attachToTarget', { targetId, flatten: true });
  const send = (method, params) => browser.send(method, params, sessionId);

  await send('Page.enable');
  await send('Emulation.setDeviceMetricsOverride', {
    width: 390,
    height: 844,
    deviceScaleFactor: 2,
    mobile: false,
  });
  await send('Emulation.setEmulatedMedia', {
    features: [{ name: 'prefers-color-scheme', value: theme.scheme }],
  });
  await send('Emulation.setGeolocationOverride', {
    latitude: city.latitude,
    longitude: city.longitude,
    accuracy: 20,
  });

  const evaluate = async (expression) =>
    (await send('Runtime.evaluate', { expression, returnByValue: true, awaitPromise: true })).result.value;

  /** The smallest Flutter semantics node whose label or text matches. */
  const find = (pattern) =>
    evaluate(`(() => {
      const wanted = new RegExp(${JSON.stringify(pattern)});
      const nodes = [...document.querySelectorAll('flt-semantics, flt-semantics *')]
        .filter((n) => wanted.test(n.getAttribute?.('aria-label') ?? '') || wanted.test((n.innerText ?? '').trim()))
        .map((n) => n.getBoundingClientRect())
        .filter((r) => r.width > 0 && r.height > 0)
        .sort((a, b) => a.width * a.height - b.width * b.height);
      const r = nodes[0];
      return r ? { x: r.x + r.width / 2, y: r.y + r.height / 2, top: r.y } : null;
    })()`);

  const waitFor = async (pattern, timeout = 30000) => {
    for (const start = Date.now(); Date.now() - start < timeout; ) {
      const found = await find(pattern);
      if (found) return found;
      await sleep(500);
    }
    throw new Error(`not found: ${pattern}`);
  };

  const mouse = (type, x, y, extra = {}) => send('Input.dispatchMouseEvent', { type, x, y, ...extra });
  const tapAt = async (x, y) => {
    await mouse('mouseMoved', x, y);
    await mouse('mousePressed', x, y, { button: 'left', clickCount: 1 });
    await sleep(60);
    await mouse('mouseReleased', x, y, { button: 'left', clickCount: 1 });
  };
  const tap = async (pattern, wait = 1500) => {
    const target = await waitFor(pattern);
    await tapAt(target.x, target.y);
    await sleep(wait);
  };
  const scroll = async (dy, wait = 800) => {
    await mouse('mouseWheel', 195, 500, { deltaX: 0, deltaY: dy });
    await sleep(wait);
  };
  /** Flutter builds its semantics tree only once somebody asks for it. */
  const enableSemantics = async () => {
    for (let i = 0; i < 60; i++) {
      const done = await evaluate(`(() => {
        const placeholder = document.querySelector('flt-semantics-placeholder');
        if (placeholder) { placeholder.click(); return false; }
        return document.querySelector('flt-semantics') !== null;
      })()`);
      if (done) return;
      await sleep(500);
    }
    throw new Error('Flutter did not start');
  };

  const shot = async (screen) => {
    // Away from any control, so no hover state shows.
    await mouse('mouseMoved', 1, 1);
    await sleep(500);
    const { data } = await send('Page.captureScreenshot', { format: 'jpeg', quality: 86 });
    const file = join(OUT, `${city.slug}-${screen}-${theme.slug}.jpg`);
    writeFileSync(file, Buffer.from(data, 'base64'));
    console.log('  ', file);
  };

  return {
    send,
    find,
    waitFor,
    tap,
    tapAt,
    scroll,
    shot,
    enableSemantics,
    close: () => browser.send('Target.disposeBrowserContext', { browserContextId }),
  };
}

async function capture(browser, city, theme) {
  console.log(`${city.name} · ${theme.slug}`);
  const page = await openPage(browser, city, theme);
  await page.send('Page.navigate', { url: BASE_URL });
  await page.enableSemantics();
  await sleep(3000);

  // Registration, city step: the GPS city goes first with its tag.
  await page.tap('^Regístrate$');
  const detect = await page.waitFor('Detectar mi ciudad por GPS');
  await page.scroll(detect.top - 560);
  await page.tap('Detectar mi ciudad por GPS', 4000);
  const heading = await page.waitFor('¿Dónde vas a cuidar la calle\\?');
  await page.scroll(heading.top - 90, 2000);
  await page.shot('registro');
  await page.tap('^Volver$');

  // Guest mode: map, Comunidad and the first report.
  await page.tap('Explorar sin cuenta', 9000);
  await page.waitFor(`${city.name}, `);
  await page.shot('mapa');
  // The tab, not the title: its label also says which tab it is.
  await page.tap('^Comunidad([^A-Za-z]|$)', 5000);
  await page.shot('comunidad');

  const card = await page.find('^Reporte #');
  if (card) {
    await page.tapAt(card.x, Math.min(card.y, 700));
    await sleep(5000);
    await page.shot('detalle');
  } else {
    console.warn(`   no report in ${city.name}: no detail screenshot`);
  }
  await page.close();
}

if (!CHROME) throw new Error('Set CHROME to the path of Chrome or Edge.');
mkdirSync(OUT, { recursive: true });
const profile = mkdtempSync(join(tmpdir(), 'vigia-shots-'));
const chrome = spawn(CHROME, [
  '--headless=new',
  `--remote-debugging-port=${PORT}`,
  `--user-data-dir=${profile}`,
  '--no-first-run',
  '--hide-scrollbars',
  '--use-gl=swiftshader',
  '--enable-unsafe-swiftshader',
  'about:blank',
]);

let failed = false;
try {
  let version;
  for (let i = 0; i < 40 && !version; i++) {
    await sleep(500);
    version = await fetch(`http://127.0.0.1:${PORT}/json/version`).then((r) => r.json(), () => null);
  }
  if (!version) throw new Error('Chrome did not open its debugging port.');
  const browser = await connect(version.webSocketDebuggerUrl);
  for (const city of CITIES) {
    for (const theme of THEMES) {
      try {
        await capture(browser, city, theme);
      } catch (error) {
        failed = true;
        console.error(`   failed: ${error.message}`);
      }
    }
  }
  await browser.send('Browser.close').catch(() => {});
  browser.close();
} finally {
  chrome.kill();
  await sleep(1000);
  rmSync(profile, { recursive: true, force: true, maxRetries: 5, retryDelay: 500 });
}
process.exit(failed ? 1 : 0);
