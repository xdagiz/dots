import net from "node:net";
import { isAbsolute } from "node:path";
import type { ExtensionAPI, ExtensionContext } from "@earendil-works/pi-coding-agent";

const HERDR_ENV = process.env.HERDR_ENV;
const socketPath = process.env.HERDR_SOCKET_PATH;
const paneId = process.env.HERDR_PANE_ID;
const source = "herdr:pi";
const MAX_ERROR_CHARS = 120;

const enabled = () => HERDR_ENV === "1" && !!socketPath && !!paneId;

const sendRequestAttempt = (request: unknown, timeoutMs: number) => {
  if (!enabled()) return Promise.resolve(true);
  return new Promise((resolve) => {
    let done = false;
    let timeout: ReturnType<typeof setTimeout> | undefined;

    const finish = (delivered: boolean) => {
      if (done) return;
      done = true;

      if (timeout) clearTimeout(timeout);

      socket.destroy();
      resolve(delivered);
    };

    const socket = net.createConnection(socketPath!);
    socket.on("error", () => finish(false));
    socket.on("connect", () => socket.write(`${JSON.stringify(request)}\n`));
    socket.on("data", () => finish(true));
    socket.on("end", () => finish(false));

    timeout = setTimeout(() => finish(false), timeoutMs);
    timeout.unref?.();
  });
};

const sendRequest = async (request: unknown) => {
  if (await sendRequestAttempt(request, 500)) return;
  await sendRequestAttempt(request, 1500);
};

type AgentState = "working" | "blocked" | "idle";

type OutboxItem =
  | { kind: "state"; state: AgentState; message?: string }
  | { kind: "session"; sessionStartSource?: string };

type BlockSource = "herdr" | "prompt" | "ui" | "error";

type HerdrBlockedPayload = {
  active?: unknown;
  label?: unknown;
};

type AskUserPromptPayload = {
  questions?: Array<{ header?: unknown }>;
};

type AskUserBlockedPayload = {
  active?: unknown;
};

let reportSeq = Date.now() * 1000;
let currentAgentSessionId: string | undefined;
let currentAgentSessionPath: string | undefined;
let sendInFlight = false;

const nextReportSeq = () => {
  reportSeq += 1;
  return reportSeq;
};

const updateSessionRef = (ctx: ExtensionContext) => {
  try {
    const file = ctx?.sessionManager?.getSessionFile?.();
    currentAgentSessionPath = typeof file === "string" && isAbsolute(file) ? file : undefined;
  } catch {
    currentAgentSessionPath = undefined;
  }

  try {
    const id = ctx?.sessionManager?.getSessionId?.();
    currentAgentSessionId = typeof id === "string" && id.length > 0 ? id : undefined;
  } catch {
    currentAgentSessionId = undefined;
  }
};

const withSessionRef = (params: Record<string, unknown>) => {
  if (currentAgentSessionPath) {
    return {
      ...params,
      agent_session_path: currentAgentSessionPath,
    };
  }

  if (currentAgentSessionId) {
    return {
      ...params,
      agent_session_id: currentAgentSessionId,
    };
  }

  return params;
};

const currentSessionRef = () => {
  if (currentAgentSessionPath) {
    return {
      agent_session_path: currentAgentSessionPath,
    };
  }

  if (currentAgentSessionId) {
    return {
      agent_session_id: currentAgentSessionId,
    };
  }

  return undefined;
};

const requestId = (prefix: string) =>
  `${source}:${prefix}:${Date.now()}:${Math.random().toString(36).slice(2)}`;

const sendState = (state: AgentState, message?: string) => {
  const params: Record<string, unknown> = withSessionRef({
    pane_id: paneId,
    source,
    agent: "pi",
    state,
    seq: nextReportSeq(),
  });

  if (message !== undefined) params.message = message;
  return sendRequest({
    id: requestId("state"),
    method: "pane.report_agent",
    params,
  });
};

