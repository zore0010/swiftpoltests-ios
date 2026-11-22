#!/usr/bin/env node
// Exports the filtered NeoValues data as JSON for the native app (English text only).
// Usage: node scripts/export-neovalues.js <neovalues-folder> <output-folder>
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const src = path.resolve(process.argv[2]);
const out = path.resolve(process.argv[3]);
const read = (f) => fs.readFileSync(path.join(src, f), 'utf8');

const box = {};
vm.createContext(box);
vm.runInContext(read('data.js') + '\n;this.D = { categories, categoryValues, ideologies, categoryTitles };', box);
vm.runInContext(read('translations.js') + '\n;this.T = TRANSLATIONS;', box);
const { categories, categoryValues, ideologies, categoryTitles } = box.D;
const en = box.T.en;
const tree = JSON.parse(read('questions_tree.json'));

const questions = {};
for (const c of categories) {
  questions[c] = (tree[c] || []).map((n) => {
    if (!n.options) return { id: n.id, leaf: true };
    return {
      id: n.id,
      text: n.en,
      options: n.options.map((o) => ({ text: o.en, next: o.next })),
    };
  });
}

const values = categories.map((c) => ({
  id: c,
  title: (categoryTitles && categoryTitles[c]) || en.categories[c] || c,
  values: (categoryValues[c] || []).map((v) => ({ id: v, name: en.values[v] || v })),
}));

const ideologyList = Object.entries(ideologies).map(([name, e]) => {
  const requirements = {};
  for (const c of categories) if (c in e) requirements[c] = [].concat(e[c]);
  return {
    name,
    group: e.group || null,
    color: e.color || null,
    requirements,
    description: en.descriptions[name] || null,
  };
});

fs.mkdirSync(out, { recursive: true });
fs.writeFileSync(path.join(out, 'questions.json'), JSON.stringify({ categories, questions }, null, 1));
fs.writeFileSync(path.join(out, 'values.json'), JSON.stringify(values, null, 1));
fs.writeFileSync(path.join(out, 'ideologies.json'), JSON.stringify(ideologyList, null, 1));
console.log(`Exported ${categories.length} categories, ${Object.values(questions).flat().length} nodes, ${ideologyList.length} ideologies to ${out}`);
