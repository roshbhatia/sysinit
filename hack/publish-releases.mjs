import { execFileSync } from "node:child_process";
import console from "node:console";
import { appendFileSync, readFileSync } from "node:fs";
import { setTimeout as wait } from "node:timers/promises";
import { pathToFileURL } from "node:url";

const repository = "roshbhatia/sysinit";
export const batchSize = 450;
export const writeIntervalMs = 8_000;

export function releaseBody(release) {
  return `Historical release reconstructed from Git history. Commit date: ${release.date}.\n\n${release.notes}`;
}

export function validateManifest(releases, tags) {
  if (!Array.isArray(releases) || releases.length === 0) {
    throw new Error("Release manifest is empty");
  }
  const seen = new Set();
  for (const release of releases) {
    if (
      !/^\d+\.\d+\.\d+$/.test(release.version) ||
      release.gitTag !== `v${release.version}` ||
      !/^[a-f0-9]{40}$/.test(release.gitHead) ||
      !Number.isFinite(Date.parse(release.date)) ||
      typeof release.notes !== "string" ||
      !release.notes.trim() ||
      seen.has(release.gitTag)
    ) {
      throw new Error(`Invalid or duplicate release: ${release.gitTag}`);
    }
    if (tags.get(release.gitTag) !== release.gitHead) {
      throw new Error(`Tag target mismatch: ${release.gitTag}`);
    }
    seen.add(release.gitTag);
  }
}

function validatePublished(actual, expected) {
  const normalize = (body) => body?.replaceAll("\r\n", "\n").trim();
  if (
    actual.tag_name !== expected.gitTag ||
    actual.draft ||
    actual.prerelease ||
    normalize(actual.body) !== normalize(releaseBody(expected))
  ) {
    throw new Error(
      `Existing release differs from the manifest: ${expected.gitTag}`,
    );
  }
}

export function githubClient({
  token,
  fetchImpl = globalThis.fetch,
  sleep = wait,
  now = Date.now,
  log = console.log,
}) {
  if (!token) throw new Error("GH_TOKEN or GITHUB_TOKEN is required");
  let lastWrite = -Infinity;

  async function request(method, path, body) {
    for (let attempt = 0; ; attempt++) {
      if (method !== "GET") {
        await sleep(Math.max(0, lastWrite + writeIntervalMs - now()));
        lastWrite = now();
      }
      const response = await fetchImpl(`https://api.github.com${path}`, {
        method,
        redirect: "error",
        signal: globalThis.AbortSignal.timeout(30_000),
        headers: {
          Authorization: `Bearer ${token}`,
          Accept: "application/vnd.github+json",
          "X-GitHub-Api-Version": "2026-03-10",
          "Content-Type": "application/json",
          "User-Agent": "sysinit-release-backfill",
        },
        body: body === undefined ? undefined : JSON.stringify(body),
      });
      const result = await response.json();
      if (response.ok) return result;

      const retryAfter = response.headers.get("retry-after");
      const rateLimited =
        response.status === 429 ||
        (response.status === 403 &&
          (retryAfter !== null || /rate limit/i.test(result.message)));
      if (!rateLimited || attempt >= 5) {
        throw new Error(
          `GitHub ${method} ${path}: ${response.status} ${result.message}`,
        );
      }
      const reset = Number(response.headers.get("x-ratelimit-reset")) * 1_000;
      const retryMs = retryAfter
        ? /^\d+$/.test(retryAfter)
          ? Number(retryAfter) * 1_000
          : Date.parse(retryAfter) - now()
        : 0;
      const waitMs = Math.max(
        60_000 * 2 ** attempt,
        retryMs || 0,
        response.headers.get("x-ratelimit-remaining") === "0"
          ? reset - now()
          : 0,
      );
      log(`GitHub rate limit: waiting ${Math.ceil(waitMs / 1_000)} seconds`);
      await sleep(waitMs);
    }
  }

  const prefix = `/repos/${repository}`;
  return {
    async listReleases() {
      const releases = [];
      for (let page = 1; ; page++) {
        const entries = await request(
          "GET",
          `${prefix}/releases?per_page=100&page=${page}`,
        );
        releases.push(...entries);
        if (entries.length < 100) return releases;
      }
    },
    latest: () => request("GET", `${prefix}/releases/latest`),
    ref: (tag) =>
      request("GET", `${prefix}/git/ref/tags/${encodeURIComponent(tag)}`),
    create: (body) => request("POST", `${prefix}/releases`, body),
  };
}