const sendSession = (sessionStartSource?: string) => {
  const sessionRef = currentSessionRef();
  if (!sessionRef) return Promise.resolve();

  const params: Record<string, unknown> = {
    pane_id: paneId,
    source,
    agent: "pi",
    seq: nextReportSeq(),
    ...sessionRef,
  };

  if (sessionStartSource !== undefined) params.session_start_source = sessionStartSource;
  return sendRequest({
    id: requestId("session"),
    method: "pane.report_agent_session",
    params,
  });
};

const outbox: OutboxItem[] = [];

const enqueue = (item: OutboxItem) => {
  if (item.kind === "state") {
    for (let i = outbox.length - 1; i >= 0; i -= 1) {
      if (outbox[i].kind === "state") outbox.splice(i, 1);
    }
  }

  outbox.push(item);
  if (!sendInFlight) void drainQueue();
};

const queueState = (state: AgentState, message?: string) => {
  enqueue({ kind: "state", state, message });
};

const queueSession = (sessionStartSource?: string) => {
  enqueue({ kind: "session", sessionStartSource });
};

async function drainQueue(): Promise<void> {
  if (sendInFlight) return;

  sendInFlight = true;
  try {
    while (outbox.length > 0) {
      const next = outbox.shift();
      if (!next) break;
      if (next.kind === "state") await sendState(next.state, next.message);
      else await sendSession(next.sessionStartSource);
    }
  } finally {
    sendInFlight = false;
    if (outbox.length > 0) void drainQueue();
  }
}

const truncateError = (text: string) => {
  const clean = text.trim() || "An error occurred";
  if (clean.length <= MAX_ERROR_CHARS) return clean;
  return `${clean.slice(0, MAX_ERROR_CHARS - 3)}...`;
};

const asLabel = (value: unknown) =>
  typeof value === "string" && value.length > 0 ? value : undefined;

