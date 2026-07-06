import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { Text } from "@earendil-works/pi-tui";

interface DoneTimerData {
  elapsed: string;
  timestamp: number;
}

function formatDuration(ms: number): string {
  if (ms < 1000) return `${ms}ms`;
  if (ms < 60_000) return `${(ms / 1000).toFixed(1)}s`;
  const m = Math.floor(ms / 60_000);
  const s = Math.floor((ms % 60_000) / 1000);
  return `${m}m ${s}s`;
}

export default function doneTimerExtension(pi: ExtensionAPI) {
  let startTime = 0;

  pi.registerEntryRenderer<DoneTimerData>("done-timer", (entry, _options, theme) => {
    const data = entry.data ?? { elapsed: "?s", timestamp: Date.now() };
    return new Text(theme.fg("thinkingText", `Done in ${data.elapsed}`), 1, 0);
  });

  pi.on("turn_start", () => {
    if (startTime === 0) {
      startTime = Date.now();
    }
  });

  pi.on("agent_settled", () => {
    if (startTime > 0) {
      const elapsed = Date.now() - startTime;
      pi.appendEntry<DoneTimerData>("done-timer", {
        elapsed: formatDuration(elapsed),
        timestamp: Date.now(),
      });
    }
    startTime = 0;
  });
}