export async function publishBatch(
  releases,
  client,
  { index, plan = false, log = console.log },
) {
  if (
    !Number.isInteger(index) ||
    index < 0 ||
    index >= Math.ceil(releases.length / batchSize)
  ) {
    throw new Error("Invalid batch index");
  }
  const existing = new Map(
    (await client.listReleases()).map((item) => [item.tag_name, item]),
  );
  const selected = releases.slice(index * batchSize, (index + 1) * batchSize);
  const result = {
    batch: index,
    total: selected.length,
    existing: 0,
    created: 0,
    planned: 0,
  };
  for (const release of selected) {
    const previous = existing.get(release.gitTag);
    if (previous) {
      validatePublished(previous, release);
      result.existing++;
      continue;
    }
    if (plan) {
      result.planned++;
      continue;
    }
    const ref = await client.ref(release.gitTag);
    if (ref.object.type !== "commit" || ref.object.sha !== release.gitHead) {
      throw new Error(`Remote tag target mismatch: ${release.gitTag}`);
    }
    const created = await client.create({
      tag_name: release.gitTag,
      target_commitish: release.gitHead,
      name: release.gitTag,
      body: releaseBody(release),
      draft: false,
      prerelease: false,
      generate_release_notes: false,
      make_latest: "false",
    });
    validatePublished(created, release);
    result.created++;
    log(
      `Published ${release.gitTag}: ${result.created} created, ${result.existing} already present`,
    );
  }
  return result;
}

export async function verifyReleases(releases, client) {
  const existing = new Map(
    (await client.listReleases()).map((item) => [item.tag_name, item]),
  );
  for (const release of releases) {
    const actual = existing.get(release.gitTag);
    if (!actual) throw new Error(`Missing release: ${release.gitTag}`);
    validatePublished(actual, release);
  }
  const latest = await client.latest();
  if (releases.some((release) => release.gitTag === latest.tag_name)) {
    throw new Error(
      `Historical release replaced the latest release: ${latest.tag_name}`,
    );
  }
  return { verified: releases.length, latest: latest.tag_name };
}

async function main() {
  const [manifest, mode, batch] = process.argv.slice(2);
  if (
    !manifest ||
    !["--batch", "--plan", "--verify"].includes(mode) ||
    process.argv.length !== (mode === "--verify" ? 4 : 5)
  ) {
    throw new Error(
      "usage: node hack/publish-releases.mjs <manifest> <--batch INDEX|--plan INDEX|--verify>",
    );
  }
  const { releases } = JSON.parse(readFileSync(manifest, "utf8"));
  const refs = execFileSync(
    "git",
    [
      "for-each-ref",
      "--format=%(refname:strip=2)%00%(objectname)%00%(*objectname)",
      "refs/tags",
    ],
    { encoding: "utf8", maxBuffer: 4 * 1024 * 1024 },
  );
  const tags = new Map(
    refs
      .trim()
      .split("\n")
      .map((line) => {
        const [tag, sha, peeled] = line.split("\0");
        return [tag, peeled || sha];
      }),
  );
  validateManifest(releases, tags);
  const client = githubClient({
    token: process.env.GH_TOKEN || process.env.GITHUB_TOKEN,
  });
  const result =
    mode === "--verify"
      ? await verifyReleases(releases, client)
      : await publishBatch(releases, client, {
          index: Number(batch),
          plan: mode === "--plan",
        });
  console.log(JSON.stringify(result));
  if (process.env.GITHUB_STEP_SUMMARY) {
    appendFileSync(
      process.env.GITHUB_STEP_SUMMARY,
      `Release backfill: \`${JSON.stringify(result)}\`\n`,
    );
  }
}

if (
  process.argv[1] &&
  import.meta.url === pathToFileURL(process.argv[1]).href
) {
  await main();
}