export default function (pi: ExtensionAPI) {
  if (!enabled()) return;

  let agentActive = false;
  let subagentCount = 0;
  let questionLabel: string | undefined;
  let lastState: AgentState | undefined;
  let lastMessage: string | undefined;
  let rootSession = false;
  let lastError: string | undefined;
  let errorReported = false;

  const blocks = new Map<BlockSource, { count: number; label?: string }>();
  const blockPriority: BlockSource[] = ["error", "herdr", "prompt", "ui"];

  const isBlocked = () => {
    for (const entry of blocks.values()) if (entry.count > 0) return true;
    return false;
  };

  const activeBlockLabel = () => {
    for (const key of blockPriority) {
      const entry = blocks.get(key);
      if (entry && entry.count > 0) return entry.label;
    }
    return undefined;
  };

  const desiredState = () => {
    if (isBlocked()) return { state: "blocked" as const, message: activeBlockLabel() };
    if (agentActive) return { state: "working" as const, message: undefined };
    if (subagentCount > 0) {
      return {
        state: "working" as const,
        message: `${subagentCount} subagent${subagentCount === 1 ? "" : "s"}`,
      };
    }
    return { state: "idle" as const, message: undefined };
  };

  function publishState(force = false) {
    const next = desiredState();
    if (!force && next.state === lastState && next.message === lastMessage) return;
    lastState = next.state;
    lastMessage = next.message;
    queueState(next.state, next.message);
  }

  const addBlock = (origin: BlockSource, label?: string) => {
    const entry = blocks.get(origin);
    if (entry) {
      entry.count += 1;
      if (label !== undefined) entry.label = label;
    } else {
      blocks.set(origin, { count: 1, label });
    }
    publishState();
  };

  const setBlockLabel = (origin: BlockSource, label: string) => {
    const entry = blocks.get(origin);
    if (!entry) {
      blocks.set(origin, { count: 1, label });
    } else {
      entry.label = label;
    }
    publishState();
  };

  const removeBlock = (origin: BlockSource) => {
    const entry = blocks.get(origin);
    if (!entry) return;
    entry.count -= 1;
    if (entry.count <= 0) blocks.delete(origin);
    publishState();
  };

  const clearBlocks = (origins: BlockSource[]) => {
    let changed = false;
    for (const origin of origins) if (blocks.delete(origin)) changed = true;
    if (changed) publishState();
  };

  pi.events.on("herdr:blocked", (data) => {
    if (!rootSession) return;
    const payload = data as HerdrBlockedPayload;
    if (!payload?.active) {
      removeBlock("herdr");
    } else {
      addBlock("herdr", asLabel(payload?.label));
    }
  });

  pi.events.on("rpiv:ask-user:prompt", (data) => {
    if (!rootSession) return;
    const payload = data as AskUserPromptPayload;
    questionLabel = asLabel(payload?.questions?.[0]?.header);
  });

  pi.events.on("rpiv:ask-user:blocked", (data) => {
    if (!rootSession) return;
    const payload = data as AskUserBlockedPayload;
    const active = !!payload?.active;
    if (active) {
      addBlock("prompt", questionLabel ?? "question");
    } else {
      removeBlock("prompt");
      questionLabel = undefined;
    }
  });

  pi.on("ui_prompt_start", (event) => {
    if (!rootSession) return;
    addBlock("ui", asLabel(event?.title) ?? asLabel(event?.kind) ?? "prompt");
  });

  pi.on("ui_prompt_end", () => {
    if (!rootSession) return;
    removeBlock("ui");
  });

  const subagentStarted = () => {
    if (!rootSession) return;
    subagentCount += 1;
    publishState();
  };

  const subagentFinished = () => {
    if (!rootSession) return;
    subagentCount = Math.max(0, subagentCount - 1);
    publishState();
  };

  pi.events.on("subagents:started", subagentStarted);
  pi.events.on("subagents:completed", subagentFinished);
  pi.events.on("subagents:failed", subagentFinished);

  pi.on("session_start", (event, ctx) => {
    if (ctx?.mode !== "tui") return;

    rootSession = true;
    updateSessionRef(ctx);
    subagentCount = 0;
    questionLabel = undefined;
    clearBlocks(["prompt", "ui"]);
    queueSession(event?.reason);

    agentActive = ctx?.isIdle?.() === false;
    publishState(true);
  });

  pi.on("message_end", (event) => {
    if (!rootSession) return;
    if (event.message.role !== "assistant") return;
    if (event.message.stopReason === "error") {
      lastError = event.message.errorMessage?.trim() || "An error occurred";
      const label = `error: ${truncateError(lastError)}`;
      if (!errorReported) {
        errorReported = true;
        addBlock("error", label);
      } else {
        setBlockLabel("error", label);
      }
    } else {
      lastError = undefined;
    }
  });

  pi.on("agent_start", (_event, ctx) => {
    if (!rootSession) return;
    updateSessionRef(ctx);
    queueSession();
    clearBlocks(["error"]);
    lastError = undefined;
    errorReported = false;
    agentActive = true;
    publishState();
  });

  pi.on("agent_settled", (_event, ctx) => {
    if (!rootSession || ctx?.isIdle?.() !== true) {
      return;
    }

    agentActive = false;

    if (!blocks.has("error")) {
      clearBlocks(["herdr", "prompt", "ui"]);
    }
    lastError = undefined;
    errorReported = false;

    publishState();
  });

  pi.on("session_tree", (_event, ctx) => {
    if (!rootSession) return;
    updateSessionRef(ctx);
    publishState();
  });

  pi.on("session_shutdown", () => {
    if (!rootSession) return;
    rootSession = false;
    agentActive = false;
    subagentCount = 0;
    questionLabel = undefined;
    lastError = undefined;
    errorReported = false;
    blocks.clear();
    queueState("idle", undefined);
  });
}
