import assert from "node:assert/strict";
import fs from "node:fs";
import vm from "node:vm";

const path = process.argv[2];
assert(path, "actions.js path is required");
const context = {};
vm.runInNewContext(fs.readFileSync(path, "utf8"), context);

const panelPath = process.argv[3];
assert(panelPath, "panel.html path is required");
const panelSource = fs.readFileSync(panelPath, "utf8");
const emojiStart = panelSource.indexOf("const EMOJI_CAP");
const emojiEnd = panelSource.indexOf("const PREFIX_CAP", emojiStart);
assert(emojiStart >= 0 && emojiEnd > emojiStart, "emoji search source is required");
const emojiContext = {
  emoji: [
    { code: "alpha", cp: "a", name: "Alpha", search: "alpha first" },
    { code: "beta", cp: "b", name: "Beta", search: "beta second" },
    { code: "gamma", cp: "g", name: "Gamma", search: "gamma third" },
  ],
  recent: { beta: 10 },
};
vm.runInNewContext(panelSource.slice(emojiStart, emojiEnd), emojiContext);

const actions = [
  {
    name: "terminal",
    label: "Terminal",
    commands: [
      { name: "open", detail: "Open a terminal" },
      { name: "run", detail: "Run a command", argument: "command" },
    ],
  },
  {
    name: "browser",
    label: "Browser",
    commands: [
      { name: "focus", detail: "Focus the browser" },
      { name: "open", detail: "Open a URL", argument: "url" },
    ],
  },
];
const parse = (query) => context.actionRows(query, actions, 12);

assert.equal(parse("+ter")[0].completion, "+terminal ");
assert.deepEqual(
  Array.from(parse("+terminal "), (row) => row.title),
  ["+terminal open", "+terminal run"],
);
assert.equal(parse("+terminal r")[0].completion, "+terminal run ");
assert.equal(parse("+terminal run")[0].action, undefined);
assert.equal(parse("+terminal run git status")[0].command, "run");
assert.equal(parse("+terminal run git status")[0].arg, "git status");
assert.equal(parse("+terminal open")[0].command, "open");
assert.equal(parse("+terminal open extra").length, 0);
assert.equal(parse("+browser open")[0].action, undefined);
assert.equal(parse("+browser open example.com")[0].arg, "example.com");
assert.equal(parse("+unknown ").length, 0);

assert.deepEqual(
  Array.from(emojiContext.emojiRows(":"), (row) => row.code),
  ["beta", "alpha", "gamma"],
);
assert.deepEqual(
  Array.from(emojiContext.emojiRows(":third"), (row) => row.code),
  ["gamma"],
);
