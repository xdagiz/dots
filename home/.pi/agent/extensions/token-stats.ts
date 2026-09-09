import type {
  ExtensionAPI,
  ExtensionCommandContext,
  Theme,
  ThemeColor,
} from "@earendil-works/pi-coding-agent";
import type { AutocompleteItem } from "@earendil-works/pi-tui";
import {
  Key,
  matchesKey,
  truncateToWidth,
  visibleWidth,
  wrapTextWithAnsi,
} from "@earendil-works/pi-tui";
import { existsSync, lstatSync, readdirSync, readFileSync, renameSync, statSync, writeFileSync } from "node:fs";
import { readFile } from "node:fs/promises";
import { homedir } from "node:os";
import { join } from "node:path";

type Usage = {
  input?: number;
  output?: number;
  cacheRead?: number;
  cacheWrite?: number;
  totalTokens?: number;
  cost?: {
    input?: number;
    output?: number;
    cacheRead?: number;
    cacheWrite?: number;
    total?: number;
  };
};

type AssistantMessage = {
  role?: string;
  provider?: string;
  model?: string;
  usage?: Usage;
  timestamp?: number;
};

type SessionLine = {
  type?: string;
  timestamp?: string;
  message?: AssistantMessage;
};

type DayKey = string;

interface DayBucket {
  requests: number;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  tokens: number;
  cost: number;
}

interface ModelUsage {
  provider: string;
  model: string;
  requests: number;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  tokens: number;
  cost: number;
}

interface SessionSpan {
  start?: number;
  end?: number;
}

interface CacheFileEntry {
  mtime: number;
  size: number;
  days: Record<DayKey, DayBucket>;
  dayModels: Record<DayKey, Record<string, ModelUsage>>;
  span: SessionSpan;
  skippedNoTimestamp: number;
}

interface CacheFile {
  version: 1;
  files: Record<string, CacheFileEntry>;
}

interface AllTimeData {
  sessionDir: string;
  filesScanned: number;
  filesWithUsage: number;
  filesFailed: number;
  skippedNoTimestamp: number;
  days: Map<DayKey, DayBucket>;
  dayModels: Map<DayKey, Map<string, ModelUsage>>;
  sessions: SessionSpan[];
  firstActivity?: number;
}

interface ModelStats {
  provider: string;
  model: string;
  requests: number;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  costTotal: number;
}

interface RangeStats {
  days: number;
  fromTime?: number;
  fromKey?: DayKey;
  toTime: number;
  sessions: number;
  requests: number;
  input: number;
  output: number;
  cacheRead: number;
  cacheWrite: number;
  totalTokens: number;
  costTotal: number;
  models: ModelStats[];
  activeDays: DayKey[];
  totalDayCount: number;
  mostActiveDay?: { key: DayKey; tokens: number };
  longestSessionMs?: number;
  longestStreak: number;
  currentStreak: number;
}

interface HeatCell {
  key: DayKey;
  tokens: number;
  level: number;
  future: boolean;
}

interface Heatmap {
  weeks: HeatCell[][];
  monthLabels: Array<{ col: number; label: string }>;
  truncated: boolean;
}

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"];
const BODY_INDENT = "  ";
const OVERVIEW_DESCRIPTION =
  "Token and cost usage computed from pi session files. Heatmap cells are days, shaded by tokens relative to your busiest days.";
const MODELS_DESCRIPTION =
  "Per-model token and cost totals for the selected range, sorted by tokens.";
const LEVEL_COLORS: ThemeColor[] = [
  "thinkingLow",
  "thinkingMedium",
  "thinkingHigh",
  "thinkingXhigh",
];
const RANGES = [
  { days: 0, label: "All time" },
  { days: 7, label: "Last 7 days" },
  { days: 30, label: "Last 30 days" },
];

const getSessionDir = (): string => {
  if (process.env.PI_CODING_AGENT_SESSION_DIR) {
    return process.env.PI_CODING_AGENT_SESSION_DIR;
  }

  const configDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  return join(configDir, "sessions");
};

const getCachePath = (): string => {
  const configDir = process.env.PI_CODING_AGENT_DIR ?? join(homedir(), ".pi", "agent");
  return join(configDir, "token-stats-cache.json");
};

const mapLimit = async <T, R>(
  items: T[],
  limit: number,
  fn: (item: T) => Promise<R>,
): Promise<R[]> => {
  const results: R[] = new Array(items.length);
  let next = 0;
  const workers = Array.from({ length: Math.min(limit, items.length) }, async () => {
    while (next < items.length) {
      const index = next++;
      results[index] = await fn(items[index]!);
    }
  });
  await Promise.all(workers);
  return results;
};

