interface Env {
  ROUTE_CACHE: KVNamespace;
  USER_WATCHLISTS: KVNamespace;
  STEAMDB_BASE_URL: string;
  PARSER_VERSION: string;
}

type RouteMode = "native" | "webFallback";
type RouteGroup = "home" | "search" | "app" | "charts" | "sales" | "calendar" | "rankings" | "utility" | "entities" | "unknown";

interface RouteDescriptor {
  path: string;
  title: string;
  mode: RouteMode;
  group: RouteGroup;
  enabled: boolean;
}

interface GatewayApp {
  id: number;
  name: string;
  type: string;
  currentPrice: number | null;
  currency: string | null;
  discountPercent: number | null;
  initialPrice: number | null;
  platforms: Array<"windows" | "mac" | "linux">;
  developer: string | null;
  publisher: string | null;
  currentPlayers: number | null;
  peak24h: number | null;
  allTimePeak: number | null;
}

interface WatchlistPayload {
  installationID: string;
  appIDs: number[];
  updatedAt: string;
}

interface CachedValue<T> {
  value: T;
  updatedAt: string;
}

const ROUTES: RouteDescriptor[] = [
  { path: "/", title: "Home", mode: "native", group: "home", enabled: true },
  { path: "/search", title: "Search", mode: "native", group: "search", enabled: true },
  { path: "/instantsearch", title: "Instant Search", mode: "native", group: "search", enabled: true },
  { path: "/app/:id", title: "App Overview", mode: "native", group: "app", enabled: true },
  { path: "/app/:id/charts", title: "App Charts", mode: "native", group: "charts", enabled: true },
  { path: "/sales", title: "Sales", mode: "native", group: "sales", enabled: true },
  { path: "/charts", title: "Charts", mode: "native", group: "charts", enabled: true },
  { path: "/calendar", title: "Calendar", mode: "native", group: "calendar", enabled: true },
  { path: "/pricechanges", title: "Price Changes", mode: "native", group: "sales", enabled: true },
  { path: "/upcoming", title: "Upcoming", mode: "native", group: "calendar", enabled: true },
  { path: "/freepackages", title: "Free Packages", mode: "native", group: "sales", enabled: true },
  { path: "/bundles", title: "Bundles", mode: "native", group: "sales", enabled: true },
  { path: "/top-rated", title: "Top Rated", mode: "native", group: "rankings", enabled: true },
  { path: "/topsellers/global", title: "Top Sellers (Global)", mode: "native", group: "rankings", enabled: true },
  { path: "/topsellers/weekly", title: "Top Sellers (Weekly)", mode: "native", group: "rankings", enabled: true },
  { path: "/mostfollowed", title: "Most Followed", mode: "native", group: "rankings", enabled: true },
  { path: "/mostwished", title: "Most Wished", mode: "native", group: "rankings", enabled: true },
  { path: "/wishlists", title: "Wishlists", mode: "native", group: "rankings", enabled: true },
  { path: "/dailyactiveusers", title: "Daily Active Users", mode: "native", group: "rankings", enabled: true },
  { path: "/calculator", title: "Calculator", mode: "webFallback", group: "utility", enabled: true },
  { path: "/tags", title: "Tags", mode: "webFallback", group: "utility", enabled: true },
  { path: "/patchnotes", title: "Patch Notes", mode: "webFallback", group: "utility", enabled: true },
  { path: "/events", title: "Events", mode: "webFallback", group: "utility", enabled: true },
  { path: "/year", title: "Year in Review", mode: "webFallback", group: "utility", enabled: true },
  { path: "/developer/:id", title: "Developer", mode: "webFallback", group: "entities", enabled: true },
  { path: "/publisher/:id", title: "Publisher", mode: "webFallback", group: "entities", enabled: true },
  { path: "/sub/:id", title: "Package", mode: "webFallback", group: "entities", enabled: true },
  { path: "/bundle/:id", title: "Bundle", mode: "webFallback", group: "entities", enabled: true },
  { path: "/depot/:id", title: "Depot", mode: "webFallback", group: "entities", enabled: true }
];

