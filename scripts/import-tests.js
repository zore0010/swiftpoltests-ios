#!/usr/bin/env node
// Prepares the imported quizzes in Web/tests/<id> so they run without the network:
//   1. removes analytics, advertising and tracking code;
//   2. downloads every script, stylesheet and font they load into vendor/ and points the pages at it;
//   3. removes the fascist ideologies from their data (the entries and the names that link to them);
//   4. fails the build if any external resource or tracker is still referenced.
// Usage: node scripts/import-tests.js <web-folder> [--no-net]   (--no-net skips steps 2 and 4; for local tests only)
'use strict';
const fs = require('fs');
const os = require('os');
const path = require('path');
const vm = require('vm');
const { execFileSync } = require('child_process');

const webRoot = path.resolve(process.argv[2] || 'Web');
const noNet = process.argv.includes('--no-net');
const TESTS = ['axes', 'auth', 'inf', 'rightvalues', '10groups', '8dreams', 'theovalues', 'religioquest', 'mytests'];
const CACHE = path.join(os.tmpdir(), 'political-tests-vendor');
const UA = 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Safari/605.1.15';

// Scripts and stylesheets, pinned by URL. Each is saved as vendor/<file>.
const LIBS = [
  ['https://ajax.googleapis.com/ajax/libs/jquery/3.5.1/jquery.min.js', 'jquery-3.5.1.min.js'],
  ['https://code.jquery.com/jquery-1.10.2.js', 'jquery-1.10.2.js'],
  ['https://cdnjs.cloudflare.com/ajax/libs/list.js/2.3.1/list.min.js', 'list-2.3.1.min.js'],
  ['https://cdn.jsdelivr.net/npm/html2canvas@1.0.0-rc.5/dist/html2canvas.min.js', 'html2canvas-1.0.0-rc.5.min.js'],
  ['https://cdnjs.cloudflare.com/ajax/libs/html2canvas/0.4.1/html2canvas.js', 'html2canvas-0.4.1.js'],
];

const ANALYTICS = /googletagmanager|googlesyndication|pagead2|statcounter|adsbygoogle|google-analytics|gtag\(|dataLayer/i;
const FASCIST_NAME = /fascis|nazi|national.?socialis|volk/i;

function listFiles(dir, out = []) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    if (entry.name === 'vendor') continue;
    const p = path.join(dir, entry.name);
    if (entry.isDirectory()) listFiles(p, out);
    else out.push(p);
  }
  return out;
}

const textFiles = (dir) => listFiles(dir).filter((f) => /\.(html?|js|css|json)$/i.test(f));

