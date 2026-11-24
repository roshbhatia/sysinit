import { test, expect } from "bun:test";
import { register } from "./claude.ts";
import { transformSSE } from "./opencode.ts";

test("Claude rewrites visible and recorded text, preserving stream handles", async () => {
  const hooks = new Map();
  register((name, ...args) => hooks.set(name, args.at(-1)));
  const chunks = [
    { kind: "engine", ref: 0 },
    { kind: "text", index: 0, text: "Basically, ", ref: 1 },
    { kind: "text", index: 0, text: "done.", ref: 2 },
    { kind: "stop", stopReason: "end_turn", usage: null, ref: 3 },
  ];
  let calls = 0;
  const $ = {
    process: {
      run: async () => {
        calls++;
        return { exitCode: 0, stdout: JSON.stringify({ text: "Done." }) };
      },
    },
    ui: { log() {} },
  };
  const output = [];
  for await (const c of hooks.get("turn.step")($, {}, async function* () {
    yield* chunks;
  }))
    output.push(c);
  expect(calls).toBe(1);
  expect(output.map((c) => c.text ?? "").join("")).toBe("Done.");
  expect(output.map((c) => c.ref)).toEqual([0, 1, 2, 3]);
  chunks.splice(2, 0, { kind: "tool", index: 1, name: "Bash", id: "x" });
  const bypass = [];
  for await (const c of hooks.get("turn.step")($, {}, async function* () {
    yield* chunks;
  }))
    bypass.push(c);
  expect(bypass).toEqual(chunks);
  expect(calls).toBe(1);
});

test("Claude process failure returns the original and does not request a retry", async () => {
  let handler;
  register((name, ...args) => {
    if (name === "turn.step") handler = args.at(-1);
  });
  const chunks = [
    { kind: "text", index: 0, text: "Original." },
    { kind: "stop", stopReason: "end_turn", usage: null },
  ];
  const output = [];
  for await (const c of handler(
    {
      process: {
        run: async () => {
          throw Error("timeout");
        },
      },
      ui: { log() {} },
    },
    {},
    async function* () {
      yield* chunks;
    },
  ))
    output.push(c);
  expect(output).toEqual(chunks);
});

const sse = (items) =>
  items.map((item) => "data: " + JSON.stringify(item) + "\n\n").join("");
test("OpenCode Anthropic and Chat text changes retain usage and protocol fields", async () => {
  const source = sse([
    {
      type: "content_block_delta",
      index: 0,
      delta: { type: "text_delta", text: "Wordy." },
    },
    {
      type: "message_delta",
      delta: { stop_reason: "end_turn" },
      usage: { output_tokens: 7 },
    },
  ]);
  const result = await transformSSE(source, async () => "Short.");
  expect(result).toContain("Short.");
  expect(result).toContain('"output_tokens":7');
  expect(result).not.toContain("Wordy.");
  const chat =
    sse([
      { choices: [{ index: 0, delta: { content: "Wordy." } }] },
      { choices: [{ index: 0, finish_reason: "stop", delta: {} }] },
    ]) + "data: [DONE]\n\n";
  expect(await transformSSE(chat, async () => "Short.")).toContain("Short.");
});
test("OpenCode Responses changes delta and completed representations together", async () => {
  const source = sse([
    {
      type: "response.output_text.delta",
      output_index: 0,
      content_index: 0,
      delta: "Wordy.",
    },
    { type: "response.output_text.done", text: "Wordy." },
    {
      type: "response.completed",
      response: {
        status: "completed",
        output: [
          {
            type: "message",
            content: [{ type: "output_text", text: "Wordy." }],
          },
        ],
      },
    },
  ]);
  const result = await transformSSE(source, async () => "Short.");
  expect(result).not.toContain("Wordy.");
  expect(result.match(/Short\./g).length).toBe(3);
});
test("OpenCode leaves tool calls, partial streams and unknown formats untouched", async () => {
  const source = sse([
    { type: "content_block_start", content_block: { type: "tool_use" } },
    {
      type: "content_block_delta",
      index: 0,
      delta: { type: "text_delta", text: "Wordy." },
    },
    { type: "message_delta", delta: { stop_reason: "end_turn" } },
  ]);
  const edit = () => {
    throw Error("must not run");
  };
  expect(await transformSSE(source, edit)).toBe(source);
  expect(await transformSSE('data: {"choices":[]}\n\n', edit)).toBe(
    'data: {"choices":[]}\n\n',
  );
  expect(await transformSSE("unknown", edit)).toBe("unknown");
});