const COLLECTION_ROUTE_MAP: Record<string, string> = {
  "top-rated": "/top-rated/",
  "topsellers-global": "/topsellers/global/",
  "topsellers-weekly": "/topsellers/weekly/",
  "mostfollowed": "/mostfollowed/",
  "mostwished": "/mostwished/",
  "wishlists": "/wishlists/",
  "dailyactiveusers": "/dailyactiveusers/",
  "sales": "/sales/",
  "charts": "/charts/",
  "calendar": "/calendar/",
  "pricechanges": "/pricechanges/",
  "upcoming": "/upcoming/",
  "freepackages": "/freepackages/",
  "bundles": "/bundles/"
};

const CACHE_TTL: Record<string, number> = {
  home: 300,
  search: 180,
  app: 300,
  charts: 300,
  collection: 300,
  watchlist: 60
};

export default {
  async fetch(request: Request, env: Env): Promise<Response> {
    try {
      if (request.method === "OPTIONS") {
        return withCors(new Response(null, { status: 204 }));
      }

      const url = new URL(request.url);
      const pathname = normalizePath(url.pathname);

      if (request.method === "GET" && pathname === "/v1/health") {
        return json(env, {
          status: "ok",
          parserVersion: env.PARSER_VERSION || "v1",
          timestamp: new Date().toISOString()
        });
      }

      if (request.method === "GET" && pathname === "/v1/navigation/routes") {
        return json(env, { routes: ROUTES });
      }

      if (request.method === "GET" && pathname === "/v1/home") {
        return await cachedJSON(env, "home", CACHE_TTL.home, async () => {
          const html = await fetchSteamDB(env, "/");
          const parsed = parseAppsFromHtml(html);
          return {
            trending: parsed.slice(0, 20),
            topSellers: parsed.slice(0, 20),
            mostPlayed: parsed.slice(0, 20),
            stale: false
          };
        });
      }

      if (request.method === "GET" && pathname === "/v1/search") {
        const query = (url.searchParams.get("q") || "").trim();
        const page = Number.parseInt(url.searchParams.get("page") || "1", 10);
        if (!query) {
          return badRequest(env, "Missing q query parameter.");
        }

        return await cachedJSON(env, `search:${query}:${page}`, CACHE_TTL.search, async () => {
          const html = await fetchSteamDB(env, "/search/", [
            ["q", query],
            ["a", "app"]
          ]);
          return {
            results: parseAppsFromHtml(html),
            page,
            total: null,
            stale: false
          };
        });
      }

      const appOverviewMatch = pathname.match(/^\/v1\/apps\/(\d+)\/overview$/);
      if (request.method === "GET" && appOverviewMatch) {
        const appID = Number.parseInt(appOverviewMatch[1], 10);
        return await cachedJSON(env, `app:${appID}:overview`, CACHE_TTL.app, async () => {
          const html = await fetchSteamDB(env, `/app/${appID}/`);
          const app = parseAppOverview(html, appID);
          return { app, stale: false };
        });
      }

      const appChartsMatch = pathname.match(/^\/v1\/apps\/(\d+)\/charts$/);
      if (request.method === "GET" && appChartsMatch) {
        const appID = Number.parseInt(appChartsMatch[1], 10);
        const range = (url.searchParams.get("range") || "month").toLowerCase();
        return await cachedJSON(env, `app:${appID}:charts:${range}`, CACHE_TTL.charts, async () => {
          const html = await fetchSteamDB(env, `/app/${appID}/charts/`);
          const parsed = parseChartPayload(html, appID);
          return { ...parsed, stale: false };
        });
      }

      const collectionMatch = pathname.match(/^\/v1\/collections\/([a-z0-9-]+)$/);
      if (request.method === "GET" && collectionMatch) {
        const kind = collectionMatch[1];
        const steamRoute = COLLECTION_ROUTE_MAP[kind];
        if (!steamRoute) {
          return badRequest(env, `Unknown collection kind: ${kind}`);
        }

        return await cachedJSON(env, `collection:${kind}`, CACHE_TTL.collection, async () => {
          const html = await fetchSteamDB(env, steamRoute);
          return {
            kind,
            items: parseAppsFromHtml(html),
            stale: false
          };
        });
      }

      const watchlistMatch = pathname.match(/^\/v1\/watchlist\/([^/]+)$/);
      if (watchlistMatch && request.method === "GET") {
        const installationID = sanitizeInstallationID(watchlistMatch[1]);
        const payload = await getWatchlist(env, installationID);
        return json(env, payload);
      }

      if (watchlistMatch && request.method === "PUT") {
        const installationID = sanitizeInstallationID(watchlistMatch[1]);
        const body = await request.json<Partial<WatchlistPayload>>();
        if (!Array.isArray(body.appIDs)) {
          return badRequest(env, "Body must contain appIDs array.");
        }

        const normalizedIDs = body.appIDs
          .map((item) => Number.parseInt(String(item), 10))
          .filter((item) => Number.isFinite(item) && item > 0);

        const payload: WatchlistPayload = {
          installationID,
          appIDs: [...new Set(normalizedIDs)],
          updatedAt: new Date().toISOString()
        };

        await env.USER_WATCHLISTS.put(`watchlist:${installationID}`, JSON.stringify(payload), {
          expirationTtl: CACHE_TTL.watchlist * 100
        });
        return json(env, payload);
      }

      return withCors(new Response("Not Found", { status: 404 }));
    } catch (error) {
      const message = error instanceof Error ? error.message : "Unexpected error";
      return json(env, { error: message }, 500);
    }
  }
};

