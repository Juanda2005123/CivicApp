// Inlines tokens.css into the *.src.html pages so each mockup is a single,
// self-contained file (it opens the same from a browser, a preview pane or an email).
// Usage (from this folder): node build.mjs
import { readFileSync, writeFileSync, readdirSync } from 'node:fs';

const css = readFileSync('tokens.css', 'utf8');
for (const name of readdirSync('.').filter((f) => f.endsWith('.src.html'))) {
  const html = readFileSync(name, 'utf8').replace(
    '<link rel="stylesheet" href="tokens.css">',
    `<style>\n${css}\n</style>`,
  );
  writeFileSync(name.replace('.src.html', '.html'), html);
  console.log(`built ${name.replace('.src.html', '.html')}`);
}
