// Sprint 2 demo recorder (Playwright). Drives the Flutter web build and records a video.
//
//   flutter build web
//   (cd build/web && python3 -m http.server 8099) &
//   cd tool/demo && npm install
//   DEMO_EMAIL=you+b@gmail.com DEMO_PASSWORD=Vigia2026 node demo.mjs
//
// Env: BASE_URL, DEMO_EMAIL, DEMO_PASSWORD, DEMO_LAT, DEMO_LON, DEMO_CRUCE, DEMO_BARRIO, HEADED=1, SLOW=1.5 (pause multiplier),
//      PLAYWRIGHT_CHROMIUM (path to a Chromium/Chrome executable, optional).
// Output: tool/demo/out/*.webm and a screenshot of any failing step.
import { chromium } from 'playwright';
import { mkdirSync, readdirSync, renameSync } from 'node:fs';

const BASE_URL = process.env.BASE_URL ?? 'http://localhost:8099/';
const EMAIL = process.env.DEMO_EMAIL;
const PASSWORD = process.env.DEMO_PASSWORD;
// Simulated GPS. Default: centre of Cali; set DEMO_LAT / DEMO_LON to the exact spot of the hazard.
const LAT = Number(process.env.DEMO_LAT ?? 3.4516);
const LON = Number(process.env.DEMO_LON ?? -76.532);
if (!Number.isFinite(LAT) || !Number.isFinite(LON) || Math.abs(LAT) > 90 || Math.abs(LON) > 180) {
  console.error(`DEMO_LAT / DEMO_LON must be real numbers (for example DEMO_LAT=3.4516 DEMO_LON=-76.5320), got "${process.env.DEMO_LAT}" / "${process.env.DEMO_LON}".`);
  process.exit(1);
}
const CRUCE = process.env.DEMO_CRUCE ?? '56'; // cross street of the typed address
const BARRIO = process.env.DEMO_BARRIO ?? 'Autopista Sur'; // used only when the app proposes none
const SLOW = Number(process.env.SLOW ?? 1);
const OUT = new URL('./out/', import.meta.url).pathname;
mkdirSync(OUT, { recursive: true });

const browser = await chromium.launch({
  headless: !process.env.HEADED,
  executablePath: process.env.PLAYWRIGHT_CHROMIUM || undefined,
  args: ['--use-gl=swiftshader', '--enable-unsafe-swiftshader'],
});
const context = await browser.newContext({
  viewport: { width: 430, height: 900 },
  geolocation: { latitude: LAT, longitude: LON },
  permissions: ['geolocation'],
  recordVideo: { dir: OUT, size: { width: 430, height: 900 } },
});
const page = await context.newPage();

const pause = (ms) => page.waitForTimeout(ms * SLOW);

/** Subtitle bar drawn over the app: it is the narration of the video. */
async function caption(text) {
  await page.evaluate((t) => {
    let el = document.getElementById('demo-caption');
    if (!el) {
      el = document.createElement('div');
      el.id = 'demo-caption';
      el.style.cssText =
        'position:fixed;left:8px;right:8px;top:8px;z-index:99999;padding:8px 12px;border-radius:8px;' +
        'background:rgba(20,40,56,.92);color:#fff;font:600 14px sans-serif;text-align:center;pointer-events:none';
      document.body.appendChild(el);
    }
    el.textContent = t;
  }, text);
}

// SKIP_WIZARD=1 skips the report wizard (it publishes a real report), to test the other scenes.
const WIZARD = ['HU-06 · HU-07', 'HU-08 · HU-09', 'HU-10', 'HU-11', 'HU-12'];

async function scene(historias, text, fn) {
  if (process.env.SKIP_WIZARD && WIZARD.includes(historias)) return;
  console.log(`▶ ${historias}: ${text}`);
  try {
    await caption(`${historias} · ${text}`);
    await fn();
    if (process.env.STOP_AFTER && text.includes(process.env.STOP_AFTER)) {
      await page.screenshot({ path: `${OUT}STOP.png` });
      console.log('STOP_AFTER reached:', text);
      await finish(0);
    }
  } catch (e) {
    const shot = `${OUT}FAILED-${historias.replace(/\W+/g, '_')}.png`;
    await page.screenshot({ path: shot });
    console.error(`✗ ${historias} failed: ${e.message.split('\n')[0]}\n  screenshot: ${shot}`);
    await finish(1);
  }
}

