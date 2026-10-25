// Bindings, vars and secrets the Worker sees (see wrangler.jsonc).

export interface AppEnv {
  DB: D1Database;
  ASSETS: Fetcher;
  ROOM_NAME?: string;
  ROOM_PASSWORD: string;
  SESSION_SECRET: string;
  COINGECKO_API_KEY?: string;
  /** Tests point the market sources at fake hosts. */
  MARKET_BASE_OVERRIDE?: string;
}

export const roomName = (env: AppEnv) => env.ROOM_NAME?.trim() || "Terminal";