async function getWatchlist(env: Env, installationID: string): Promise<WatchlistPayload> {
  const key = `watchlist:${installationID}`;
  const raw = await env.USER_WATCHLISTS.get(key);
  if (!raw) {
    return {
      installationID,
      appIDs: [],
      updatedAt: new Date().toISOString()
    };
  }

  try {
    const parsed = JSON.parse(raw) as WatchlistPayload;
    return {
      installationID,
      appIDs: parsed.appIDs || [],
      updatedAt: parsed.updatedAt || new Date().toISOString()
    };
  } catch {
    return {
      installationID,
      appIDs: [],
      updatedAt: new Date().toISOString()
    };
  }
}

async function cachedJSON<T>(
  env: Env,
  key: string,
  ttl: number,
  loader: () => Promise<T>
): Promise<Response> {
  const cacheKey = `route:${key}`;
  const cachedRaw = await env.ROUTE_CACHE.get(cacheKey);
  let cached: CachedValue<T> | null = null;

  if (cachedRaw) {
    try {
      cached = JSON.parse(cachedRaw) as CachedValue<T>;
    } catch {
      cached = null;
    }
  }

  try {
    const value = await loader();
    const payload: CachedValue<T> = {
      value,
      updatedAt: new Date().toISOString()
    };
    await env.ROUTE_CACHE.put(cacheKey, JSON.stringify(payload), { expirationTtl: ttl });
    return json(env, value);
  } catch (error) {
    if (cached) {
      const staleValue = addStaleFlag(cached.value);
      return json(env, staleValue, 200, { "X-Cache-Status": "stale-fallback" });
    }
    throw error;
  }
}

function addStaleFlag<T>(value: T): T {
  if (typeof value === "object" && value !== null) {
    return { ...(value as Record<string, unknown>), stale: true } as T;
  }
  return value;
}

