#!/usr/bin/env node
// Removes excluded ideologies, the values only they need, and every question that leads only to them.
// Usage: node scripts/filter-neovalues.js <neovalues-folder> <exclusions.json>
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const dir = path.resolve(process.argv[2]);
const cfg = JSON.parse(fs.readFileSync(path.resolve(process.argv[3]), 'utf8'));
const read = (f) => fs.readFileSync(path.join(dir, f), 'utf8');
const write = (f, s) => fs.writeFileSync(path.join(dir, f), s);
const esc = (s) => s.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');

// 1. Work out what goes.
const sandbox = {};
vm.createContext(sandbox);
vm.runInContext(read('data.js') + '\n;this.D = { categories, categoryValues, ideologies };', sandbox);
const { categories, categoryValues, ideologies } = sandbox.D;
const reqs = (e) => {
  const out = [];
  for (const c of categories) if (c in e) for (const x of [].concat(e[c])) out.push([c, x]);
  return out;
};

const removedIdeo = new Set(cfg.ideologies);
const removedValues = new Set(cfg.values);
const cascaded = [];
for (const [name, entry] of Object.entries(ideologies)) {
  if (!removedIdeo.has(name) && reqs(entry).some(([, x]) => removedValues.has(x))) {
    removedIdeo.add(name);
    cascaded.push(name);
  }
}
const used = new Set();
for (const [name, entry] of Object.entries(ideologies)) {
  if (!removedIdeo.has(name)) for (const [c, x] of reqs(entry)) used.add(c + '|' + x);
}
for (const c of categories) {
  for (const v of categoryValues[c] || []) {
    if (!used.has(c + '|' + v)) removedValues.add(v);
  }
}

// Record problems that exist in the source, so they are not blamed on this filter.
const originalProblems = new Set(validate(dir, []).problems);

// 2. data.js: drop ideology blocks, key lines, and value IDs.
const lines = read('data.js').split('\n');
const out = [];
for (let i = 0; i < lines.length; i++) {
  const block = lines[i].match(/^\s{4}"(.+)": \{\s*$/);
  if (block && removedIdeo.has(block[1])) {
    while (i < lines.length && !/^\s{4}\},?\s*$/.test(lines[i])) i++;
    continue;
  }
  const key = lines[i].match(/^\s*"(.+?)":/);
  if (key && (removedIdeo.has(key[1]) || removedValues.has(key[1]))) continue;
  const bare = lines[i].match(/^\s*"(.+?)",?\s*$/);
  if (bare && removedValues.has(bare[1])) continue;
  out.push(lines[i]);
}
// Value IDs also appear inside arrays in these blocks only. Strip them there, and nowhere else.
const arrayBlocks = new Set(['categoryValues', 'subCategories', 'incompatibleSubCategories']);
const data = out.join('\n').split(/\n(?=const )/).map((block) => {
  const name = (block.match(/^const (\w+)/) || [])[1];
  if (!arrayBlocks.has(name)) return block;
  let b = block;
  for (const v of removedValues) {
    b = b.replace(new RegExp(',\\s*"' + esc(v) + '"', 'g'), '');
    b = b.replace(new RegExp('"' + esc(v) + '"\\s*,\\s*', 'g'), '');
  }
  return b;
}).join('\n');
write('data.js', data);

// 3. translations.js: drop descriptions and names for removed items.
const tPath = path.join(dir, 'translations.js');
if (fs.existsSync(tPath)) {
  const keep = read('translations.js').split('\n').filter((l) => {
    const k = l.match(/^\s*"(.+?)":/);
    return !(k && (removedIdeo.has(k[1]) || removedValues.has(k[1])));
  });
  write('translations.js', keep.join('\n'));
}

// 4. Remove files that name or show removed items.
for (const f of cfg.removeFiles) {
  const p = path.join(dir, f);
  if (fs.existsSync(p)) fs.rmSync(p);
}