const scanFile = async (file: string): Promise<CacheFileEntry | undefined> => {
  let content: string;
  try {
    content = await readFile(file, "utf8");
  } catch {
    return undefined;
  }

  const entry: CacheFileEntry = { mtime: 0, size: 0, days: {}, dayModels: {}, span: {}, skippedNoTimestamp: 0 };
  for (const rawLine of content.split("\n")) {
    const line = rawLine.trim();
    if (!line || !line.includes('"usage"')) {
      continue;
    }

    let parsed: SessionLine;
    try {
      parsed = JSON.parse(line) as SessionLine;
    } catch {
      continue;
    }

    if (
      parsed.type !== "message" ||
      parsed.message?.role !== "assistant" ||
      !parsed.message.usage
    ) {
      continue;
    }

    const usage = parsed.message.usage;
    const input = usage.input ?? 0;
    const output = usage.output ?? 0;
    const cacheRead = usage.cacheRead ?? 0;
    const cacheWrite = usage.cacheWrite ?? 0;
    const totalTokens = usage.totalTokens ?? input + output + cacheRead + cacheWrite;
    const cost =
      usage.cost?.total ??
      (usage.cost?.input ?? 0) +
        (usage.cost?.output ?? 0) +
        (usage.cost?.cacheRead ?? 0) +
        (usage.cost?.cacheWrite ?? 0);
    const ts =
      parsed.message.timestamp ?? (parsed.timestamp ? Date.parse(parsed.timestamp) : undefined);
    if (ts === undefined || !Number.isFinite(ts)) {
      entry.skippedNoTimestamp += 1;
      continue;
    }

    const span = entry.span;
    if (span.start === undefined || ts < span.start) span.start = ts;
    if (span.end === undefined || ts > span.end) span.end = ts;

    const key = dateKeyOf(ts);
    const bucket = entry.days[key] ?? emptyBucket();
    bucket.requests += 1;
    bucket.input += input;
    bucket.output += output;
    bucket.cacheRead += cacheRead;
    bucket.cacheWrite += cacheWrite;
    bucket.tokens += totalTokens;
    bucket.cost += cost;
    entry.days[key] = bucket;

    const provider = parsed.message.provider ?? "unknown";
    const model = parsed.message.model ?? "unknown";
    const modelMap = entry.dayModels[key] ?? {};
    const modelKey = `${provider}/${model}`;
    const agg = modelMap[modelKey] ?? {
      provider,
      model,
      requests: 0,
      input: 0,
      output: 0,
      cacheRead: 0,
      cacheWrite: 0,
      tokens: 0,
      cost: 0,
    };
    agg.requests += 1;
    agg.input += input;
    agg.output += output;
    agg.cacheRead += cacheRead;
    agg.cacheWrite += cacheWrite;
    agg.tokens += totalTokens;
    agg.cost += cost;
    modelMap[modelKey] = agg;
    entry.dayModels[key] = modelMap;
  }

  return entry;
};

const walkJsonlFiles = (dir: string): string[] => {
  if (!existsSync(dir)) {
    return [];
  }

  const result: string[] = [];
  const stack = [dir];

  while (stack.length > 0) {
    const current = stack.pop()!;
    let entries: string[] = [];
    try {
      entries = readdirSync(current).sort();
    } catch {
      continue;
    }

    for (const entry of entries) {
      const fullPath = join(current, entry);
      let lst;
      try {
        lst = lstatSync(fullPath);
      } catch {
        continue;
      }

      if (lst.isSymbolicLink()) {
        let target;
        try {
          target = statSync(fullPath);
        } catch {
          continue;
        }
        if (target.isDirectory()) {
          continue;
        }
        if (target.isFile() && entry.endsWith(".jsonl")) {
          result.push(fullPath);
        }
        continue;
      }

      if (lst.isDirectory()) {
        stack.push(fullPath);
      } else if (lst.isFile() && entry.endsWith(".jsonl")) {
        result.push(fullPath);
      }
    }
  }

  result.sort();
  return result;
};

const parseDays = (args: string | undefined): number => {
  const text = (args ?? "").trim();
  if (!text) {
    return 30;
  }

  const flagMatch = text.match(/(?:^|\s)(?:--days|-d)(?:\s*=\s*|\s+)(-?\d+)(?:\s|$)/i);
  const attachedMatch = text.match(/(?:^|\s)-d(-?\d+)(?:\s|$)/i);
  const compactMatch = text.match(/^(-?\d+)\s*d?$/i);
  const valueText = flagMatch?.[1] ?? attachedMatch?.[1] ?? compactMatch?.[1];
  const value = Number.parseInt(valueText ?? "", 10);

  if (!Number.isFinite(value) || value < 0) {
    return 30;
  }

  return value;
};

const pad2 = (value: number): string => String(value).padStart(2, "0");

const dateKeyOf = (ts: number): DayKey => {
  const d = new Date(ts);
  return `${d.getFullYear()}-${pad2(d.getMonth() + 1)}-${pad2(d.getDate())}`;
};

const keyToDate = (key: DayKey): Date => {
  const [y, m, d] = key.split("-").map(Number) as [number, number, number];
  return new Date(y, m - 1, d);
};

const addDays = (key: DayKey, n: number): DayKey => {
  const d = keyToDate(key);
  d.setDate(d.getDate() + n);
  return dateKeyOf(d.getTime());
};

const mondayOf = (key: DayKey): DayKey => {
  const d = keyToDate(key);
  const weekday = (d.getDay() + 6) % 7;
  d.setDate(d.getDate() - weekday);
  return dateKeyOf(d.getTime());
};

const diffDays = (a: DayKey, b: DayKey): number =>
  Math.round((keyToDate(b).getTime() - keyToDate(a).getTime()) / 86_400_000);

const rangeBounds = (
  days: number,
  toTime: number,
): { fromTime?: number; fromKey?: DayKey; today: DayKey } => {
  const today = dateKeyOf(toTime);
  if (days === 0) {
    return { today };
  }
  const fromKey = addDays(today, -(days - 1));
  return { fromTime: keyToDate(fromKey).getTime(), fromKey, today };
};

const formatDay = (key: DayKey): string => {
  const d = keyToDate(key);
  return `${MONTHS[d.getMonth()]} ${d.getDate()}`;
};

const formatDuration = (ms: number): string => {
  const totalMinutes = Math.max(0, Math.floor(ms / 60_000));
  const d = Math.floor(totalMinutes / 1440);
  const h = Math.floor((totalMinutes % 1440) / 60);
  const m = totalMinutes % 60;
  const parts: string[] = [];
  if (d > 0) parts.push(`${d}d`);
  if (h > 0) parts.push(`${h}h`);
  if (m > 0 || parts.length === 0) parts.push(`${m}m`);
  return parts.join(" ");
};

const formatNumber = (value: number): string =>
  new Intl.NumberFormat("en-US").format(Math.round(value));

const formatCompactTokens = (value: number): string => {
  const rounded = Math.round(value);
  if (rounded >= 1_000_000_000_000) {
    return `${(rounded / 1_000_000_000_000).toFixed(1)}T`;
  }
  if (rounded >= 1_000_000_000) {
    return `${(rounded / 1_000_000_000).toFixed(1)}B`;
  }
  if (rounded >= 1_000_000) {
    return `${(rounded / 1_000_000).toFixed(1)}M`;
  }
  if (rounded >= 1_000) {
    return `${(rounded / 1_000).toFixed(1)}K`;
  }
  return formatNumber(rounded);
};