async function fetchSteamDB(
  env: Env,
  path: string,
  query: Array<[string, string]> = []
): Promise<string> {
  const base = env.STEAMDB_BASE_URL || "https://steamdb.info";
  const url = new URL(path, base);
  for (const [key, value] of query) {
    url.searchParams.set(key, value);
  }

  const response = await fetch(url.toString(), {
    method: "GET",
    headers: {
      "User-Agent": "SteamDBCompanion-Worker/1.0 (+https://steamdb.info/)"
    }
  });

  if (response.status === 429) {
    throw new Error("SteamDB rate limit reached.");
  }

  if (!response.ok) {
    throw new Error(`SteamDB upstream error: ${response.status}`);
  }

  return await response.text();
}

function parseAppsFromHtml(html: string): GatewayApp[] {
  const rows = Array.from(html.matchAll(/<tr[^>]*data-appid="(\d+)"[^>]*>([\s\S]*?)<\/tr>/gi));
  const results: GatewayApp[] = [];
  const seen = new Set<number>();

  for (const row of rows) {
    const appID = Number.parseInt(row[1], 10);
    if (!Number.isFinite(appID) || appID <= 0 || seen.has(appID)) {
      continue;
    }

    const rowHtml = row[2];
    const linkMatch = rowHtml.match(/<a[^>]*href="\/app\/\d+\/"[^>]*>([\s\S]*?)<\/a>/i);
    const name = cleanupText(linkMatch ? linkMatch[1] : `App ${appID}`);
    const price = parsePrice(rowHtml);

    results.push({
      id: appID,
      name,
      type: "game",
      currentPrice: price?.value ?? null,
      currency: price ? "USD" : null,
      discountPercent: parseDiscount(rowHtml),
      initialPrice: price?.value ?? null,
      platforms: ["windows"],
      developer: null,
      publisher: null,
      currentPlayers: parseFirstNumber(rowHtml),
      peak24h: null,
      allTimePeak: null
    });
    seen.add(appID);
  }

  if (results.length > 0) {
    return results;
  }

  const fallbackMatches = Array.from(html.matchAll(/href="\/app\/(\d+)\/"[^>]*>([^<]+)<\/a>/gi));
  for (const match of fallbackMatches) {
    const appID = Number.parseInt(match[1], 10);
    if (!Number.isFinite(appID) || appID <= 0 || seen.has(appID)) {
      continue;
    }
    results.push({
      id: appID,
      name: cleanupText(match[2]),
      type: "game",
      currentPrice: null,
      currency: null,
      discountPercent: null,
      initialPrice: null,
      platforms: ["windows"],
      developer: null,
      publisher: null,
      currentPlayers: null,
      peak24h: null,
      allTimePeak: null
    });
    seen.add(appID);
    if (results.length >= 60) {
      break;
    }
  }

  return results;
}

function parseAppOverview(html: string, appID: number): GatewayApp {
  const titleMatch = html.match(/<h1[^>]*itemprop="name"[^>]*>([\s\S]*?)<\/h1>/i);
  const name = cleanupText(titleMatch ? titleMatch[1] : `App ${appID}`);
  const price = parsePrice(html);
  const players = parseFirstNumber(html);

  return {
    id: appID,
    name,
    type: "game",
    currentPrice: price?.value ?? null,
    currency: price ? "USD" : null,
    discountPercent: parseDiscount(html),
    initialPrice: price?.value ?? null,
    platforms: parsePlatforms(html),
    developer: parseLabelValue(html, "Developer"),
    publisher: parseLabelValue(html, "Publisher"),
    currentPlayers: players,
    peak24h: null,
    allTimePeak: null
  };
}

function parseChartPayload(html: string, appID: number) {
  const prices: Array<{ date: string; price: number; discount: number }> = [];
  const playerTrend: Array<{ date: string; players: number }> = [];

  const pairMatches = Array.from(html.matchAll(/\[(\d{10,13}),\s*([0-9.]+)\]/g)).slice(0, 96);
  for (const match of pairMatches) {
    const timestamp = Number.parseInt(match[1], 10);
    const value = Number.parseFloat(match[2]);
    if (!Number.isFinite(timestamp) || !Number.isFinite(value)) {
      continue;
    }

    const date = new Date(timestamp > 10_000_000_000 ? timestamp : timestamp * 1000).toISOString();
    playerTrend.push({ date, players: Math.round(value) });
  }

  return {
    appID,
    currency: "USD",
    priceHistory: prices,
    playerTrend,
    stale: false
  };
}

