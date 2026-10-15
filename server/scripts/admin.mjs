#!/usr/bin/env node
// Nimbus owner CLI: manage invites, users and reports on your Nimbus server.
// Node 20+, no dependencies. Run it through npm from the server/ folder:
//
//   npm run admin -- invite "James"                 make an invite (1 use, default daily limit)
//   npm run admin -- invite "Family" --uses 5 --limit 50
//   npm run admin -- invites                        list invites
//   npm run admin -- revoke-invite K7QM-2XPA        delete an unused invite
//   npm run admin -- users                          list people and today's usage
//   npm run admin -- revoke-user u_7k2m9qxz4t       cut someone off immediately
//   npm run admin -- reports                        answers people reported
//
// Add --json to any command for raw JSON output.
//
// Server and admin token come from the environment (NIMBUS_URL, NIMBUS_ADMIN_TOKEN)
// or from server/.nimbus-admin.json: {"url": "https://nimbus.<you>.workers.dev", "adminToken": "..."}
// (written by scripts/setup-mac.sh; git-ignored).

import { readFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";

const CONFIG_FILE = join(dirname(fileURLToPath(import.meta.url)), "..", ".nimbus-admin.json");

const USAGE = `Nimbus admin

Usage: npm run admin -- <command> [options]

Commands:
  invite <name> [--uses N] [--limit N]   Create an invite code (default: 1 use, server's daily limit)
  invites                                List invite codes
  revoke-invite <code>                   Delete an invite code (people who already joined keep access)
  users                                  List users with today's usage
  revoke-user <id>                       Revoke a user's access immediately
  reports                                Show reported answers (newest first)
  help                                   Show this help

Options:
  --json                                 Print the raw JSON response

Configuration (first match wins):
  NIMBUS_URL and NIMBUS_ADMIN_TOKEN environment variables, or
  ${CONFIG_FILE}
  containing {"url": "https://nimbus.<you>.workers.dev", "adminToken": "<ADMIN_TOKEN>"}`;

class CliError extends Error {}

function parseArgs(argv) {
  const positional = [];
  const flags = {};
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === "--") continue;
    if (arg.startsWith("--")) {
      const eq = arg.indexOf("=");
      const key = eq === -1 ? arg.slice(2) : arg.slice(2, eq);
      if (key === "json" || key === "help") {
        flags[key] = true;
      } else if (eq !== -1) {
        flags[key] = arg.slice(eq + 1);
      } else {
        const value = argv[i + 1];
        if (value === undefined || value.startsWith("--")) throw new CliError(`--${key} needs a value.`);
        flags[key] = value;
        i++;
      }
    } else if (arg === "-h") {
      flags.help = true;
    } else {
      positional.push(arg);
    }
  }
  return { positional, flags };
}

function wholeNumber(flags, key, min) {
  if (flags[key] === undefined) return undefined;
  const n = Number(flags[key]);
  if (!Number.isInteger(n) || n < min) throw new CliError(`--${key} must be a whole number of at least ${min}.`);
  return n;
}