const formatCost = (value: number): string => {
  if (value >= 100) return `$${Math.round(value)}`;
  if (value >= 1) return `$${value.toFixed(2)}`;
  return `$${value.toFixed(4)}`;
};

const formatDateTime = (value: number): string => {
  const date = new Date(value);
  return `${date.getFullYear()}-${pad2(date.getMonth() + 1)}-${pad2(date.getDate())} ${pad2(date.getHours())}:${pad2(date.getMinutes())}`;
};

const emptyBucket = (): DayBucket => ({
  requests: 0,
  input: 0,
  output: 0,
  cacheRead: 0,
  cacheWrite: 0,
  tokens: 0,
  cost: 0,
});

const mergeEntry = (data: AllTimeData, entry: CacheFileEntry): void => {
  if (
    entry.span.start !== undefined &&
    (data.firstActivity === undefined || entry.span.start < data.firstActivity)
  ) {
    data.firstActivity = entry.span.start;
  }
  data.sessions.push(entry.span);
  data.skippedNoTimestamp += entry.skippedNoTimestamp ?? 0;
  if (Object.keys(entry.days).length > 0) {
    data.filesWithUsage += 1;
  }
  for (const [key, bucket] of Object.entries(entry.days)) {
    const target = data.days.get(key) ?? emptyBucket();
    target.requests += bucket.requests;
    target.input += bucket.input;
    target.output += bucket.output;
    target.cacheRead += bucket.cacheRead;
    target.cacheWrite += bucket.cacheWrite;
    target.tokens += bucket.tokens;
    target.cost += bucket.cost;
    data.days.set(key, target);
  }
  for (const [key, modelMap] of Object.entries(entry.dayModels)) {
    let targetMap = data.dayModels.get(key);
    if (targetMap === undefined) {
      targetMap = new Map();
      data.dayModels.set(key, targetMap);
    }
    for (const [modelKey, agg] of Object.entries(modelMap)) {
      const target = targetMap.get(modelKey) ?? { ...agg };
      if (targetMap.has(modelKey)) {
        target.requests += agg.requests;
        target.input += agg.input;
        target.output += agg.output;
        target.cacheRead += agg.cacheRead;
        target.cacheWrite += agg.cacheWrite;
        target.tokens += agg.tokens;
        target.cost += agg.cost;
      }
      targetMap.set(modelKey, target);
    }
  }
};

const isValidBucket = (value: unknown): value is DayBucket => {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const bucket = value as Record<string, unknown>;
  return ["requests", "input", "output", "cacheRead", "cacheWrite", "tokens", "cost"].every(
    (key) => typeof bucket[key] === "number" && Number.isFinite(bucket[key] as number),
  );
};

const isValidCacheEntry = (value: unknown): value is CacheFileEntry => {
  if (typeof value !== "object" || value === null) {
    return false;
  }
  const entry = value as Record<string, unknown>;
  if (typeof entry["mtime"] !== "number" || typeof entry["size"] !== "number") {
    return false;
  }
  if (typeof entry["days"] !== "object" || entry["days"] === null) {
    return false;
  }
  if (typeof entry["dayModels"] !== "object" || entry["dayModels"] === null) {
    return false;
  }
  if (typeof entry["span"] !== "object" || entry["span"] === null) {
    return false;
  }
  for (const bucket of Object.values(entry["days"] as Record<string, unknown>)) {
    if (!isValidBucket(bucket)) {
      return false;
    }
  }
  return true;
};

const writeCacheAtomic = (path: string, cache: CacheFile): void => {
  const tmp = `${path}.tmp.${process.pid}`;
  try {
    writeFileSync(tmp, JSON.stringify(cache));
    renameSync(tmp, path);
  } catch {
    try {
      writeFileSync(path, JSON.stringify(cache));
    } catch {}
  }
};

const collectAll = async (): Promise<AllTimeData> => {
  const sessionDir = getSessionDir();
  const files = walkJsonlFiles(sessionDir);
  const data: AllTimeData = {
    sessionDir,
    filesScanned: files.length,
    filesWithUsage: 0,
    filesFailed: 0,
    skippedNoTimestamp: 0,
    days: new Map(),
    dayModels: new Map(),
    sessions: [],
  };

  let cache: CacheFile = { version: 1, files: {} };
  let cacheDirty = false;
  try {
    const parsed = JSON.parse(readFileSync(getCachePath(), "utf8")) as CacheFile;
    if (parsed.version === 1 && parsed.files && typeof parsed.files === "object") {
      cache = parsed;
      for (const [path, entry] of Object.entries(cache.files)) {
        if (!isValidCacheEntry(entry)) {
          delete cache.files[path];
          cacheDirty = true;
        }
      }
    }
  } catch {}

  const statJobs = await mapLimit(files, 32, async (file) => {
    try {
      const st = statSync(file);
      return { file, mtime: st.mtimeMs, size: st.size };
    } catch {
      return undefined;
    }
  });

  const live = statJobs.filter((job) => job !== undefined) as Array<{
    file: string;
    mtime: number;
    size: number;
  }>;
  const stale = live.filter((job) => {
    const cached = cache.files[job.file];
    return cached === undefined || cached.mtime !== job.mtime || cached.size !== job.size;
  });

  const scanned = await mapLimit(stale, 8, async (job) => {
    const entry = await scanFile(job.file);
    return entry === undefined ? undefined : { job, entry };
  });

  for (const result of scanned) {
    if (result === undefined) continue;
    const previous = cache.files[result.job.file];
    const next = {
      ...result.entry,
      mtime: result.job.mtime,
      size: result.job.size,
    };
    if (JSON.stringify(previous) !== JSON.stringify(next)) {
      cache.files[result.job.file] = next;
      cacheDirty = true;
    }
  }

  const liveFiles = new Set(live.map((job) => job.file));
  for (const path of Object.keys(cache.files)) {
    if (!liveFiles.has(path)) {
      delete cache.files[path];
      cacheDirty = true;
    }
  }

  for (const job of live) {
    const entry = cache.files[job.file];
    if (entry === undefined) {
      data.filesFailed += 1;
      continue;
    }
    try {
      mergeEntry(data, entry);
    } catch {
      data.filesFailed += 1;
      delete cache.files[job.file];
      cacheDirty = true;
    }
  }

  if (cacheDirty) {
    writeCacheAtomic(getCachePath(), cache);
  }

  return data;
};

