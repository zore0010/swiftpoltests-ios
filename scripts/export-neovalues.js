#!/usr/bin/env node
// Exports the filtered NeoValues data as JSON for the native app (English text only).
// Usage: node scripts/export-neovalues.js <neovalues-folder> <output-folder>
//
// Order matters: the original matching code iterates objects in insertion order and its sorts are stable,
// so requirements, sub-category groups and ideologies are written as arrays that keep that order.
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const src = path.resolve(process.argv[2]);
const out = path.resolve(process.argv[3]);
const read = (f) => fs.readFileSync(path.join(src, f), 'utf8');

const box = {};
vm.createContext(box);
vm.runInContext(
  read('data.js') +
    '\n;this.D = { categories, categoryValues, ideologies, categoryTitles, subCategories, incompatibleSubCategories };',
  box
);
vm.runInContext(read('translations.js') + '\n;this.T = TRANSLATIONS;', box);
const { categories, categoryValues, ideologies, categoryTitles, subCategories, incompatibleSubCategories } = box.D;
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
  values: (categoryValues[c] || []).map((v) => ({
    id: v,
    name: en.values[v] || v.replace(/_/g, ' '),
    description: en.descriptions[v] || null,
  })),
}));

// Requirements keep the key order of the original entry (Object.keys skips the hidden group/color keys).
const ideologyList = Object.entries(ideologies).map(([name, e]) => ({
  name,
  group: e.group || null,
  color: e.color || null,
  requirements: Object.keys(e).map((category) => ({ category, allowed: [].concat(e[category]) })),
  description: en.descriptions[name] || null,
}));

const matching = {
  subCategories: Object.fromEntries(
    Object.entries(subCategories).map(([category, groups]) => [
      category,
      Object.entries(groups).map(([group, vals]) => ({ group, values: vals })),
    ])
  ),
  incompatible: incompatibleSubCategories,
};

fs.mkdirSync(out, { recursive: true });
fs.writeFileSync(path.join(out, 'questions.json'), JSON.stringify({ categories, questions }));
fs.writeFileSync(path.join(out, 'values.json'), JSON.stringify(values));
fs.writeFileSync(path.join(out, 'ideologies.json'), JSON.stringify(ideologyList));
fs.writeFileSync(path.join(out, 'matching.json'), JSON.stringify(matching));
console.log(
  `Exported ${categories.length} categories, ${Object.values(questions).flat().length} nodes, ${ideologyList.length} ideologies to ${out}`
);
