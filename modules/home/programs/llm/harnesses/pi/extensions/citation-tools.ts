import type {
  ExtensionAPI,
  ExtensionContext,
} from "@earendil-works/pi-coding-agent";

interface RuntimeContext {
  cwd?: string;
  ui?: { notify?(message: string, level: "info" | "warning"): void };
}

const runtime = (ctx: ExtensionContext): RuntimeContext =>
  ctx as unknown as RuntimeContext;

async function run(
  pi: ExtensionAPI,
  cwd: string,
  command: string,
): Promise<string> {
  const result = await pi.exec("sh", [
    "-c",
    `cd ${JSON.stringify(cwd)} && ${command}`,
  ]);
  const out = [result.stdout, result.stderr].filter(Boolean).join("\n").trim();
  return out || "(no output)";
}

async function deliver(
  pi: ExtensionAPI,
  title: string,
  body: string,
): Promise<void> {
  await pi.sendUserMessage(`${title}\n\n\`\`\`\n${body}\n\`\`\``, {
    deliverAs: "followUp",
  });
}

export default function (pi: ExtensionAPI): void {
  pi.registerCommand("cite", {
    description:
      "citelock capture <url> --id <id> --quote <text> --class <class>",
    handler: async (args, ctx) => {
      const rt = runtime(ctx);
      const cwd = rt.cwd;
      if (!cwd) return;
      const rest = args?.trim();
      if (!rest) {
        rt.ui?.notify?.(
          "Usage: /cite <url> --id <id> --quote <text> --class <class>",
          "warning",
        );
        return;
      }
      await deliver(
        pi,
        `citelock capture ${rest}`,
        await run(pi, cwd, `citelock capture ${rest}`),
      );
    },
  });
}
