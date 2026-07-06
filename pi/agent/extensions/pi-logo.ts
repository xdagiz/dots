import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const RESET = "\x1b[0m";

// #c6a0f6
const COLOR = "\x1b[38;2;198;160;246m";

const TITLE_LINES = [
  "  ███████    ",
  "  ██   ██    ",
  "  █████  ██  ",
  "  ██     ██  "
];

function colorText(text: string) {
  return text.replace(/█/g, `${COLOR}█${RESET}`);
}

export default function piLogoExtension(pi: ExtensionAPI) {
  pi.on("session_start", (_event, ctx: ExtensionContext) => {
    if (ctx.mode !== "tui") return;

    ctx.ui.setHeader(() => ({
      render(_width: number) {
        const art = TITLE_LINES.map(colorText);
        return ["", ...art, ""];
      },
      invalidate() {},
    }));
  });

  pi.on("session_shutdown", (_event, ctx: ExtensionContext) => {
    if (ctx.mode === "tui") {
      ctx.ui.setHeader(undefined);
    }
  });
}
