import type { Register } from "claude-code";

export const register: Register = (on) => {
  on("session.start", async ($, e, next) => {
    const result = await next(e);
    await $.command.register({
      name: "diff",
      description: "Open the worktree diff in a reusable Neovim split",
      immediate: true,
    });
    return result;
  });
  on("command.run", { command: "diff" }, async ($) => {
    const result = await $.process.run(["agent-diff"], { timeoutMs: 16000 });
    return {
      text: (result.exitCode === 0 ? result.stdout : result.stderr).trim(),
    };
  });
};
