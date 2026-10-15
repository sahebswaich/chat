import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

// Tests run inside workerd (the real Workers runtime) with a local D1 database.
// The Claude API is never called: ANTHROPIC_BASE_URL points at a fake host and
// test/helpers.ts intercepts `fetch` to return recorded-style SSE streams.
export default defineConfig(async () => {
  const migrations = await readD1Migrations("./migrations");
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          bindings: {
            TEST_MIGRATIONS: migrations,
            ANTHROPIC_API_KEY: "sk-ant-test-key",
            ANTHROPIC_BASE_URL: "https://claude-api.test",
            ADMIN_TOKEN: "test-admin-token",
          },
        },
      }),
    ],
    test: {
      setupFiles: ["./test/setup.ts"],
      // Test files share one local D1 database; run them one at a time so each
      // test can start from empty tables.
      fileParallelism: false,
    },
  };
});
