import { test, expect } from "bun:test";
import register, { classify } from "./fm-router.ts";
import { access } from "node:fs/promises";
function setup(label = "simple") {
  let router;
  let calls = 0;
  let schema;
  const api = {
    registerVirtualModel(value) {
      router = value;
    },
    async exec(command, args) {
      calls++;
      schema = args[args.indexOf("--schema") + 1];
      return {
        code: 0,
        stdout: JSON.stringify({ complexity: label }),
        stderr: "",
        killed: false,
      };
    },
  };
  register(api);
  const ctx = {
    modelRegistry: {
      find(provider, id) {
        return { provider, id };
      },
    },
    ui: { notify() {} },
  };
  const req = {
    reason: "user",
    messages: [{ role: "user", content: "Fix typo" }],
    thinkingLevel: "high",
    signal: new globalThis.AbortController().signal,
  };
  return { router, ctx, req, api, calls: () => calls, schema: () => schema };
}
test("simple planning, first successful edit, persisted implementation, direct request", async () => {
  const s = setup();
  const first = await s.router.route(s.req, s.ctx);
  expect(first.model.id).toBe("gpt-5.6-terra");
  const failure = await s.router.route(
    {
      ...s.req,
      reason: "continuation",
      state: first.state,
      messages: [
        ...s.req.messages,
        { role: "toolResult", toolName: "edit", isError: true },
      ],
    },
    s.ctx,
  );
  expect(failure.model.id).toBe("gpt-5.6-terra");
  const second = await s.router.route(
    {
      ...s.req,
      reason: "continuation",
      state: first.state,
      messages: [
        ...s.req.messages,
        { role: "toolResult", toolName: "write", isError: false },
      ],
    },
    s.ctx,
  );
  expect(second.model.id).toBe("gpt-5.6-luna");
  const third = await s.router.route({ ...s.req, state: second.state }, s.ctx);
  expect(third.model.id).toBe("gpt-5.6-luna");
  expect(s.calls()).toBe(1);
  const direct = await s.router.route({ ...s.req, reason: "direct" }, s.ctx);
  expect(direct.model.id).toBe("gpt-5.6-luna");
  expect(s.calls()).toBe(1);
  expect(direct.thinkingLevel).toBe("high");
  await expect(access(s.schema())).rejects.toThrow();
});
test("complex tasks route to sol", async () => {
  const s = setup("complex");
  expect((await s.router.route(s.req, s.ctx)).model.id).toBe("gpt-5.6-sol");
});
test("invalid classification fails and cleans temporary file", async () => {
  const s = setup("invalid");
  await expect(classify(s.api, "x", s.req.signal)).rejects.toThrow(
    "invalid complexity",
  );
  await expect(access(s.schema())).rejects.toThrow();
});
test("cancellation avoids invoking the CLI", async () => {
  const s = setup();
  const c = new globalThis.AbortController();
  c.abort();
  await expect(classify(s.api, "x", c.signal)).rejects.toThrow();
  expect(s.calls()).toBe(0);
});