const button = (name) => page.getByRole('button', { name });
const tap = async (name, wait = 1200) => {
  await button(name).first().click();
  await pause(wait);
};
/** The city button is named after the city: "Ciudad, Departamento" (a marker has two commas). */
const openCitySwitcher = async () => {
  await page.getByRole('button', { name: /^[^,]+, [^,]+$/ }).first().click();
  await pause(1500);
};
/** Searches a city in the open switcher and picks it (the sheet's row is the last match: the button behind has the same text). */
const pickCity = async (query, label) => {
  await fill('Buscar ciudad o departamento', query);
  await pause(1500);
  await page.getByText(label).last().click();
  await pause(3500);
};
const hasText = (re) => page.getByText(re).first().waitFor({ timeout: 15000 });

/** Types into a Flutter text field found by its label, like a person would. */
async function fill(label, value) {
  const field = page.getByRole('textbox', { name: label }).first();
  await field.click();
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value, { delay: 60 });
  await pause(250);
}

async function finish(code = 0) {
  await context.close(); // flushes the video
  await browser.close();
  const webm = readdirSync(OUT).filter((f) => f.endsWith('.webm') && !f.startsWith('demo-'));
  if (webm[0]) renameSync(`${OUT}${webm[0]}`, `${OUT}demo-${Date.now()}.webm`);
  console.log(code === 0 ? `✓ done, video in ${OUT}` : `video up to the failure in ${OUT}`);
  process.exit(code);
}

// ---------------------------------------------------------------- start
await page.goto(BASE_URL);
await page.waitForSelector('flt-semantics-placeholder', { state: 'attached', timeout: 30000 });
await page.locator('flt-semantics-placeholder').dispatchEvent('click'); // turns on Flutter's accessibility tree
await hasText(/Explorar sin cuenta/);
await pause(1500);

// ---------------------------------------------------------------- HU-22 guest
await scene('HU-22', 'Entro como visitante, sin cuenta', async () => {
  await tap('Explorar sin cuenta', 3500);
  await caption('HU-22 · Veo Mapa y Comunidad sin credenciales');
  await pause(2000);
  await tap('Reportar daño');
  await hasText(/iniciar sesión|registr/i);
  await caption('HU-22 · Reportar me invita a iniciar sesión o registrarme');
  await pause(2500);
  await page.keyboard.press('Escape');
  await pause(800);
  await tap('Mi perfil');
  await hasText(/iniciar sesión|registr/i);
  await caption('HU-22 · Mi perfil muestra la misma invitación');
  await pause(2500);
});

if (!EMAIL || !PASSWORD) {
  console.log('DEMO_EMAIL / DEMO_PASSWORD not set: stopping after the guest scene.');
  await finish(0);
}

// ---------------------------------------------------------------- login
await scene('HU-19', 'Inicio sesión y llego a mi perfil', async () => {
  await page.reload();
  await page.locator('flt-semantics-placeholder').dispatchEvent('click');
  await hasText(/Ingresa a tu cuenta/);
  await fill('Correo electrónico', EMAIL);
  await fill('Contraseña', PASSWORD);
  await tap('Ingresar', 3500);
  await button('Reportar daño').first().waitFor({ timeout: 20000 }); // the shell opens on Mapa
  await caption('HU-19 · Abajo: Mapa, Comunidad y Mi perfil');
  await pause(2000);
  await tap('Mi perfil', 3000);
  await hasText(/Puntos de reputación/);
  await pause(2000);
});

// ---------------------------------------------------------------- map
await scene('HU-03 · HU-13', 'El mapa pide la ubicación y se centra en mí', async () => {
  await tap('Mapa', 4000);
  await pause(2500);
});

// ---------------------------------------------------------------- city switcher
await scene('HU-13', 'Estoy en Cali: el mapa abre en mi ciudad', async () => {
  await caption('HU-13 · Me registré en otra ciudad, pero el mapa abre donde estoy');
  await pause(3000);
  await tap('Centrar en mi ubicación', 3000);
});