const computeStreaks = (
  activeDays: readonly DayKey[],
  today: DayKey,
): { longest: number; current: number } => {
  const sorted = [...activeDays].sort();
  const set = new Set(sorted);
  let longest = 0;
  let run = 0;
  let prev: DayKey | undefined;
  for (const key of sorted) {
    run = prev !== undefined && diffDays(prev, key) === 1 ? run + 1 : 1;
    if (run > longest) longest = run;
    prev = key;
  }
  let current = 0;
  let cursor = today;
  if (!set.has(cursor)) cursor = addDays(cursor, -1);
  while (set.has(cursor)) {
    current += 1;
    cursor = addDays(cursor, -1);
  }
  return { longest, current };
};

const computeRange = (data: AllTimeData, days: number): RangeStats => {
  const toTime = Date.now();
  const { fromTime, fromKey, today } = rangeBounds(days, toTime);
  const totals = emptyBucket();
  const models = new Map<string, ModelStats>();
  const activeDays: DayKey[] = [];
  let mostActiveDay: { key: DayKey; tokens: number } | undefined;

  for (const [key, bucket] of data.days) {
    if (key > today || (fromKey !== undefined && key < fromKey)) continue;
    totals.requests += bucket.requests;
    totals.input += bucket.input;
    totals.output += bucket.output;
    totals.cacheRead += bucket.cacheRead;
    totals.cacheWrite += bucket.cacheWrite;
    totals.tokens += bucket.tokens;
    totals.cost += bucket.cost;
    if (bucket.tokens > 0) {
      activeDays.push(key);
      if (mostActiveDay === undefined || bucket.tokens > mostActiveDay.tokens) {
        mostActiveDay = { key, tokens: bucket.tokens };
      }
    }
    for (const agg of data.dayModels.get(key)?.values() ?? []) {
      const modelKey = `${agg.provider}/${agg.model}`;
      let m = models.get(modelKey);
      if (m === undefined) {
        m = {
          provider: agg.provider,
          model: agg.model,
          requests: 0,
          input: 0,
          output: 0,
          cacheRead: 0,
          cacheWrite: 0,
          totalTokens: 0,
          costTotal: 0,
        };
        models.set(modelKey, m);
      }
      m.requests += agg.requests;
      m.input += agg.input;
      m.output += agg.output;
      m.cacheRead += agg.cacheRead;
      m.cacheWrite += agg.cacheWrite;
      m.totalTokens += agg.tokens;
      m.costTotal += agg.cost;
    }
  }
  activeDays.sort();

  let sessions = 0;
  let longestSessionMs: number | undefined;
  for (const span of data.sessions) {
    if (span.end === undefined) continue;
    if (fromTime !== undefined && span.end < fromTime) continue;
    sessions += 1;
    if (span.start !== undefined) {
      const ms = span.end - span.start;
      if (ms >= 0 && (longestSessionMs === undefined || ms > longestSessionMs)) {
        longestSessionMs = ms;
      }
    }
  }

  const firstDay =
    fromKey ?? (data.firstActivity !== undefined ? dateKeyOf(data.firstActivity) : undefined);
  const totalDayCount =
    days === 0
      ? firstDay !== undefined
        ? diffDays(firstDay, today) + 1
        : 0
      : days;
  const fullActive = [...data.days.entries()]
    .filter(([key, bucket]) => key <= today && bucket.tokens > 0)
    .map(([key]) => key)
    .sort();
  const { longest, current } = computeStreaks(fullActive, today);

  return {
    days,
    fromTime,
    fromKey,
    toTime,
    sessions,
    requests: totals.requests,
    input: totals.input,
    output: totals.output,
    cacheRead: totals.cacheRead,
    cacheWrite: totals.cacheWrite,
    totalTokens: totals.tokens,
    costTotal: totals.cost,
    models: [...models.values()],
    activeDays,
    totalDayCount,
    mostActiveDay,
    longestSessionMs,
    longestStreak: longest,
    currentStreak: current,
  };
};

const computeLevelThresholds = (tokens: number[]): [number, number, number] | undefined => {
  const positive = tokens.filter((t) => t > 0);
  if (positive.length === 0) return undefined;
  const sorted = [...positive].sort((a, b) => a - b);
  const distinct = [...new Set(sorted)];
  if (distinct.length === 1) {
    return [0, 0, 0];
  }
  if (sorted.length <= 4) {
    if (distinct.length === 2) {
      const a = distinct[0]!;
      return [a, a, a];
    }
    if (distinct.length === 3) {
      const a = distinct[0]!;
      const b = distinct[1]!;
      return [a, b, b];
    }
    return [sorted[0]!, sorted[1]!, sorted[2]!];
  }
  const pick = (p: number) => sorted[Math.floor(p * sorted.length)]!;
  let t1 = pick(0.25);
  let t2 = pick(0.5);
  let t3 = pick(0.75);
  const max = sorted[sorted.length - 1]!;
  if (t3 >= max) {
    t3 = [...distinct].reverse().find((v) => v < max) ?? 0;
  }
  if (t2 > t3) {
    t2 = t3;
  }
  if (t1 > t2) {
    t1 = t2;
  }
  return [t1, t2, t3];
};

const levelFor = (tokens: number, thresholds: [number, number, number] | undefined): number => {
  if (tokens <= 0 || thresholds === undefined) return 0;
  const [t1, t2, t3] = thresholds;
  if (tokens <= t1) return 1;
  if (tokens <= t2) return 2;
  if (tokens <= t3) return 3;
  return 4;
};