function parsePlatforms(html: string): Array<"windows" | "mac" | "linux"> {
  const lower = html.toLowerCase();
  const platforms: Array<"windows" | "mac" | "linux"> = [];

  if (lower.includes("windows")) {
    platforms.push("windows");
  }
  if (lower.includes("mac")) {
    platforms.push("mac");
  }
  if (lower.includes("linux")) {
    platforms.push("linux");
  }

  if (platforms.length === 0) {
    platforms.push("windows");
  }
  return platforms;
}

function parseLabelValue(html: string, label: string): string | null {
  const regex = new RegExp(`${label}[\\s\\S]{0,120}?<a[^>]*>([\\s\\S]*?)<\\/a>`, "i");
  const match = html.match(regex);
  return match ? cleanupText(match[1]) : null;
}

function parseDiscount(text: string): number | null {
  const match = text.match(/-([0-9]{1,2})%/);
  if (!match) return null;
  const value = Number.parseInt(match[1], 10);
  return Number.isFinite(value) ? value : null;
}

function parsePrice(text: string): { value: number } | null {
  if (/free/i.test(text)) {
    return null;
  }

  const match = text.match(/[$€£]\s*([0-9]+(?:\.[0-9]{1,2})?)/);
  if (!match) {
    return null;
  }

  const value = Number.parseFloat(match[1]);
  if (!Number.isFinite(value)) {
    return null;
  }

  return { value };
}

function parseFirstNumber(text: string): number | null {
  const match = text.match(/([0-9][0-9,]{1,})/);
  if (!match) {
    return null;
  }
  const numeric = Number.parseInt(match[1].replaceAll(",", ""), 10);
  return Number.isFinite(numeric) ? numeric : null;
}

function cleanupText(value: string): string {
  const withoutTags = value.replace(/<[^>]+>/g, " ");
  return decodeEntities(withoutTags).replace(/\s+/g, " ").trim();
}

function decodeEntities(value: string): string {
  return value
    .replaceAll("&amp;", "&")
    .replaceAll("&quot;", "\"")
    .replaceAll("&#39;", "'")
    .replaceAll("&lt;", "<")
    .replaceAll("&gt;", ">");
}

function normalizePath(path: string): string {
  if (!path || path === "/") return "/";
  const trimmed = path.trim();
  if (!trimmed.startsWith("/")) {
    return `/${trimmed}`;
  }
  return trimmed.endsWith("/") ? trimmed.slice(0, -1) || "/" : trimmed;
}

function sanitizeInstallationID(raw: string): string {
  return raw.replace(/[^a-zA-Z0-9_-]/g, "").slice(0, 80);
}

function badRequest(env: Env, message: string): Response {
  return json(env, { error: message }, 400);
}

function json(env: Env, payload: unknown, status = 200, extraHeaders: Record<string, string> = {}): Response {
  return withCors(new Response(JSON.stringify(payload), {
    status,
    headers: {
      "Content-Type": "application/json; charset=utf-8",
      "Cache-Control": "no-store",
      "X-Parser-Version": env.PARSER_VERSION || "v1",
      ...extraHeaders
    }
  }));
}

function withCors(response: Response): Response {
  const headers = new Headers(response.headers);
  headers.set("Access-Control-Allow-Origin", "*");
  headers.set("Access-Control-Allow-Methods", "GET,PUT,OPTIONS");
  headers.set("Access-Control-Allow-Headers", "Content-Type");
  return new Response(response.body, {
    status: response.status,
    headers
  });
}