await scene('HU-21', 'Consulto otra ciudad y vuelvo a la mía', async () => {
  await openCitySwitcher();
  await pickCity('medellin', 'Medellín, Antioquia');
  await caption('HU-21 · El mapa se va a Medellín; mi ubicación guardada no cambia');
  await pause(2500);
  await caption('HU-21 · "Centrar en mi ubicación" me lleva a mi posición sin cambiar la ciudad que consulto ni la guardada');
  await tap('Centrar en mi ubicación', 4500);
  await caption('HU-21 · Vuelvo a mi ciudad desde el selector');
  await openCitySwitcher();
  await pickCity('cali', 'Cali, Valle del Cauca');
});

// ---------------------------------------------------------------- feed
await scene('HU-19', 'Comunidad: los reportes de mi ciudad', async () => {
  await tap('Comunidad', 3500);
  await page.mouse.wheel(0, 700);
  await pause(2500);
});

// ---------------------------------------------------------------- wizard
await scene('HU-06 · HU-07', 'Paso 1: ubico el daño', async () => {
  await tap('Mapa', 2000);
  await tap('Reportar daño', 3000);
  await hasText(/Paso 1 de 5/);
  await pause(1500);
  await fill('Cruce o generadora (#)', CRUCE);
  await caption('HU-06 · Si salgo con datos escritos, la app me pide confirmar');
  await page.getByRole('button', { name: 'Cerrar asistente' }).first().click();
  await pause(2500);
  await tap('Seguir editando', 1500);
  await caption('HU-27 · Muevo el punto del daño directamente en el mapa');
  await tap('Seleccionar ubicación', 3500);
  // Drag the map under the fixed pin, slowly, like a finger.
  await page.mouse.move(215, 430);
  await page.mouse.down();
  await page.mouse.move(185, 410, { steps: 25 });
  await page.mouse.up();
  await pause(2500);
  await tap('Confirmar punto', 4000);
  await caption('HU-26 · La app propone la dirección del punto; puedo corregirla');
  await pause(3500);
  await page.screenshot({ path: `${OUT}STOP.png` });
  if (process.env.STOP_AFTER === 'pinned') { console.log('pinned captured'); await finish(0); }
  // The app proposes the neighbourhood from the point; type one only when it left it empty.
  const barrio = page.getByRole('textbox', { name: 'Barrio o sector' }).first();
  if (!(await barrio.inputValue().catch(() => ''))) await fill('Barrio o sector', BARRIO);
  await tap('Confirmar ubicación', 4000);
  await tap('Continuar', 2000);
});

await scene('HU-08 · HU-09', 'Paso 2: tipo, gravedad y reportes parecidos', async () => {
  await hasText(/Paso 2 de 5/);
  await pause(1500);
  await tap('Continuar', 1500); // nothing chosen yet: the screen says what is missing
  await caption('HU-08 · Si falta el tipo o la gravedad, me lo señala y no avanza');
  await pause(2500);
  await page.getByText(/Hueco|bache/i).first().click();
  await pause(1000);
  await tap('Alta', 2000);
  await tap('Continuar', 1000); // the nearby check runs now; with none the wizard goes straight to step 3
  const cercanos = page.getByText(/Ver daños/).first();
  const paso3 = page.getByText(/Paso 3 de 5/).first();
  for (let i = 0; i < 40 && !(await cercanos.count()) && !(await paso3.count()); i++) {
    await page.mouse.move(200 + (i % 2) * 20, 700); // keeps headless Chromium painting
    await page.waitForTimeout(1000);
  }
  if (await cercanos.count()) {
    await caption('HU-09 · Hay reportes parecidos cerca: los reviso sin perder mi progreso');
    await pause(2500);
    await cercanos.click();
    await pause(3500);
    if (process.env.STOP_AFTER === 'sheet') { await page.screenshot({ path: `${OUT}STOP.png` }); console.log('sheet captured'); await finish(0); }
    await tap('Es otro daño', 2500);
  }
});