const buildHeatmap = (data: AllTimeData, stats: RangeStats, maxWeeks: number): Heatmap => {
  const today = dateKeyOf(stats.toTime);
  const rangeStartKey =
    stats.fromKey ??
    (stats.fromTime !== undefined
      ? dateKeyOf(stats.fromTime)
      : data.firstActivity !== undefined
        ? dateKeyOf(data.firstActivity)
        : today);
  let start = mondayOf(rangeStartKey);
  const end = mondayOf(today);
  const totalWeeks = Math.floor(diffDays(start, end) / 7) + 1;
  let truncated = false;
  if (totalWeeks > maxWeeks) {
    start = addDays(end, -((maxWeeks - 1) * 7));
    truncated = true;
  }
  const weeks = Math.min(totalWeeks, maxWeeks);
  const thresholds = computeLevelThresholds(
    stats.activeDays.map((k) => data.days.get(k)?.tokens ?? 0).filter((t) => t > 0),
  );
  const columns: HeatCell[][] = [];
  const monthLabels: Array<{ col: number; label: string }> = [];
  let prevMonth = -1;
  let lastLabelCol = -3;
  for (let w = 0; w < weeks; w++) {
    const col: HeatCell[] = [];
    for (let r = 0; r < 7; r++) {
      const key = addDays(start, w * 7 + r);
      const future = key > today;
      const tokens = future ? 0 : (data.days.get(key)?.tokens ?? 0);
      col.push({ key, tokens, level: future ? 0 : levelFor(tokens, thresholds), future });
    }
    columns.push(col);
    const month = keyToDate(addDays(start, w * 7 + 3)).getMonth();
    if (month !== prevMonth) {
      if (w - lastLabelCol >= 2) {
        monthLabels.push({ col: w, label: MONTHS[month]! });
        lastLabelCol = w;
      }
      prevMonth = month;
    }
  }
  return { weeks: columns, monthLabels, truncated };
};

const renderHeatCell = (theme: Theme, cell: HeatCell): string =>
  cell.level === 0 ? theme.fg("dim", "·") : theme.fg(LEVEL_COLORS[cell.level - 1]!, "■");

const renderHeatmapLines = (theme: Theme, heat: Heatmap): string[] => {
  const labelWidth = 4;
  const monthChars: string[] = Array(heat.weeks.length * 2).fill(" ");
  for (const { col, label } of heat.monthLabels) {
    for (let i = 0; i < label.length && col * 2 + i < monthChars.length; i++) {
      monthChars[col * 2 + i] = label[i]!;
    }
  }
  const lines = [`${" ".repeat(labelWidth)}${theme.fg("dim", monthChars.join("").trimEnd())}`];
  const dayLabels = ["Mon", "", "Wed", "", "Fri", "", ""];
  for (let r = 0; r < 7; r++) {
    const cells = heat.weeks.map((week) => renderHeatCell(theme, week[r]!)).join(" ");
    lines.push(`${theme.fg("dim", (dayLabels[r] ?? "").padEnd(labelWidth))}${cells}`);
  }
  const legend = LEVEL_COLORS.map((c) => theme.fg(c, "■")).join(" ");
  lines.push("");
  lines.push(
    `${" ".repeat(labelWidth)}${theme.fg("dim", "Less ")}${legend}${theme.fg("dim", " More")}`,
  );
  if (heat.truncated) {
    lines.push(`${" ".repeat(labelWidth)}${theme.fg("dim", "(older weeks hidden to fit width)")}`);
  }
  return lines;
};

const renderTabsLine = (theme: Theme, days: number, width: number): string => {
  const build = (labels: readonly string[]) => {
    const parts = RANGES.map((r, i) =>
      r.days === days ? theme.fg("accent", theme.bold(labels[i]!)) : theme.fg("dim", labels[i]!),
    );
    return `  ${parts.join(theme.fg("dim", " · "))}`;
  };
  const full = build(RANGES.map((r) => r.label));
  if (visibleWidth(full) <= width) return full;
  return build(["All", "7d", "30d"]);
};

const renderHintsLine = (
  theme: Theme,
  hints: Array<readonly [string, string]>,
  width: number,
): string => {
  const full = `${BODY_INDENT}${hints
    .map(([key, desc]) => `${theme.fg("dim", key)}${theme.fg("muted", ` ${desc}`)}`)
    .join(theme.fg("dim", " · "))}`;
  if (visibleWidth(full) <= width) return full;
  return `${BODY_INDENT}${hints.map(([key]) => theme.fg("dim", key)).join(theme.fg("dim", " · "))}`;
};

const spreadLine = (left: string, right: string, width: number): string => {
  const gap = width - visibleWidth(left) - visibleWidth(right);
  if (gap < 1) {
    const trimmedLeft = truncateToWidth(left, Math.max(1, width - visibleWidth(right) - 2), "…");
    return truncateToWidth(`${trimmedLeft} ${right}`, width, "…");
  }
  return `${left}${" ".repeat(gap)}${right}`;
};

const wrapDescriptionLines = (theme: Theme, text: string, width: number): string[] => {
  const contentWidth = Math.max(1, width - BODY_INDENT.length);
  const wrapped = wrapTextWithAnsi(text, contentWidth);
  return (wrapped.length === 0 ? [""] : wrapped).map((line) =>
    theme.fg("dim", `${BODY_INDENT}${line}`),
  );
};

const wrapParts = (parts: string[], separator: string, maxWidth: number): string[] => {
  const lines: string[] = [];
  let current: string | undefined;
  for (const part of parts) {
    const candidate = current === undefined ? part : `${current}${separator}${part}`;
    if (current === undefined || visibleWidth(candidate) <= maxWidth) {
      current = candidate;
    } else {
      lines.push(current);
      current = part;
    }
  }
  if (current !== undefined) lines.push(current);
  return lines;
};

