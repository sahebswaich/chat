import { cloudflareTest, readD1Migrations } from "@cloudflare/vitest-plugin";
import { defineConfig } from "vitest/config";

// Tests run inside workerd (the real Workers runtime) with a local D1 database.
const TEST_SECRETS = { ROOM_PASSWORD: "test-password", SESSION_SECRET: "test-session-secret" };
for (const [key, value] of Object.entries(TEST_SECRETS)) process.env[key] ??= value;

export default defineConfig(async () => {
  const migrations = await readD1Migrations("./migrations");
  return {
    plugins: [
      cloudflareTest({
        wrangler: { configPath: "./wrangler.jsonc" },
        miniflare: {
          bindings: { TEST_MIGRATIONS: migrations, ...TEST_SECRETS, PUBLISH_HOST_SUFFIX: "pub.example.com" },
        },
      }),
    ],
    test: {
      setupFiles: ["./test/setup.ts"],
      fileParallelism: false,
    },
  };
});
