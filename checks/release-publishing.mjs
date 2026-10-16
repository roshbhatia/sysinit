import assert from "node:assert/strict";
import test from "node:test";
import {
  batchSize,
  githubClient,
  publishBatch,
  releaseBody,
  validateManifest,
  verifyReleases,
  writeIntervalMs,
} from "../hack/publish-releases.mjs";

function release(index = 0) {
  return {
    version: `1.0.${index}`,
    gitTag: `v1.0.${index}`,
    gitHead: (index + 1).toString(16).padStart(40, "0"),
    date: "2020-01-02T12:00:00+00:00",
    notes: `## 1.0.${index}\n\nGenerated historical notes\n`,
  };
}

function published(item) {
  return {
    tag_name: item.gitTag,
    body: releaseBody(item),
    draft: false,
    prerelease: false,
  };
}

function fakeClient(existing = []) {
  const writes = [];
  const client = {
    listReleases: async () => [...existing, ...writes],
    latest: async () => ({ tag_name: "v3.113.1" }),
    ref: async (tag) => {
      const index = Number(tag.split(".").at(-1));
      return { object: { type: "commit", sha: release(index).gitHead } };
    },
    create: async (body) => {
      writes.push(body);
      return body;
    },
  };
  return { client, writes };
}

test("manifest rejects moved, missing, duplicate, and malformed tags", () => {
  const item = release();
  const tags = new Map([[item.gitTag, item.gitHead]]);
  validateManifest([item], tags);
  assert.throws(() => validateManifest([], tags), /empty/);
  assert.throws(() => validateManifest([item], new Map()), /target mismatch/);
  assert.throws(() => validateManifest([item, item], tags), /duplicate/);
  assert.throws(
    () => validateManifest([{ ...item, gitTag: "main" }], tags),
    /Invalid/,
  );
});

test("publishing resumes existing releases and preserves the latest marker", async () => {
  const items = [release(), release(1)];
  const { client, writes } = fakeClient([published(items[0])]);
  const result = await publishBatch(items, client, { index: 0, log() {} });
  assert.deepEqual(result, {
    batch: 0,
    total: 2,
    existing: 1,
    created: 1,
    planned: 0,
  });
  assert.equal(writes[0].make_latest, "false");
  assert.equal(writes[0].target_commitish, items[1].gitHead);
  assert.equal(writes[0].generate_release_notes, false);
  assert.equal(writes[0].body, releaseBody(items[1]));
  assert.match(writes[0].body, /Historical release reconstructed/);
  assert.deepEqual(await verifyReleases(items, client), {
    verified: 2,
    latest: "v3.113.1",
  });
});

test("plan mode and mismatched remote tags make no writes", async () => {
  const { client, writes } = fakeClient();
  const plan = await publishBatch([release()], client, {
    index: 0,
    plan: true,
  });
  assert.equal(plan.planned, 1);
  assert.equal(writes.length, 0);
  client.ref = async () => ({
    object: { type: "commit", sha: "0".repeat(40) },
  });
  await assert.rejects(
    publishBatch([release()], client, { index: 0 }),
    /Remote tag target mismatch/,
  );
  assert.equal(writes.length, 0);
});

test("batches never publish outside their selected range", async () => {
  const items = Array.from({ length: batchSize + 1 }, (_, index) =>
    release(index),
  );
  const { client, writes } = fakeClient();
  await publishBatch(items, client, { index: 1, log() {} });
  assert.deepEqual(
    writes.map((item) => item.tag_name),
    [items.at(-1).gitTag],
  );
  await assert.rejects(
    publishBatch(items, client, { index: 2 }),
    /Invalid batch/,
  );
});

test("verification rejects missing, draft, altered, and accidentally latest releases", async () => {
  const item = release();
  const { client, writes } = fakeClient();
  await assert.rejects(verifyReleases([item], client), /Missing release/);
  writes.push({ ...published(item), draft: true });
  await assert.rejects(verifyReleases([item], client), /differs/);
  writes[0] = { ...published(item), body: "someone else's notes" };
  await assert.rejects(verifyReleases([item], client), /differs/);
  writes[0] = published(item);
  client.latest = async () => ({ tag_name: item.gitTag });
  await assert.rejects(verifyReleases([item], client), /replaced the latest/);
});

test("writes respect spacing and GitHub retry-after without token-bearing redirects", async () => {
  let time = 0;
  const sleeps = [];
  const calls = [];
  const client = githubClient({
    token: "fixture-token",
    now: () => time,
    sleep: async (ms) => {
      sleeps.push(ms);
      time += ms;
    },
    log() {},
    fetchImpl: async (url, options) => {
      calls.push({ url, options, time });
      if (calls.length === 1) {
        return new globalThis.Response(
          JSON.stringify({ message: "secondary rate limit" }),
          {
            status: 403,
            headers: { "retry-after": "120" },
          },
        );
      }
      return new globalThis.Response("{}");
    },
  });
  await client.create({});
  await client.create({});
  assert.equal(calls[1].time - calls[0].time, 120_000);
  assert.equal(calls[2].time - calls[1].time, writeIntervalMs);
  assert.ok(sleeps.includes(120_000));
  assert.ok(
    calls.every(
      ({ url, options }) =>
        url.startsWith("https://api.github.com/") &&
        options.redirect === "error",
    ),
  );
});

test("unexpected HTTP failures stop instead of retrying writes", async () => {
  let calls = 0;
  const client = githubClient({
    token: "fixture-token",
    sleep: async () => {},
    fetchImpl: async () => {
      calls++;
      return new globalThis.Response(
        JSON.stringify({ message: "service failure" }),
        {
          status: 500,
        },
      );
    },
  });
  await assert.rejects(client.create({}), /500 service failure/);
  assert.equal(calls, 1);
});