const renderStatsLines = (theme: Theme, stats: RangeStats, width: number): string[] => {
  const labelWidth = 15;
  const indent = 2;
  const models = [...stats.models].sort((a, b) => b.totalTokens - a.totalTokens);
  const fav = models[0];
  const favText = fav ? `${fav.provider}/${fav.model}` : "-";
  const mostActiveText = stats.mostActiveDay
    ? `${formatDay(stats.mostActiveDay.key)} (${formatCompactTokens(stats.mostActiveDay.tokens)})`
    : "-";
  const longestText =
    stats.longestSessionMs !== undefined ? formatDuration(stats.longestSessionMs) : "-";
  const left: Array<readonly [string, string, ThemeColor]> = [
    ["Favorite model", favText, fav ? "accent" : "muted"],
    ["Sessions", formatNumber(stats.sessions), "text"],
    ["Active days", `${stats.activeDays.length}/${stats.totalDayCount}`, "text"],
    ["Most active day", mostActiveText, stats.mostActiveDay ? "text" : "muted"],
  ];
  const right: Array<readonly [string, string, ThemeColor]> = [
    ["Total tokens", formatCompactTokens(stats.totalTokens), "text"],
    ["Longest session", longestText, stats.longestSessionMs !== undefined ? "text" : "muted"],
    [
      "Longest streak",
      stats.longestStreak > 0 ? `${stats.longestStreak} days` : "-",
      stats.longestStreak > 0 ? "text" : "muted",
    ],
    [
      "Current streak",
      stats.currentStreak > 0 ? `${stats.currentStreak} days` : "-",
      stats.currentStreak > 0 ? "text" : "muted",
    ],
  ];
  const lines: string[] = [];
  const leftValueWidth = Math.max(0, ...left.map(([, v]) => v.length));
  const rightValueWidth = Math.max(0, ...right.map(([, v]) => v.length));
  const twoColumn =
    indent + (labelWidth + 2) + leftValueWidth + 4 + (labelWidth + 2) + rightValueWidth <= width;
  if (twoColumn) {
    const leftBlockWidth = labelWidth + 2 + leftValueWidth + 4;
    for (let i = 0; i < left.length; i++) {
      const [ll, lv, lc] = left[i]!;
      const [rl, rv, rc] = right[i]!;
      const leftLabel = theme.fg("dim", `${ll}:`.padEnd(labelWidth + 2));
      const rightLabel = theme.fg("dim", `${rl}:`.padEnd(labelWidth + 2));
      const gap = " ".repeat(Math.max(1, leftBlockWidth - (labelWidth + 2) - lv.length));
      lines.push(
        `${" ".repeat(indent)}${leftLabel}${theme.fg(lc, lv)}${gap}${rightLabel}${theme.fg(rc, rv)}`,
      );
    }
  } else {
    const valueWidth = Math.max(4, width - indent - (labelWidth + 2) - 1);
    for (const [label, value, color] of [...left, ...right]) {
      lines.push(
        `${" ".repeat(indent)}${theme.fg("dim", `${label}:`.padEnd(labelWidth + 2))}${theme.fg(color, truncatePlain(value, valueWidth))}`,
      );
    }
  }
  lines.push("");
  const parts: string[] = [];
  for (const [label, value] of [
    ["Input", stats.input],
    ["Output", stats.output],
    ["Cache read", stats.cacheRead],
    ["Cache write", stats.cacheWrite],
  ] as const) {
    parts.push(`${theme.fg("dim", `${label} `)}${theme.fg("muted", formatCompactTokens(value))}`);
  }
  const separator = theme.fg("dim", " · ");
  for (const line of wrapParts(parts, separator, width - indent)) {
    lines.push(`${" ".repeat(indent)}${line}`);
  }
  return lines;
};

const renderModelLines = (
  theme: Theme,
  stats: RangeStats,
  width: number,
  maxLines: number,
): string[] => {
  if (stats.models.length === 0) {
    return [`  ${theme.fg("muted", "No token usage found in this range.")}`];
  }
  const models = [...stats.models].sort((a, b) => b.totalTokens - a.totalTokens);
  const allHeaders = [
    "Model",
    "Tokens",
    "Reqs",
    "Input",
    "Output",
    "Cache Rd",
    "Cache Wr",
    "Cost",
  ] as const;
  const allRows = models.map((m) => [
    `${m.provider}/${m.model}`,
    formatCompactTokens(m.totalTokens),
    formatNumber(m.requests),
    formatCompactTokens(m.input),
    formatCompactTokens(m.output),
    formatCompactTokens(m.cacheRead),
    formatCompactTokens(m.cacheWrite),
    formatCost(m.costTotal),
  ]);
  const totalRow = [
    "TOTAL",
    formatCompactTokens(stats.totalTokens),
    formatNumber(stats.requests),
    formatCompactTokens(stats.input),
    formatCompactTokens(stats.output),
    formatCompactTokens(stats.cacheRead),
    formatCompactTokens(stats.cacheWrite),
    formatCost(stats.costTotal),
  ];
  const allWidths = allHeaders.map((h, i) =>
    Math.max(h.length, totalRow[i]!.length, ...allRows.map((r) => r[i]!.length)),
  );
  const keep = [0, 1, 2, 3, 4, 5, 6, 7];
  const droppable = [6, 5, 3, 4, 2];
  const tableWidth = () =>
    keep.reduce((sum, i) => sum + allWidths[i]!, 0) + keep.length * 3 + 3;
  for (const col of droppable) {
    if (tableWidth() <= width) break;
    const pos = keep.indexOf(col);
    if (pos >= 0) keep.splice(pos, 1);
  }
  const headers = keep.map((i) => allHeaders[i]!);
  const rows = allRows.map((row) => keep.map((i) => row[i]!));
  const totals = keep.map((i) => totalRow[i]!);
  const widths = keep.map((i) => allWidths[i]!);
  if (tableWidth() > width) {
    widths[0] = Math.max(8, widths[0]! - (tableWidth() - width));
  }
  const aligns = keep.map((i) => (i === 0 ? "l" : "r"));
  const cell = (text: string, w: number, align: "l" | "r") => {
    const t = truncateToWidth(text, w, "…");
    return align === "l" ? t.padEnd(w) : t.padStart(w);
  };
  const bar = theme.fg("dim", " │ ");
  const leftEdge = theme.fg("dim", "│ ");
  const rightEdge = theme.fg("dim", " │");
  const frame = (l: string, j: string, r: string): string =>
    `  ${theme.fg("dim", l + widths.map((w) => "─".repeat(Math.max(1, w) + 2)).join(j) + r)}`;
  const lines: string[] = [
    frame("┌", "┬", "┐"),
    `  ${leftEdge}${headers.map((h, i) => theme.fg("dim", cell(h, widths[i]!, aligns[i]! as "l" | "r"))).join(bar)}${rightEdge}`,
    frame("├", "┼", "┤"),
  ];
  const maxRows = Math.max(1, Math.floor((maxLines - 5) / 2));
  const hidden = rows.length - maxRows;
  for (const row of rows.slice(0, maxRows)) {
    const cells = row
      .map((c, i) => theme.fg("text", cell(c, widths[i]!, aligns[i]! as "l" | "r")))
      .join(bar);
    lines.push(`  ${leftEdge}${cells}${rightEdge}`);
    lines.push(frame("├", "┼", "┤"));
  }
  const totalCells = totals
    .map((c, i) => theme.fg("text", cell(c, widths[i]!, aligns[i]! as "l" | "r")))
    .join(bar);
  lines.push(`  ${leftEdge}${theme.bold(totalCells)}${rightEdge}`);
  lines.push(frame("└", "┴", "┘"));
  if (hidden > 0) {
    lines.push(`  ${theme.fg("dim", `+${hidden} more models`)}`);
  }
  return lines;
};

