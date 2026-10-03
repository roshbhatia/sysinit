import type { Plugin } from "@opencode/plugin";
import { execFile } from "node:child_process";

export async function rewrite(text: string): Promise<string> {
  return new Promise((resolve) => {
    const child = execFile(
      "@rewriter@",
      [],
      { timeout: 16000, maxBuffer: 1024 * 1024 },
      (error, stdout) => {
        if (error) return resolve(text);
        try {
          const reply: unknown = JSON.parse(stdout);
          resolve(
            typeof reply === "object" &&
              reply !== null &&
              "text" in reply &&
              typeof reply.text === "string"
              ? reply.text
              : text,
          );
        } catch {
          resolve(text);
        }
      },
    );
    child.stdin?.on("error", () => {});
    child.stdin?.end(JSON.stringify({ text }));
  });
}

type RecordValue = Record<string, unknown>;
function record(value: unknown): value is RecordValue {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

export async function transformSSE(
  source: string,
  edit: (text: string) => Promise<string>,
): Promise<string> {
  const frames = source.split(/\r?\n\r?\n/);
  const pieces: { owner: RecordValue; key: string; text: string }[] = [];
  const parsed: { lines: string[]; index: number; value: RecordValue }[] = [];
  const blocks = new Set<string>();
  const completed: { owner: RecordValue; key: string }[] = [];
  let ended = false;
  let tool = false;
  for (const frame of frames) {
    const lines = frame.split(/\r?\n/);
    const indices = lines.flatMap((line, i) =>
      line.startsWith("data:") ? [i] : [],
    );
    if (frame.trim() === "") continue;
    if (indices.length !== 1) return source;
    const index = indices[0];
    const data = lines[index].slice(5).trim();
    if (!data || data === "[DONE]") continue;
    let value: unknown;
    try {
      value = JSON.parse(data);
    } catch {
      return source;
    }
    if (!record(value)) return source;
    parsed.push({ lines, index, value });
    if (
      value.type === "content_block_start" &&
      record(value.content_block) &&
      value.content_block.type === "text" &&
      value.content_block.text
    )
      return source;
    if (
      value.type === "response.output_item.added" &&
      record(value.item) &&
      typeof value.item.type === "string" &&
      value.item.type.endsWith("_call")
    )
      tool = true;
    if (
      value.type === "response.output_text.delta" &&
      typeof value.delta === "string"
    ) {
      pieces.push({ owner: value, key: "delta", text: value.delta });
      blocks.add(`responses:${value.output_index}:${value.content_index}`);
    }
    if (
      value.type === "response.output_text.done" &&
      typeof value.text === "string"
    )
      completed.push({ owner: value, key: "text" });
    if (
      value.type === "response.content_part.done" &&
      record(value.part) &&
      value.part.type === "output_text"
    )
      completed.push({ owner: value.part, key: "text" });
    const items =
      value.type === "response.output_item.done"
        ? [value.item]
        : value.type === "response.completed" &&
            record(value.response) &&
            Array.isArray(value.response.output)
          ? value.response.output
          : [];
    for (const item of items) {
      if (!record(item)) continue;
      if (typeof item.type === "string" && item.type.endsWith("_call"))
        tool = true;
      if (item.type === "message" && Array.isArray(item.content)) {
        for (const part of item.content) {
          if (
            record(part) &&
            part.type === "output_text" &&
            typeof part.text === "string"
          )
            completed.push({ owner: part, key: "text" });
        }
      }
    }
    if (
      value.type === "response.completed" &&
      record(value.response) &&
      value.response.status === "completed"
    )
      ended = true;
    if (
      value.type === "content_block_start" &&
      record(value.content_block) &&
      value.content_block.type === "tool_use"
    )
      tool = true;
    if (
      value.type === "content_block_delta" &&
      record(value.delta) &&
      value.delta.type === "text_delta" &&
      typeof value.delta.text === "string"
    ) {
      pieces.push({ owner: value.delta, key: "text", text: value.delta.text });
      blocks.add(String(value.index));
    }
    if (
      value.type === "message_delta" &&
      record(value.delta) &&
      value.delta.stop_reason === "end_turn"
    )
      ended = true;
    if (Array.isArray(value.choices)) {
      for (const choice of value.choices) {
        if (
          !record(choice) ||
          (choice.index !== undefined && choice.index !== 0)
        )
          return source;
        if (record(choice.delta)) {
          if (choice.delta.tool_calls || choice.delta.function_call)
            tool = true;
          if (typeof choice.delta.content === "string") {
            pieces.push({
              owner: choice.delta,
              key: "content",
              text: choice.delta.content,
            });
            blocks.add("chat");
          }
        }
        if (choice.finish_reason === "stop") ended = true;
      }
    }
  }
  if (!ended || tool || blocks.size !== 1 || pieces.length === 0) return source;
  const original = pieces.map((piece) => piece.text).join("");
  if (completed.some(({ owner, key }) => owner[key] !== original))
    return source;
  const text = await edit(original);
  completed.forEach(({ owner, key }) => {
    owner[key] = text;
  });
  pieces.forEach((piece, index) => {
    piece.owner[piece.key] = index === 0 ? text : "";
  });
  let position = 0;
  return frames
    .map((frame) => {
      const next = parsed[position];
      if (!next || next.lines.join("\n") !== frame.replaceAll("\r\n", "\n"))
        return frame;
      position++;
      next.lines[next.index] = `data: ${JSON.stringify(next.value)}`;
      return next.lines.join("\n");
    })
    .join("\n\n");
}

export default {
  id: "sysinit.output",
  async setup(ctx) {
    await ctx.session.hook("http.response", (event) => {
      if (
        event.kind !== "primary" ||
        !event.response.ok ||
        !event.response.headers
          .get("content-type")
          ?.includes("text/event-stream") ||
        !event.response.body
      )
        return;
      const original = event.response;
      const body = original.body;
      if (!body) return;
      const reader = body.getReader();
      const stream = new ReadableStream<Uint8Array>({
        async start(controller) {
          const chunks: Uint8Array[] = [];
          let size = 0;
          let passthrough = false;
          try {
            while (true) {
              const next = await reader.read();
              if (next.done) break;
              if (passthrough) {
                controller.enqueue(next.value);
                continue;
              }
              chunks.push(next.value);
              size += next.value.length;
              if (size > 256000) {
                passthrough = true;
                chunks.forEach((chunk) => controller.enqueue(chunk));
                chunks.length = 0;
              }
            }
            if (!passthrough) {
              const bytes = new Uint8Array(size);
              let offset = 0;
              for (const chunk of chunks) {
                bytes.set(chunk, offset);
                offset += chunk.length;
              }
              const text = new TextDecoder().decode(bytes);
              controller.enqueue(
                new TextEncoder().encode(await transformSSE(text, rewrite)),
              );
            }
            controller.close();
          } catch (error) {
            controller.error(error);
          } finally {
            reader.releaseLock();
          }
        },
        cancel(reason) {
          return reader.cancel(reason);
        },
      });
      const headers = new Headers(original.headers);
      headers.delete("content-length");
      headers.delete("content-encoding");
      event.response = new Response(stream, {
        status: original.status,
        statusText: original.statusText,
        headers,
      });
    });
  },
} satisfies Plugin.Plugin;
