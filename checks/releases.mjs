import assert from "node:assert/strict";
import test from "node:test";
import { reconstruct } from "../hack/reconstruct-releases.mjs";

function commit(message, index = 1, extra = {}) {
  return {
    hash: index.toString(16).padStart(40, "0"),
    date: "2020-01-02T12:00:00+00:00",
    message,
    ...extra,
  };
}

test("history uses semantic-release rules and includes unclassified notes", async () => {
  const result = await reconstruct([
    commit("initial configuration"),
    commit("feat(shell): add shell", 2),
    commit("fix(shell): correct path", 3),
    commit("feat(mail): add inbox", 4),
    commit("refactor(shell)!: replace interface", 5),
    commit("chore(deps): update packages", 6),
    commit("docs: explain setup", 7),
  ]);
  assert.deepEqual(
    result.releases.map(({ version }) => version),
    ["1.0.0", "1.0.1", "1.1.0", "2.0.0", "2.0.1"],
  );
  assert.match(result.releases[0].notes, /initial configuration/);
  assert.match(result.releases[0].notes, /2020-01-02/);
  assert.match(result.releases[4].notes, /update packages/);
  assert.equal(result.unreleased.length, 1);
});

test("breaking footers cause major releases", async () => {
  const { releases } = await reconstruct([
    commit("feat: initial release"),
    commit("fix: change config\n\nBREAKING CHANGE: rename setting", 2),
  ]);
  assert.equal(releases[1].version, "2.0.0");
  assert.match(releases[1].notes, /rename setting/);
});

test("merged changes release at the mainline merge", async () => {
  const { releases } = await reconstruct([
    commit("feat: branch feature", 1, { merged: true }),
    commit("Merge branch feature", 2),
  ]);
  assert.equal(releases.length, 1);
  assert.equal(releases[0].gitHead, commit("", 2).hash);
  assert.match(releases[0].notes, /branch feature/);
});

test("documentation alone creates no version", async () => {
  assert.equal((await reconstruct([commit("docs: setup")])).releases.length, 0);
});

test("standard Git revert messages cause patch releases", async () => {
  const { releases } = await reconstruct([
    commit("feat: initial release"),
    commit(
      'Revert "feat: initial release"\n\nThis reverts commit ' +
        commit("").hash +
        ".",
      2,
    ),
  ]);
  assert.equal(releases.length, 2);
  assert.equal(releases[1].version, "1.0.1");
});