const tableRow = (cells: Array<string | number>): string => `| ${cells.join(" | ")} |`;

const truncatePlain = (text: string, maxWidth: number): string =>
  truncateToWidth(text, Math.max(1, maxWidth), "…");

const buildMarkdown = (stats: RangeStats, data: AllTimeData): string => {
  const today = dateKeyOf(stats.toTime);
  const range =
    stats.days === 0
      ? "all time"
      : stats.fromKey !== undefined
        ? `last ${stats.days} days (${formatDay(stats.fromKey)} to ${formatDay(today)})`
        : `last ${stats.days} days (${formatDateTime(stats.fromTime!)} to ${formatDateTime(stats.toTime)})`;
  const rows = [...stats.models].sort((a, b) => b.totalTokens - a.totalTokens);

  const lines: string[] = [
    "# Pi Token Usage Stats",
    "",
    `- Range: ${range}`,
    `- Session dir: \`${data.sessionDir}\``,
    `- Files walked: ${formatNumber(data.filesScanned)}, files with usage: ${formatNumber(data.filesWithUsage)}, files unreadable: ${formatNumber(data.filesFailed)}, sessions in range: ${formatNumber(stats.sessions)}`,
    `- Active days: ${formatNumber(stats.activeDays.length)}/${formatNumber(stats.totalDayCount)}, longest streak: ${formatNumber(stats.longestStreak)} days, current streak: ${formatNumber(stats.currentStreak)} days`,
    `- Model requests: ${formatNumber(stats.requests)}`,
    `- Total tokens: ${formatCompactTokens(stats.totalTokens)} (${formatNumber(stats.totalTokens)})`,
    `- Total cost: ${formatCost(stats.costTotal)}`,
    `- Skipped usage lines without timestamp: ${formatNumber(data.skippedNoTimestamp)}`,
    "",
    "## Overview",
    "",
    tableRow(["Input", "Output", "Cache Read", "Cache Write", "Total Tokens", "Cost"]),
    tableRow(["---:", "---:", "---:", "---:", "---:", "---:"]),
    tableRow([
      formatNumber(stats.input),
      formatNumber(stats.output),
      formatNumber(stats.cacheRead),
      formatNumber(stats.cacheWrite),
      formatNumber(stats.totalTokens),
      formatCost(stats.costTotal),
    ]),
    "",
    `- Totals use usage.totalTokens when present, else input + output + cache read + cache write.`,
    "",
    "## By Model",
    "",
  ];

  if (rows.length === 0) {
    lines.push("No token usage found in this range.");
    return lines.join("\n");
  }

  lines.push(
    tableRow([
      "Model",
      "Tokens",
      "Requests",
      "Input",
      "Output",
      "Cache Read",
      "Cache Write",
      "Cost",
    ]),
  );
  lines.push(tableRow(["---", "---:", "---:", "---:", "---:", "---:", "---:", "---:"]));
  for (const row of rows) {
    lines.push(
      tableRow([
        `\`${row.provider}/${row.model}\``,
        formatCompactTokens(row.totalTokens),
        formatNumber(row.requests),
        formatNumber(row.input),
        formatNumber(row.output),
        formatNumber(row.cacheRead),
        formatNumber(row.cacheWrite),
        formatCost(row.costTotal),
      ]),
    );
  }

  return lines.join("\n");
};

export class TokenStatsView {
  private tab: "overview" | "models" = "overview";
  private rangeIndex: number;
  private cachedLines: string[] | undefined;
  private cachedWidth: number | undefined;
  private cachedRows: number | undefined;
  private rangeCache = new Map<number, RangeStats>();
  private readonly theme: Theme;
  private readonly data: AllTimeData;
  private readonly done: () => void;
  private readonly getTerminalRows: () => number;

  constructor(
    theme: Theme,
    data: AllTimeData,
    initialDays: number,
    done: () => void,
    getTerminalRows: () => number,
  ) {
    this.theme = theme;
    this.data = data;
    this.done = done;
    this.getTerminalRows = getTerminalRows;
    const index = RANGES.findIndex((r) => r.days === initialDays);
    this.rangeIndex = index >= 0 ? index : 2;
  }

  handleInput(data: string): void {
    if (matchesKey(data, Key.escape) || data === "q" || data === "Q" || data === "\x03") {
      this.done();
      return;
    }
    if (data === "r") {
      this.rangeIndex = (this.rangeIndex + 1) % RANGES.length;
      this.clearCache();
      return;
    }
    if (data === "\t") {
      this.tab = this.tab === "overview" ? "models" : "overview";
      this.clearCache();
    }
  }