// ---------- 1. analytics and advertising ----------
function sanitizeHtml(html) {
  return html
    .replace(/<script\b[^>]*\bsrc=["'][^"']*(googletagmanager|googlesyndication|pagead2|statcounter)[^"']*["'][^>]*>\s*<\/script>/gi, '')
    .replace(/<script\b([^>]*)>([\s\S]*?)<\/script>/gi, (all, attrs, body) =>
      !/\bsrc=/i.test(attrs) && ANALYTICS.test(body) ? '' : all)
    .replace(/<ins\b[^>]*adsbygoogle[^>]*>[\s\S]*?<\/ins>/gi, '')
    .replace(/<a\b[^>]*statcounter[^>]*>[\s\S]*?<\/a>/gi, '')
    .replace(/<noscript\b[^>]*>[\s\S]*?<\/noscript>/gi, (all) => (ANALYTICS.test(all) ? '' : all));
}


// ---------- 1b. paths ----------
// Upstream pages use absolute paths (/auth/style.css) and paths that climb out of the quiz folder (../icons/x.png).
// Under app://<id>/ both break, so they become paths relative to the file.
// The 10Groups pages ask for two compass images that the repository does not contain; the one it does contain is used.
const REPLACE = {
  axes: [['icon/12axes.png', 'icons/12axes.png']],          // the instructions page says icon/, the folder is icons/
  '10groups': [['blankcompass.png', 'compassimage.png'], ['./compass.png', './compassimage.png']],
};

function fixPaths(testRoot, id) {
  for (const file of textFiles(testRoot)) {
    const up = path.relative(path.dirname(file), testRoot).split(path.sep).join('/');
    const join = (p) => (up ? `${up}/${p}` : p);
    const fix = (ref) => {
      if (ref.startsWith('/') && !ref.startsWith('//')) {
        let p = ref.slice(1);
        if (p.startsWith(`${id}/`)) p = p.slice(id.length + 1);
        return join(p);
      }
      if (ref.startsWith('../')) {
        const target = path.normalize(path.join(path.dirname(file), ref));
        if (!target.startsWith(testRoot + path.sep)) return join(ref.replace(/^(\.\.\/)+/, ''));
      }
      return ref;
    };
    let text = fs.readFileSync(file, 'utf8');
    text = text.replace(/(\s(?:src|href)\s*=\s*)(["'])([^"']*)\2/gi, (all, lead, q, ref) => lead + q + fix(ref) + q);
    text = text.replace(/url\((["']?)([^)"']+)\1\)/gi, (all, q, ref) => `url(${q}${fix(ref)}${q})`);
    for (const [from, to] of REPLACE[id] || []) text = text.split(from).join(to);
    fs.writeFileSync(file, text);
  }
}

// Files the upstream repositories do not contain. Each is listed with the file that names it.
// Favicon links (rel="icon") are not checked: a missing favicon only changes the browser tab, which the app does not show.
const KNOWN_MISSING = new Set([]);

// Every local src, href and url() must resolve to a file in the bundle.
function checkLocalReferences(testRoot, id) {
  const problems = [];
  for (const file of textFiles(testRoot)) {
    const text = fs.readFileSync(file, 'utf8');
    const refs = [];
    for (const m of text.matchAll(/<(img|script|link|iframe|source)\b([^>]*)>/gi)) {
      if (/^link$/i.test(m[1]) && /\brel\s*=\s*["'][^"']*icon/i.test(m[2])) continue;
      const attr = m[2].match(/\b(?:src|href)\s*=\s*["']([^"']+)["']/i);
      if (attr) refs.push(attr[1]);
    }
    for (const m of text.matchAll(/url\(\s*["']?([^"')]+)["']?\s*\)/gi)) refs.push(m[1]);
    for (const ref of refs) {
      if (/^(https?:|data:|mailto:|javascript:|#)/i.test(ref)) continue;
      const clean = ref.split('#')[0].split('?')[0];
      if (!clean) continue;
      const target = path.normalize(path.join(path.dirname(file), clean));
      const key = `${id}/${path.relative(testRoot, file)}|${clean}`;
      if (!fs.existsSync(target) && !KNOWN_MISSING.has(key)) problems.push(`${id}/${path.relative(testRoot, file)}: missing ${clean}`);
    }
  }
  if (problems.length) throw new Error('local files referenced but not in the bundle:\n  ' + problems.join('\n  '));
}

// ---------- 2. bundling ----------
function download(url, dest) {
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  execFileSync('curl', ['-sSfL', '-A', UA, '-o', dest, url], { stdio: 'inherit' });
  if (fs.statSync(dest).size === 0) throw new Error('empty download: ' + url);
}

function buildVendor() {
  if (fs.existsSync(path.join(CACHE, 'done'))) {
    for (const [url, local] of JSON.parse(fs.readFileSync(path.join(CACHE, 'fonts.json'), 'utf8'))) fontMap.set(url, local);
    return;
  }
  fs.rmSync(CACHE, { recursive: true, force: true });
  const vendor = path.join(CACHE, 'vendor');
  for (const [url, file] of LIBS) download(url, path.join(vendor, file));

  // Google Fonts: save the stylesheet and the font files it names, so no request leaves the app.
  const fontUrls = new Set();
  for (const f of textFiles(webRoot)) {
    for (const m of fs.readFileSync(f, 'utf8').matchAll(/https:\/\/fonts\.googleapis\.com\/[^"'\s<>)]+/g)) fontUrls.add(m[0].replace(/&amp;/g, '&'));
  }
  for (const url of fontUrls) {
    const css = execFileSync('curl', ['-sSfL', '-A', UA, url], { encoding: 'utf8' });
    const name = 'font-' + Buffer.from(url).toString('base64url').slice(0, 40) + '.css';
    let rewritten = css;
    for (const m of new Set([...css.matchAll(/url\((https:\/\/fonts\.gstatic\.com\/[^)]+)\)/g)].map((x) => x[1]))) {
      const file = 'font-' + Buffer.from(m).toString('base64url').slice(-40) + path.extname(new URL(m).pathname);
      download(m, path.join(vendor, 'fonts', file));
      rewritten = rewritten.split(`url(${m})`).join(`url(./${file})`);
    }
    fs.mkdirSync(path.join(vendor, 'fonts'), { recursive: true });
    fs.writeFileSync(path.join(vendor, 'fonts', name), rewritten);
    fontMap.set(url, 'fonts/' + name);
  }

  // Font Awesome 5.15.4 (free), replacing the account kit that RightValues loads.
  execFileSync('npm', ['pack', '@fortawesome/fontawesome-free@5.15.4', '--pack-destination', CACHE], { stdio: 'ignore' });
  const tgz = fs.readdirSync(CACHE).find((f) => f.startsWith('fortawesome-fontawesome-free') && f.endsWith('.tgz'));
  execFileSync('tar', ['-xzf', path.join(CACHE, tgz), '-C', CACHE]);
  const fa = path.join(vendor, 'fontawesome');
  fs.mkdirSync(fa, { recursive: true });
  fs.cpSync(path.join(CACHE, 'package', 'css'), path.join(fa, 'css'), { recursive: true });
  fs.cpSync(path.join(CACHE, 'package', 'webfonts'), path.join(fa, 'webfonts'), { recursive: true });
  fs.rmSync(path.join(CACHE, 'package'), { recursive: true, force: true });

  fs.writeFileSync(path.join(CACHE, 'fonts.json'), JSON.stringify([...fontMap]));
  fs.writeFileSync(path.join(CACHE, 'done'), '');
}
const fontMap = new Map();

// Relative path from a file to the test's vendor folder.
function vendorPrefix(file, testRoot) {
  const rel = path.relative(path.dirname(file), path.join(testRoot, 'vendor'));
  return rel.split(path.sep).join('/');
}

function bundleInto(testRoot) {
  const vendor = path.join(CACHE, 'vendor');
  fs.cpSync(vendor, path.join(testRoot, 'vendor'), { recursive: true });
  for (const file of textFiles(testRoot)) {
    let text = fs.readFileSync(file, 'utf8');
    const prefix = vendorPrefix(file, testRoot);
    for (const [url, local] of LIBS) {
      for (const variant of [url, url.replace(/^https:/, '')]) text = text.split(variant).join(`${prefix}/${local}`);
    }
    for (const [url, local] of fontMap) {
      for (const variant of [url, url.replace(/^https:/, '')]) text = text.split(variant).join(`${prefix}/${local}`);
    }
    text = text.replace(/<script\b[^>]*kit\.fontawesome\.com[^>]*><\/script>/gi,
      `<link rel="stylesheet" href="${prefix}/fontawesome/css/all.min.css">`);
    fs.writeFileSync(file, text);
  }
}

// ---------- 3. fascist ideologies ----------
function removeFascistIdeologies(testRoot) {
  for (const file of textFiles(testRoot)) {
    const source = fs.readFileSync(file, 'utf8');
    if (!/\bideologies\s*=\s*\[/.test(source)) continue;
    const ctx = {};
    vm.createContext(ctx);
    vm.runInContext(source, ctx, { filename: file });
    const list = ctx.ideologies;
    if (!Array.isArray(list)) throw new Error(`${file}: ideologies is not a list`);
    const removed = new Set();
    const kept = list.filter((entry) => {
      const name = String(entry.name || '').replace(/<[^>]+>/g, ' ');
      if (FASCIST_NAME.test(name)) {
        removed.add(name.trim());
        return false;
      }
      return true;
    });
    if (removed.size === 0) continue;
    // Drop links to removed ideologies from the "next" lists.
    const names = [...removed];
    for (const entry of kept) {
      if (typeof entry.next === 'string') {
        entry.next = entry.next.split(',').map((s) => s.trim()).filter((s) => s && !names.some((n) => s.includes(n))).join(', ');
      }
    }
    const json = JSON.stringify(kept, null, 2);
    if (JSON.stringify(JSON.parse(json)) !== JSON.stringify(kept)) throw new Error(`${file}: data does not round-trip`);
    fs.writeFileSync(file, 'ideologies = ' + json + ';\n');
    console.log(`${path.relative(webRoot, file)}: removed ${removed.size} ideologies (${names.join(', ')})`);
  }
}

// ---------- 4. verification ----------
function verify(testRoot) {
  const problems = [];
  for (const file of textFiles(testRoot)) {
    const text = fs.readFileSync(file, 'utf8');
    const rel = path.relative(webRoot, file);
    if (ANALYTICS.test(text)) problems.push(`${rel}: analytics or advertising code`);
    if (/<(script|link|img|iframe|source|video|audio)\b[^>]*\b(src|href)\s*=\s*["'](https?:)?\/\//i.test(text)) problems.push(`${rel}: external script, style or image`);
    if (/url\(\s*["']?(https?:)?\/\//i.test(text)) problems.push(`${rel}: external url() in css`);
    if (/@import\s+(url\()?["']?(https?:)?\/\//i.test(text)) problems.push(`${rel}: external @import`);
    if (/(fetch|XMLHttpRequest)\s*\(\s*["'`]https?:\/\//.test(text)) problems.push(`${rel}: runtime request to another site`);
  }
  if (problems.length) throw new Error('external resources left after import:\n  ' + problems.join('\n  '));
}

// ---------- run ----------
for (const id of TESTS) {
  const testRoot = path.join(webRoot, 'tests', id);
  if (!fs.existsSync(testRoot)) throw new Error('missing test folder: ' + testRoot);
  for (const file of textFiles(testRoot)) {
    if (/\.html?$/i.test(file)) fs.writeFileSync(file, sanitizeHtml(fs.readFileSync(file, 'utf8')));
  }
  for (const f of listFiles(testRoot)) if (/google[0-9a-f]{10,}\.html$/i.test(f)) fs.rmSync(f);
  fixPaths(testRoot, id);
  if (!noNet) {
    buildVendor();
    bundleInto(testRoot);
  }
  removeFascistIdeologies(testRoot);
  if (!noNet) verify(testRoot);
  checkLocalReferences(testRoot, id);
  console.log(`prepared tests/${id}`);
}
