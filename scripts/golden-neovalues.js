#!/usr/bin/env node
// Writes the reference results the Swift tests compare against.
// It runs NeoValues' own, unmodified results.html scoring script and quiz.js in Node (with a stub DOM),
// so the reference is whatever the original code does.
// Usage: node scripts/golden-neovalues.js <filtered-neovalues-folder> <output.json>
'use strict';
const fs = require('fs');
const path = require('path');
const vm = require('vm');

const src = path.resolve(process.argv[2]);
const outFile = path.resolve(process.argv[3]);
const read = (f) => fs.readFileSync(path.join(src, f), 'utf8');

function rng(seed) {
  let a = seed >>> 0;
  return () => {
    a = (a + 0x6d2b79f5) >>> 0;
    let t = a;
    t = Math.imul(t ^ (t >>> 15), t | 1);
    t ^= t + Math.imul(t ^ (t >>> 7), t | 61);
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

function element() {
  return {
    style: {},
    children: [],
    classList: { add() {}, remove() {} },
    appendChild(c) { this.children.push(c); },
    addEventListener() {},
    innerHTML: '',
    innerText: '',
    className: '',
  };
}

// ---------- Matching: the original scoring code from results.html ----------
function makeMatcherContext() {
  const ctx = {};
  vm.createContext(ctx);
  vm.runInContext(read('data.js'), ctx);
  const html = read('results.html');
  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map((m) => m[1]);
  const code = scripts.find((s) => s.includes('function renderResults'));
  if (!code) throw new Error('renderResults not found in results.html');
  const marker = "const secondaryLabelDiv = document.getElementById('secondary-label');";
  if (!code.includes(marker)) throw new Error('scoring marker not found in results.html');
  const patched = code.replace(marker, 'globalThis.__scored = scoredLabels; globalThis.__final = finalLabel;\n' + marker);

  const els = {};
  ctx.document = {
    getElementById(id) { return (els[id] ||= element()); },
    createElement() { return element(); },
    addEventListener() {},
  };
  ctx.window = { addEventListener() {} };
  ctx.localStorage = { store: {}, getItem(k) { return this.store[k] ?? null; }, setItem(k, v) { this.store[k] = v; } };
  ctx.I18n = { getValueName: (c, v) => v, getIdeologyName: (n) => n, t: (k) => k };
  vm.runInContext(patched, ctx);
  return ctx;
}

function runMatcher(ctx, answers) {
  ctx.localStorage.setItem('quizResults', JSON.stringify(answers));
  ctx.__scored = null;
  vm.runInContext('renderResults()', ctx);
  const scored = ctx.__scored.slice(0, 5).map((s) => ({
    label: s.label,
    matchPercentage: s.matchPercentage,
    identicalCount: s.identicalCount,
    broaderCount: s.broaderCount,
    totalRequired: s.totalRequired,
  }));
  return { exact: ctx.__final === 'No exact match' ? null : ctx.__final, scored };
}

// ---------- Quiz: the original quiz.js driven through its buttons ----------
function makeQuizContext(tree) {
  const ctx = {};
  vm.createContext(ctx);
  const state = { buttons: [], finished: false, stored: null, domReady: null };
  const question = element();
  const buttons = element();
  Object.defineProperty(buttons, 'innerHTML', {
    get() { return ''; },
    set() { state.buttons = []; },
  });
  buttons.appendChild = (b) => state.buttons.push(b);
  ctx.document = {
    getElementById(id) { return id === 'question' ? question : id === 'buttons' ? buttons : null; },
    createElement() { return { style: {}, onclick: null, innerText: '' }; },
    addEventListener(ev, fn) { if (ev === 'DOMContentLoaded') state.domReady = fn; },
  };
  const loc = {};
  Object.defineProperty(loc, 'href', { set() { state.finished = true; }, get() { return ''; } });
  ctx.window = { location: loc, addEventListener() {} };
  ctx.localStorage = { setItem(k, v) { state.stored = JSON.parse(v); } };
  ctx.questionsData = tree;
  vm.runInContext(read('quiz.js'), ctx);
  state.domReady();
  return { ctx, state };
}

function runQuizSequence(tree, seed) {
  const { ctx, state } = makeQuizContext(tree);
  const rand = rng(seed);
  const steps = [];
  const snapshot = () => ({
    categoryIndex: vm.runInContext('currentCategoryIndex', ctx),
    nodeId: vm.runInContext('currentNodeId', ctx),
  });
  let guard = 0;
  while (!state.finished && guard++ < 400) {
    const historyLength = vm.runInContext('history.length', ctx);
    if (historyLength > 0 && rand() < 0.15) {
      vm.runInContext('previousQuestion()', ctx);
      steps.push({ action: 'back', ...snapshot() });
    } else {
      const index = Math.floor(rand() * state.buttons.length);
      state.buttons[index].onclick();
      steps.push(state.finished ? { action: 'choose', index, finished: true } : { action: 'choose', index, ...snapshot() });
    }
  }
  return { seed, steps, results: state.stored };
}

// ---------- Build the cases ----------
const box = {};
vm.createContext(box);
vm.runInContext(read('data.js') + '\n;this.D = { categories, categoryValues, ideologies };', box);
const { categories, categoryValues, ideologies } = box.D;
const tree = JSON.parse(read('questions_tree.json'));

const random = rng(20261122);
const pick = (list) => list[Math.floor(random() * list.length)];

const answerSets = [];
// Constructed from an ideology's own requirements, so exact matches occur.
const names = Object.keys(ideologies);
for (let i = 0; i < names.length; i += 4) {
  const entry = ideologies[names[i]];
  const answers = {};
  for (const c of categories) {
    const req = entry[c];
    answers[c] = req === undefined ? pick(categoryValues[c]) : pick([].concat(req));
  }
  answerSets.push(answers);
  // The same answers with one category changed, to exercise partial matches and incompatible groups.
  const changed = { ...answers };
  const c = pick(categories);
  changed[c] = pick(categoryValues[c]);
  answerSets.push(changed);
}
// Fully random answers.
for (let i = 0; i < 60; i++) {
  const answers = {};
  for (const c of categories) answers[c] = pick(categoryValues[c]);
  answerSets.push(answers);
}

const matcherCtx = makeMatcherContext();
const matcher = answerSets.map((answers) => ({ answers, ...runMatcher(matcherCtx, answers) }));
const engine = [];
for (let seed = 1; seed <= 25; seed++) engine.push(runQuizSequence(tree, seed));

fs.mkdirSync(path.dirname(outFile), { recursive: true });
fs.writeFileSync(outFile, JSON.stringify({ matcher, engine }));
const exact = matcher.filter((m) => m.exact).length;
console.log(`Wrote ${matcher.length} matcher cases (${exact} with an exact match) and ${engine.length} quiz runs to ${outFile}`);
