import type { Register, TurnStepChunk } from "claude-code";

export const register: Register = (on) => {
  on("turn.step", async function* ($, e, next) {
    if (e.agentId) return yield* next(e);
    const pending: TurnStepChunk[] = [];
    let passthrough = false;
    let size = 0;
    try {
      for await (const chunk of next(e)) {
        if (passthrough) {
          yield chunk;
          continue;
        }
        pending.push(chunk);
        if (chunk.kind === "text") size += chunk.text.length;
        if (chunk.kind === "tool" || size > 24000) {
          passthrough = true;
          yield* pending;
          pending.length = 0;
        }
      }
    } catch (error) {
      yield* pending;
      throw error;
    }
    if (passthrough) return;
    const stop = pending.findLast((chunk) => chunk.kind === "stop");
    if (stop?.kind === "stop" && stop.stopReason === "end_turn") {
      const texts = pending.filter((chunk) => chunk.kind === "text");
      // Keep separate content blocks and all engine handles in their original order.
      const indices = new Set(texts.map((chunk) => chunk.index));
      if (indices.size === 1) {
        const original = texts.map((chunk) => chunk.text).join("");
        try {
          const result = await $.process.run(["@rewriter@"], {
            stdin: JSON.stringify({ text: original }),
            timeoutMs: 16000,
          });
          if (result.exitCode === 0) {
            const reply: unknown = JSON.parse(result.stdout);
            if (
              typeof reply === "object" &&
              reply !== null &&
              "text" in reply &&
              typeof reply.text === "string"
            ) {
              let first = true;
              for (const chunk of pending) {
                if (chunk.kind === "text") {
                  yield { ...chunk, text: first ? reply.text : "" };
                  first = false;
                } else yield chunk;
              }
              return;
            }
          }
        } catch {
          $.ui.log("Output cleanup unavailable; kept the original response.", {
            to: "debug",
          });
        }
      }
    }
    yield* pending;
  });
};