// 5. Questions: remove options that lead nowhere, then branches with no options, then unreachable nodes.
const tree = JSON.parse(read('questions_tree.json'));
for (const c of categories) {
  let nodes = (tree[c] || []).filter((n) => n.options || !removedValues.has(n.id));
  let changed = true;
  while (changed) {
    changed = false;
    const ids = new Set(nodes.map((n) => n.id));
    for (const n of nodes) {
      if (n.options) {
        const kept = n.options.filter((o) => ids.has(o.next));
        if (kept.length !== n.options.length) { n.options = kept; changed = true; }
      }
    }
    const before = nodes.length;
    nodes = nodes.filter((n) => !n.options || n.options.length > 0);
    if (nodes.length !== before) changed = true;
  }
  const byId = new Map(nodes.map((n) => [n.id, n]));
  const reached = new Set(nodes.length ? [nodes[0].id] : []);
  const queue = [...reached];
  while (queue.length) {
    const n = byId.get(queue.shift());
    for (const o of (n && n.options) || []) if (!reached.has(o.next)) { reached.add(o.next); queue.push(o.next); }
  }
  tree[c] = nodes.filter((n) => reached.has(n.id));
  if (tree[c].length === 0) throw new Error('category emptied: ' + c);
}
write('questions_tree.json', JSON.stringify(tree));

// 6. Check the result. Problems that already existed in the source are reported, not blamed on the filter.
function validate(folder, forbiddenKeys) {
  const problems = [];
  const warnings = [];
  const box = {};
  vm.createContext(box);
  vm.runInContext(fs.readFileSync(path.join(folder, 'data.js'), 'utf8') + '\n;this.D = { categories, categoryValues, ideologies };', box);
  const V = box.D;
  for (const [name, entry] of Object.entries(V.ideologies)) {
    for (const [c, x] of reqs(entry)) {
      if (!(V.categoryValues[c] || []).includes(x)) problems.push(`ideology "${name}" needs unknown value "${x}"`);
    }
  }
  const tree = JSON.parse(fs.readFileSync(path.join(folder, 'questions_tree.json'), 'utf8'));
  for (const c of categories) {
    const vals = new Set(V.categoryValues[c] || []);
    const ids = new Set((tree[c] || []).map((n) => n.id));
    for (const n of tree[c] || []) {
      if (!n.options && !vals.has(n.id)) problems.push(`leaf "${n.id}" is not a value of ${c}`);
      for (const o of n.options || []) if (!ids.has(o.next)) problems.push(`"${n.id}" points to missing "${o.next}"`);
    }
  }
  for (const f of fs.readdirSync(folder, { recursive: true })) {
    const p = path.join(folder, f);
    if (!fs.statSync(p).isFile() || !/\.(js|html|json|css)$/.test(f) || /^LICENSE/.test(path.basename(f))) continue;
    const text = fs.readFileSync(p, 'utf8');
    for (const key of forbiddenKeys) {
      if (text.includes('"' + key + '"')) problems.push(`"${key}" still appears as a key or ID in ${f}`);
    }
    const mentions = (text.match(/Nazi|Fascis|Volk/g) || []).length;
    if (mentions && !/^(data|questions_tree)\./.test(f)) warnings.push(`${f}: ${mentions} free-text mention(s) of Nazi/Fascist/Volk terms, review`);
  }
  return { problems, warnings };
}

const forbiddenKeys = [...removedIdeo, ...removedValues];
const after = validate(dir, forbiddenKeys);
const newProblems = after.problems.filter((p) => !originalProblems.has(p));
if (newProblems.length) {
  console.error(newProblems.join('\n'));
  process.exit(1);
}
for (const p of after.problems) if (originalProblems.has(p)) console.log('existing in source (not caused by filter): ' + p);
for (const w of after.warnings) console.log('warning: ' + w);
console.log('Removed ideologies (' + removedIdeo.size + '): ' + [...removedIdeo].sort().join(', '));
console.log('  of which pulled in because they needed a removed value: ' + (cascaded.join(', ') || 'none'));
console.log('Removed values (' + removedValues.size + '): ' + [...removedValues].sort().join(', '));
console.log('Ideologies left: ' + (Object.keys(ideologies).length - removedIdeo.size) + '. Checks passed.');