function loadConfig() {
  let file = {};
  try {
    file = JSON.parse(readFileSync(CONFIG_FILE, "utf8"));
  } catch (err) {
    if (err.code !== "ENOENT") throw new CliError(`Could not read ${CONFIG_FILE}: ${err.message}`);
  }
  let url = (process.env.NIMBUS_URL || file.url || "").trim();
  const token = (process.env.NIMBUS_ADMIN_TOKEN || file.adminToken || "").trim();
  if (!url || !token) {
    throw new CliError(
      "Don't know which server to talk to.\n" +
        "Set NIMBUS_URL and NIMBUS_ADMIN_TOKEN, or create " +
        CONFIG_FILE +
        ' with {"url": "https://nimbus.<you>.workers.dev", "adminToken": "<ADMIN_TOKEN>"}.',
    );
  }
  if (!/^https?:\/\//i.test(url)) url = `https://${url}`;
  return { url: url.replace(/\/+$/, ""), token };
}

async function api(config, method, path, body) {
  let res;
  try {
    res = await fetch(config.url + path, {
      method,
      headers: {
        authorization: `Bearer ${config.token}`,
        ...(body !== undefined ? { "content-type": "application/json" } : {}),
      },
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });
  } catch (err) {
    throw new CliError(`Could not reach ${config.url}: ${err.cause?.message ?? err.message}`);
  }
  const text = await res.text();
  let data = null;
  if (text) {
    try {
      data = JSON.parse(text);
    } catch {
      data = text;
    }
  }
  if (!res.ok) {
    const message = data?.error?.message ?? (typeof data === "string" ? data.slice(0, 200) : res.statusText);
    if (res.status === 401) throw new CliError(`The server rejected the admin token (401). ${message}`);
    throw new CliError(`${method} ${path} failed (${res.status}): ${message}`);
  }
  return data;
}

function table(rows, columns) {
  if (rows.length === 0) return "(none)";
  const cells = rows.map((row) => columns.map(([, get]) => String(get(row) ?? "")));
  const widths = columns.map(([title], i) => Math.max(title.length, ...cells.map((r) => r[i].length)));
  const line = (values) => values.map((v, i) => v.padEnd(widths[i])).join("  ").trimEnd();
  return [line(columns.map(([title]) => title)), line(widths.map((w) => "-".repeat(w))), ...cells.map(line)].join("\n");
}

const day = (iso) => (iso ? String(iso).replace("T", " ").slice(0, 16) : "never");

async function main() {
  const { positional, flags } = parseArgs(process.argv.slice(2));
  const [command, ...args] = positional;
  if (!command || command === "help" || flags.help) {
    console.log(USAGE);
    return;
  }
  const print = (data, human) => console.log(flags.json ? JSON.stringify(data, null, 2) : human(data));
  const need = (value, what) => {
    if (!value) throw new CliError(`Missing ${what}. Try: npm run admin -- help`);
    return value;
  };

  switch (command) {
    case "invite": {
      const name = need(args.join(" ").trim(), "the person's name, e.g. npm run admin -- invite \"James\"");
      const body = { name };
      const uses = wholeNumber(flags, "uses", 1);
      const limit = wholeNumber(flags, "limit", 0);
      if (uses !== undefined) body.uses = uses;
      if (limit !== undefined) body.dailyLimit = limit;
      const config = loadConfig();
      const invite = await api(config, "POST", "/admin/invites", body);
      print(invite, (d) =>
        [
          `Invite for ${name}: ${d.code}`,
          `Link: ${d.url}`,
          `Uses: ${uses ?? 1}${limit !== undefined ? `, daily limit ${limit}` : ""}`,
          "",
          "Send them the link. It has the TestFlight install button and an Open Nimbus button that signs them in.",
        ].join("\n"),
      );
      return;
    }
    case "invites": {
      const data = await api(loadConfig(), "GET", "/admin/invites");
      print(data, (d) =>
        table(d.invites, [
          ["CODE", (r) => r.code],
          ["NAME", (r) => r.name],
          ["USES LEFT", (r) => r.usesLeft],
          ["DAILY LIMIT", (r) => r.dailyLimit],
          ["CREATED (UTC)", (r) => day(r.createdAt)],
        ]),
      );
      return;
    }
    case "revoke-invite": {
      const code = need(args.join("").trim(), "the invite code");
      await api(loadConfig(), "DELETE", `/admin/invites/${encodeURIComponent(code)}`);
      print({ ok: true, code }, () => `Deleted invite ${code}. People who already joined with it keep access (use revoke-user).`);
      return;
    }
    case "users": {
      const data = await api(loadConfig(), "GET", "/admin/users");
      print(data, (d) =>
        table(d.users, [
          ["ID", (r) => r.id],
          ["NAME", (r) => r.name],
          ["DEVICE", (r) => r.device ?? ""],
          ["TODAY", (r) => r.usedToday],
          ["JOINED (UTC)", (r) => day(r.createdAt)],
          ["LAST SEEN (UTC)", (r) => day(r.lastSeenAt)],
          ["STATUS", (r) => (r.revoked ? "revoked" : "active")],
        ]),
      );
      return;
    }
    case "revoke-user": {
      const id = need(args[0]?.trim(), "the user id (see: npm run admin -- users)");
      await api(loadConfig(), "POST", `/admin/users/${encodeURIComponent(id)}/revoke`);
      print({ ok: true, id }, () => `Revoked ${id}. Their app is signed out on its next request.`);
      return;
    }
    case "reports": {
      const data = await api(loadConfig(), "GET", "/admin/reports");
      print(data, (d) => {
        if (d.reports.length === 0) return "No reports.";
        return d.reports
          .map((r) => {
            const who = r.userName ? `${r.userName} (${r.userId})` : r.userId ? r.userId : "deleted account";
            const convo = (Array.isArray(r.messages) ? r.messages : [])
              .map((m) => `  ${m.role === "user" ? "Q" : "A"}: ${String(m.content).replace(/\s+/g, " ").slice(0, 300)}`)
              .join("\n");
            const answer = String(r.answer ?? "").replace(/\s+/g, " ").slice(0, 500);
            return [`#${r.id}  ${day(r.createdAt)}  by ${who}  reason: ${r.reason}`, convo, answer ? `  Answer: ${answer}` : ""]
              .filter(Boolean)
              .join("\n");
          })
          .join("\n\n");
      });
      return;
    }
    default:
      throw new CliError(`Unknown command "${command}". Try: npm run admin -- help`);
  }
}

main().catch((err) => {
  console.error(err instanceof CliError ? `Error: ${err.message}` : err);
  process.exitCode = 1;
});
