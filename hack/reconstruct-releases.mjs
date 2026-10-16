import { execFileSync } from "node:child_process";
import { mkdirSync, writeFileSync } from "node:fs";
import { createRequire } from "node:module";
import { resolve } from "node:path";
import { pathToFileURL } from "node:url";
import config, { analyzer, notes } from "../release.config.mjs";

if (!process.env.SEMANTIC_RELEASE_ROOT) {
  throw new Error("Run this command with nix develop .#release --command node");
}
const require = createRequire(
  `${process.env.SEMANTIC_RELEASE_ROOT}/package.json`,
);
const { analyzeCommits } = await import(
  pathToFileURL(require.resolve("@semantic-release/commit-analyzer"))
);
const { generateNotes } = await import(
  pathToFileURL(require.resolve("@semantic-release/release-notes-generator"))
);
const semver = require("semver");
const logger = { log() {} };

export async function reconstruct(commits) {
  const releases = [];
  let pending = [];
  for (const commit of commits) {
    pending.push(commit);
    if (commit.merged) continue;
    const type = await analyzeCommits(analyzer, {
      commits: pending,
      cwd: process.cwd(),
      logger,
    });
    if (!type) continue;
    const lastRelease = releases.at(-1) || {};
    const version = lastRelease.version
      ? semver.inc(lastRelease.version, type)
      : "1.0.0";
    const nextRelease = {
      version,
      gitTag: `v${version}`,
      gitHead: commit.hash,
      date: commit.date,
    };
    const markdown = await generateNotes(
      {
        ...notes,
        writerOpts: {
          ...notes.writerOpts,
          finalizeContext: (context) => ({
            ...context,
            date: commit.date.slice(0, 10),
          }),
        },
      },
      {
        commits: pending,
        lastRelease,
        nextRelease,
        options: config,
        cwd: process.cwd(),
        logger,
      },
    );
    releases.push({ ...nextRelease, type, notes: markdown });
    pending = [];
  }
  return { releases, unreleased: pending };
}

function git(...args) {
  return execFileSync("git", args, {
    encoding: "utf8",
    maxBuffer: 64 * 1024 * 1024,
  });
}

async function main() {
  const [revision, destination] = process.argv.slice(2);
  if (!revision || !destination || process.argv.length !== 4) {
    throw new Error(
      "usage: node hack/reconstruct-releases.mjs <revision> <output-directory>",
    );
  }
  const head = git("rev-parse", "--verify", `${revision}^{commit}`).trim();
  const fields = git(
    "log",
    "--first-parent",
    "--reverse",
    "--format=%H%x00%cI%x00%B%x00%P%x00",
    head,
  ).split("\0");
  const commits = [];
  for (let i = 0; i + 3 < fields.length; i += 4) {
    const [hash, date, message, parents] = fields
      .slice(i, i + 4)
      .map((field) => field.trim());
    if (parents.split(" ").length > 1) {
      const merged = git(
        "log",
        "--reverse",
        "--format=%H%x00%cI%x00%B%x00",
        `${hash}^1..${hash}`,
      ).split("\0");
      for (let j = 0; j + 2 < merged.length; j += 3) {
        const [mergedHash, mergedDate, mergedMessage] = merged
          .slice(j, j + 3)
          .map((field) => field.trim());
        if (mergedHash !== hash)
          commits.push({
            hash: mergedHash,
            date: mergedDate,
            message: mergedMessage,
            merged: true,
          });
      }
    }
    commits.push({ hash, date, message });
  }
  const result = await reconstruct(commits);
  const existing = new Map(
    git("for-each-ref", "--format=%(refname:short) %(objectname)", "refs/tags")
      .trim()
      .split("\n")
      .filter(Boolean)
      .map((line) => line.split(" ")),
  );
  for (const release of result.releases) {
    if (
      existing.has(release.gitTag) &&
      git("rev-parse", `${release.gitTag}^{commit}`).trim() !== release.gitHead
    ) {
      throw new Error(
        `Existing tag conflicts with reconstruction: ${release.gitTag}`,
      );
    }
  }
  mkdirSync(destination, { recursive: true });
  writeFileSync(
    resolve(destination, "releases.json"),
    JSON.stringify({ head, ...result }, null, 2) + "\n",
  );
  writeFileSync(
    resolve(destination, "CHANGELOG.md"),
    "# Historical releases\n\nVersions are reconstructed from commit messages, not evidence of past deployment.\n\n" +
      result.releases
        .toReversed()
        .map((release) => release.notes)
        .join("\n"),
  );
  writeFileSync(
    resolve(destination, "tags.txt"),
    result.releases
      .filter((release) => !existing.has(release.gitTag))
      .map(
        (release) => `create refs/tags/${release.gitTag} ${release.gitHead}\n`,
      )
      .join(""),
  );
  process.stdout.write(
    JSON.stringify({
      head,
      commits: commits.length,
      releases: result.releases.length,
      latest: result.releases.at(-1)?.gitTag,
      unreleased: result.unreleased.length,
    }) + "\n",
  );
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(resolve(process.argv[1])).href
) {
  await main();
}
