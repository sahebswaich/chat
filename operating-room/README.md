# Operating Room

Your home page: the unified **X → ∞** vision with its pods, the **Prime Treatise** (paper pages,
Save as PDF, a discussion thread on every section), publishing, and share links. One
**Cloudflare Worker** + one **D1** database, behind a password. The trading terminal is its own
Worker in [`../terminal`](../terminal).

```
src/index.ts    router + the gate in front of every page     public/index.html      home (vision, pods, moves)
src/gate.ts     password, signed cookies, share links        public/treatise/       the treatise (built)
src/publish.ts  /p/<slug>, subdomains, custom hosts           public/publish/        owner tools
src/comments.ts discussion threads                           public/assets/         css + js
treatise/       chapter sources (markdown) + pods + vision   scripts/               treatise build
```

## Deploy (Mac, about 10 minutes)

You need Node.js 22.12+ and a free Cloudflare account.

```bash
cd ~/chat/operating-room
npm install
npx wrangler login

# Secrets go in a private temp file, never on the command line.
SECRETS_FILE=$(mktemp)
cat > "$SECRETS_FILE" <<EOF
ROOM_PASSWORD=pick-a-long-password
SESSION_SECRET=$(openssl rand -hex 32)
EOF
npx wrangler deploy --secrets-file "$SECRETS_FILE"
rm "$SECRETS_FILE"
npx wrangler d1 migrations apply operating-room --remote   # answer "y"
```

Open the `https://operating-room.<you>.workers.dev` address it prints and sign in.
Change the password later with `npx wrangler secret put ROOM_PASSWORD` (changing
`SESSION_SECRET` the same way signs everyone out).

Set `TERMINAL_URL` in `wrangler.jsonc` to the terminal's address so the home page links to it.

## Your own domain (DNS)

Your domain must use Cloudflare DNS (Cloudflare dashboard → Add a site).

**The room on a hostname** — in `wrangler.jsonc`, uncomment `routes` and set
`{ "pattern": "room.yourdomain.com", "custom_domain": true }`, then `npx wrangler deploy`.
Cloudflare creates the DNS record and certificate itself.

**Every publication on its own subdomain** (`<slug>.pub.yourdomain.com`):
1. `wrangler.jsonc` → `"PUBLISH_HOST_SUFFIX": "pub.yourdomain.com"` and add the route
   `{ "pattern": "*.pub.yourdomain.com/*", "zone_name": "yourdomain.com" }`.
2. Cloudflare DNS → add record: type `AAAA`, name `*.pub`, content `100::`, Proxied (orange cloud).
3. `npx wrangler deploy`. A page published as `glx-memo` is now at `glx-memo.pub.yourdomain.com`.

**One page on any hostname** (e.g. `memo.yourdomain.com`): dashboard → Workers → operating-room
→ Settings → Domains & Routes → Add → Custom domain → `memo.yourdomain.com`. Then in
Publish, put that hostname in "Own hostname". Each hostname serves only that page.

## Publishing

Publish → write markdown (or paste HTML) → Publish. Markdown pages use the paper template
(Save as PDF, discussion threads); HTML pages are served exactly as written in a sandbox that
can't touch the room's cookies or API. "Private" pages need the password or a share link;
"Public" pages open for anyone with the address. Scripted publishing:

```bash
curl -X PUT https://room.yourdomain.com/api/publications/my-page \
  -H "cookie: room_session=…" -H "content-type: application/json" \
  -d '{"title":"My page","kind":"markdown","visibility":"private","body":"# Hello"}'
```

## Share links (Excalidraw-style)

Publish → Share links → pick what it opens (`/treatise`, `/p/glx-memo`, `/` for everything),
read-only or read + comment, optional expiry → Create link. Whoever opens the link is in, no
password; they see only that part of the room. "Turn off" kills the link and every session it
started. Comment links ask for a name the first time someone posts.

## The treatise

Chapters live in `treatise/ch*.md` (dialect in `treatise/README.md`); the home page's pods
in `treatise/pods/*.json`, its hero and eras in `treatise/vision.json`. Rebuild after editing:

```bash
pip install markdown
python3 scripts/build_treatise.py            # → public/treatise/, public/data/
python3 scripts/build_treatise.py --artifact /tmp/prime-treatise.html   # single-file edition
npx wrangler deploy
```

## Test

```bash
npm test         # gate, share links, discussion, publishing (workerd + local D1)
npm run typecheck
```