/** Adds a photo through the web picker's native file chooser. */
async function addPhoto(file) {
  let opened = false;
  page.once('filechooser', async (fc) => {
    opened = true;
    await fc.setFiles(new URL(`./assets/${file}`, import.meta.url).pathname);
  });
  await page.getByText('Agregar', { exact: true }).first().click();
  await pause(1500);
  await page.getByText(/Elegir foto de la galería/).first().click();
  await pause(4000);
  if (!opened) throw new Error('the file chooser did not open');
}

await scene('HU-10', 'Paso 3: fotos como evidencia', async () => {
  await hasText(/Paso 3 de 5/);
  await pause(1500);
  await caption('HU-10 · Solo acepto JPG, PNG o WebP: este formato se rechaza');
  await addPhoto('hueco.jfif');
  await pause(3000);
  if (process.env.STOP_AFTER === 'rejected') { await page.screenshot({ path: `${OUT}STOP.png` }); console.log('rejected captured'); await finish(0); }
  await caption('HU-10 · Con una foto válida: la primera queda como principal');
  await addPhoto('hueco.jpg');
  await pause(2500);
  await caption('HU-10 · Hasta 3 fotos: al llegar al límite no puedo agregar más');
  await addPhoto('hueco.jpg');
  await addPhoto('hueco.jpg');
  await pause(2500);
  if (process.env.STOP_AFTER === 'limit') { await page.screenshot({ path: `${OUT}STOP.png` }); console.log('limit captured'); await finish(0); }
  await tap('Continuar', 1500);
});

await scene('HU-11', 'Paso 4: título y descripción', async () => {
  await hasText(/Paso 4 de 5/);
  await tap('Revisar reporte', 1500); // empty fields: shows the errors
  await caption('HU-11 · Título y descripción son obligatorios');
  await pause(2000);
  // A title over 180 characters is refused with its limit (pasted: typing 185 characters takes too long on camera).
  await page.getByRole('textbox', { name: 'Título del reporte' }).first().click();
  await page.keyboard.insertText('Hueco '.repeat(31));
  await tap('Revisar reporte', 1500);
  await caption('HU-11 · El título tiene un límite de 180 caracteres');
  await pause(2500);
  if (process.env.STOP_AFTER === 'limit180') { await page.screenshot({ path: `${OUT}STOP.png` }); console.log('limit180 captured'); await finish(0); }
  await fill('Título del reporte', 'Hueco profundo en carril derecho');
  await fill('Descripción detallada', 'Hueco de unos 20 cm de profundidad que obliga a frenar de golpe.');
  await tap('Revisar reporte', 2500);
});

await scene('HU-12', 'Paso 5: publico y recibo mi código', async () => {
  await hasText(/Paso 5 de 5/);
  await pause(2500);
  await tap('Publicar reporte (+100 XP)', 5000);
  await hasText(/#VIG-\d+/);
  await caption('HU-12 · Reporte publicado con su código único');
  await pause(3500);
  await tap('Aceptar', 2500);
});

await scene('HU-12 · HU-13', 'Mi reporte aparece en el mapa y gané +100 XP', async () => {
  await tap('Mi perfil', 3000);
  // The city switcher left the map on another city: go back to the one with the new report.
  await tap('Mapa', 2000);
  await openCitySwitcher();
  await pickCity('cali', 'Cali, Valle del Cauca');
});

await scene('HU-13 · HU-14', 'Marcador por tipo y detalle del reporte', async () => {
  const marker = page.getByRole('button', { name: /Hueco profundo en carril derecho.*gravedad/i }).first();
  await marker.waitFor({ timeout: 20000 });
  // The citizen's own dot sits over a report made on the spot and eats mouse taps:
  // activate the marker through Flutter's accessibility tree instead.
  await marker.dispatchEvent('click');
  await pause(2000);
  await hasText(/#VIG-\d+/);
  await caption('HU-14 · Detalle: código, estado, gravedad, ubicación y autor');
  await pause(5000);
  await tap(/Volver|Back|Atrás/i);
});

await scene('HU-19', 'Comunidad muestra mi reporte', async () => {
  await tap('Comunidad', 4000);
});

await finish(0);
