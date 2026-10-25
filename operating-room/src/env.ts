// Bindings, vars and secrets the Worker sees (see wrangler.jsonc).

export interface AppEnv {
  DB: D1Database;
  ASSETS: Fetcher;
  ROOM_NAME?: string;
  PUBLISH_HOST_SUFFIX?: string;
  ROOM_PASSWORD: string;
  SESSION_SECRET: string;
  /** Home page link to the trading terminal Worker. */
  TERMINAL_URL?: string;
}

export const roomName = (env: AppEnv) => env.ROOM_NAME?.trim() || "Operating Room";
