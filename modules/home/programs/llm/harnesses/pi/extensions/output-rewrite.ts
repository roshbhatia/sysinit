import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { execFile } from "node:child_process";

function rewrite(text: string): Promise<string> {
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

export default function (pi: ExtensionAPI) {
  pi.on("message_end", async (event) => {
    const message = event.message;
    if (
      message.role !== "assistant" ||
      message.stopReason !== "stop" ||
      message.content.some((part) => part.type === "toolCall")
    )
      return;
    const texts = message.content.filter((part) => part.type === "text");
    if (texts.length !== 1) return;
    const text = await rewrite(texts[0].text);
    const content = message.content.map((part) =>
      part.type === "text" ? { ...part, text } : part,
    );
    return { message: { ...message, content } };
  });
}
