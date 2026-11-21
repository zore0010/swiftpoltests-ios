import Foundation

/// JavaScript added to each quiz page. It saves progress after every answer, restores it on the quiz
/// page, and records a finished result on the results page. It only wraps functions the quiz already
/// defines, so the bundled quiz files are not edited.
enum OverlayScript {
    static let messageName = "wkwv"

    /// The script for one test: it sets the test id, then runs the shared overlay.
    static func source(for testID: String) -> String {
        "window.wkwvTestID = '" + testID + "';\n" + overlay
    }

    static let overlay = #"""
(function () {
  'use strict';
  var handler = window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.wkwv;
  if (!handler) { return; }
  var testID = window.wkwvTestID || '';
  var page = (location.pathname.split('/').pop() || 'index.html').toLowerCase();

  function post(message) {
    try { handler.postMessage(message); } catch (e) { }
  }

  function save(state) {
    post({ type: 'save', payload: JSON.stringify(state) });
  }

  function complete(data) {
    var raw = JSON.stringify(data);
    var guard = 'wkwv-last-complete-' + testID;
    if (sessionStorage.getItem(guard) === raw) { return; }
    sessionStorage.setItem(guard, raw);
    post({ type: 'complete', payload: raw });
  }

  // 12 Axes (quiz.html and longquiz.html). State lives in the page globals qn, quests, answers, scores.
  function axesState() {
    return { qn: qn, answers: answers, quests: quests, scores: scores };
  }

  function axesWrap() {
    var originalNext = window.next_question;
    var originalPrev = window.prev_question;
    window.next_question = function (mult) {
      originalNext(mult);
      if (qn < quests.length) { save(axesState()); }
    };
    window.prev_question = function () {
      originalPrev();
      if (qn < quests.length) { save(axesState()); }
    };
  }

  function axesRestore(s) {
    if (!s || !Array.isArray(s.quests) || !Array.isArray(s.answers) || !Array.isArray(s.scores)) { return; }
    if (!Number.isInteger(s.qn) || s.qn < 0 || s.qn >= s.quests.length || s.scores.length !== 12) { return; }
    quests = s.quests;
    answers = s.answers;
    scores = s.scores;
    qn = s.qn;
    init_question();
  }

  // NeoValues (quiz.html). State lives in the page's lets: currentCategoryIndex, currentNodeId, results, history.
  function nvState() {
    return { categoryIndex: currentCategoryIndex, nodeId: currentNodeId, results: results, history: history };
  }

  function nvWrap() {
    var originalSelect = window.selectOption;
    var originalPrev = window.previousQuestion;
    window.selectOption = function (nextId) {
      originalSelect(nextId);
      if (currentCategoryIndex < categoryOrder.length) { save(nvState()); }
    };
    window.previousQuestion = function () {
      originalPrev();
      if (history.length > 0) { save(nvState()); }
    };
  }

  function nvRestore(s, attempts) {
    if (!s || typeof s.categoryIndex !== 'number' || !Array.isArray(s.history)) { return; }
    if (!s.results || typeof s.results !== 'object') { return; }
    if (typeof questionsByCategory === 'undefined' || Object.keys(questionsByCategory).length === 0) {
      if ((attempts || 0) < 100) {
        setTimeout(function () { nvRestore(s, (attempts || 0) + 1); }, 100);
      }
      return;
    }
    if (s.categoryIndex < 0 || s.categoryIndex >= categoryOrder.length) { return; }
    currentCategoryIndex = s.categoryIndex;
    results = s.results;
    history = s.history;
    loadCategoryMap(categoryOrder[currentCategoryIndex]);
    var node = currentQuestions[s.nodeId];
    if (node) {
      renderNode(node);
    } else {
      startQuizCategory(categoryOrder[currentCategoryIndex]);
    }
  }

  // Called by the app with the saved state (or null) after the quiz page asks for it.
  window.wkwvRestore = function (saved) {
    if (testID === 'axes') { axesRestore(saved); }
    if (testID === 'neovalues') { nvRestore(saved, 0); }
  };

  function start() {
    if (page === 'quiz.html' || page === 'longquiz.html') {
      if (testID === 'axes') { axesWrap(); }
      if (testID === 'neovalues') { nvWrap(); }
      post({ type: 'load' });
    } else if (page === 'results.html') {
      if (testID === 'axes' && location.search) {
        complete({ query: location.search });
      }
      if (testID === 'neovalues') {
        var raw = localStorage.getItem('quizResults');
        if (raw) {
          try { complete({ results: JSON.parse(raw) }); } catch (e) { }
        }
      }
    }
  }

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', start);
  } else {
    start();
  }
})();
"""#
}