  render(width: number): string[] {
    const rows = this.getTerminalRows();
    if (this.cachedLines !== undefined && this.cachedWidth === width && this.cachedRows === rows) {
      return this.cachedLines;
    }

    const stats = this.stats();
    const days = RANGES[this.rangeIndex]!.days;
    const theme = this.theme;
    const border = theme.fg("border", "─".repeat(Math.max(1, width)));
    const rangeLabel = RANGES[this.rangeIndex]!.label;
    const meta = theme.fg(
      "muted",
      `${rangeLabel} · ${formatCompactTokens(stats.totalTokens)} tokens · ${formatCost(stats.costTotal)}`,
    );
    const prefix: string[] = [
      border,
      "",
      spreadLine(theme.fg("accent", theme.bold("Pi Token Stats")), meta, width),
      "",
    ];
    const body: string[] = [];
    let description: string;
    let hints: Array<readonly [string, string]>;
    if (this.tab === "overview") {
      const maxWeeks = Math.max(1, Math.floor((width - 8) / 2));
      body.push(...renderHeatmapLines(theme, buildHeatmap(this.data, stats, maxWeeks)));
      body.push("", renderTabsLine(theme, days, width), "");
      body.push(...renderStatsLines(theme, stats, width));
      description = OVERVIEW_DESCRIPTION;
      hints = [
        ["r", "Cycle dates"],
        ["Tab", "Models"],
        ["Esc", "Close"],
      ];
    } else {
      const maxTableLines = Math.max(4, rows - 14);
      body.push(renderTabsLine(theme, days, width), "");
      body.push(...renderModelLines(theme, stats, width, maxTableLines));
      description = MODELS_DESCRIPTION;
      hints = [
        ["r", "Cycle dates"],
        ["Tab", "Overview"],
        ["Esc", "Close"],
      ];
    }
    const hintsLine = renderHintsLine(theme, hints, width);
    const tailWithDesc = [
      "",
      ...wrapDescriptionLines(theme, description, width),
      "",
      hintsLine,
      "",
      border,
    ];
    const tailNoDesc = ["", hintsLine, "", border];
    const fit = (head: string[], tail: string[]): string[] => {
      const total = head.length + tail.length;
      if (total <= rows) {
        return [...head, ...Array(rows - total).fill(""), ...tail];
      }
      if (tail.length >= rows) {
        return tail.slice(tail.length - rows);
      }
      const room = Math.max(0, rows - tail.length);
      const trimmed = head.slice(0, Math.max(1, room));
      while (trimmed.length < room) trimmed.push("");
      return [...trimmed, ...tail];
    };
    const fullLen = prefix.length + body.length + tailWithDesc.length;
    const noDescLen = prefix.length + body.length + tailNoDesc.length;
    let fitted: string[];
    if (fullLen <= rows) {
      fitted = fit([...prefix, ...body], tailWithDesc);
    } else if (noDescLen <= rows) {
      fitted = fit([...prefix, ...body], tailNoDesc);
    } else {
      const reduced = [...body];
      for (
        let i = reduced.length - 1;
        i >= 0 && prefix.length + reduced.length + tailNoDesc.length > rows;
        i--
      ) {
        if (reduced[i] === "") reduced.splice(i, 1);
      }
      fitted = fit([...prefix, ...reduced], tailNoDesc);
    }
    this.cachedLines = fitted;
    this.cachedWidth = width;
    this.cachedRows = rows;
    return fitted;
  }

  invalidate(): void {
    this.clearCache();
    this.rangeCache.clear();
  }

  private clearCache(): void {
    this.cachedLines = undefined;
    this.cachedWidth = undefined;
    this.cachedRows = undefined;
  }

  private stats(): RangeStats {
    const days = RANGES[this.rangeIndex]!.days;
    const cached = this.rangeCache.get(days);
    if (cached !== undefined && dateKeyOf(cached.toTime) === dateKeyOf(Date.now())) {
      return cached;
    }
    const fresh = computeRange(this.data, days);
    this.rangeCache.set(days, fresh);
    return fresh;
  }
}

export { addDays, buildHeatmap, collectAll, computeLevelThresholds, computeRange, computeStreaks, dateKeyOf, diffDays, levelFor, mondayOf, parseDays, renderModelLines };

export default function (pi: ExtensionAPI) {
  const command = {
    description: "Show pi session token and cost usage. Args: 0 for all time, 7, 30, 30d, --days 7, --days=7. TUI keys: r cycles range, Tab switches view, Esc closes",
    getArgumentCompletions: (prefix: string): AutocompleteItem[] | null => {
      const completions: AutocompleteItem[] = [
        { value: "0", label: "0", description: "All time view" },
        { value: "7", label: "7", description: "Last 7 days" },
        { value: "30", label: "30", description: "Last 30 days (default)" },
      ];
      const token = prefix.trim().split(/\s+/).pop()?.split("=").pop() ?? "";
      const filtered = completions.filter((item) => item.value.startsWith(token));
      return filtered.length > 0 ? filtered : null;
    },
    handler: async (args: string | undefined, ctx: ExtensionCommandContext) => {
      const days = parseDays(args);
      const data = await collectAll();
      if (ctx.mode !== "tui") {
        console.log(buildMarkdown(computeRange(data, days), data));
        return;
      }
      await ctx.ui.custom<void>(
        (tui, theme, _keybindings, done) => {
          const view = new TokenStatsView(theme, data, days, done, () => tui.terminal.rows);
          return {
            render: (width: number) => view.render(width),
            invalidate: () => view.invalidate(),
            handleInput: (input: string) => {
              view.handleInput(input);
              tui.requestRender();
            },
          };
        },
        { overlay: true, overlayOptions: { width: "100%", maxHeight: "100%", margin: 0 } },
      );
    },
  };

  pi.registerCommand("tokens", { ...command });
  pi.registerCommand("token-stats", { ...command });
}
