// Home: the unified vision at the core, the orgs orbiting it (each a group of pods), eras, and the
// coordination board. Content comes from /data/vision.json, /data/orgs.json and /data/pods.json,
// generated from the treatise by scripts/build_treatise.py.

const $ = (s, r = document) => r.querySelector(s);
const esc = (s) => String(s ?? "").replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const STATUS = {
  active: { color: "var(--green)", label: "Active", cls: "st-active" },
  superseded: { color: "var(--amber)", label: "Superseded", cls: "st-superseded" },
  parked: { color: "var(--dim)", label: "Parked", cls: "st-parked" },
  idea: { color: "var(--indigo)", label: "Idea", cls: "st-idea" },
};
const statusOf = (p) => STATUS[(p.status ?? "idea").split(/\s/)[0]] ?? STATUS.idea;
const store = {
  get(k, f) {
    try {
      return JSON.parse(localStorage.getItem(k)) ?? f;
    } catch {
      return f;
    }
  },
  set(k, v) {
    try {
      localStorage.setItem(k, JSON.stringify(v));
    } catch {
      /* ignore */
    }
  },
};

async function getJson(path) {
  const res = await fetch(path, { credentials: "same-origin" });
  if (!res.ok) throw new Error(`${path}: HTTP ${res.status}`);
  return res.json();
}

function renderHero(vision) {
  $("#thesis").textContent = vision.thesis;
  if (vision.kicker) $("#kicker").textContent = vision.kicker;
  $("#stats").innerHTML = vision.stats.map((s) => `<div class="stat"><b>${esc(s.value)}</b><span>${esc(s.label)}</span></div>`).join("");
  $("#erasList").innerHTML = vision.eras
    .map((e) => `<div class="era"><span class="d">${esc(e.when)}</span><h4>${esc(e.name)}</h4><p>${esc(e.text)}</p></div>`)
    .join("");
}

function renderOrbit(pods, core) {
  const svg = $("#orbit");
  const R = 236;
  const n = pods.length;
  const pos = new Map(
    pods.map((p, i) => {
      const a = -Math.PI / 2 + (i / n) * Math.PI * 2;
      return [p.id, { x: Math.cos(a) * R, y: Math.sin(a) * R }];
    }),
  );
  const links = [];
  for (const p of pods) {
    for (const f of p.feeds ?? []) {
      if (!pos.has(f) || f === p.id) continue;
      const a = pos.get(p.id);
      const b = pos.get(f);
      // Curve through a point pulled toward the center so links read as flows through the core.
      const mx = (a.x + b.x) * 0.25;
      const my = (a.y + b.y) * 0.25;
      links.push(`<path class="link" data-a="${esc(p.id)}" data-b="${esc(f)}" d="M${a.x},${a.y} Q${mx},${my} ${b.x},${b.y}"/>`);
    }
  }
  const nodes = pods
    .map((p) => {
      const { x, y } = pos.get(p.id);
      const st = statusOf(p);
      const r = 26 + Math.min(16, (p.pods?.length ?? p.ideas?.length ?? 0) * 2.2);
      const name = p.short ?? p.name;
      return `<g class="pod" tabindex="0" role="button" aria-label="${esc(p.name)}" data-id="${esc(p.id)}" transform="translate(${x},${y})">
        <circle r="${r}" fill="color-mix(in srgb, ${st.color} 16%, #0b111b)" stroke="${st.color}"/>
        <text y="2">${esc(name.length > 16 ? name.slice(0, 15) + "…" : name)}</text>
        <text class="era" y="${r + 14}">${esc(p.era ?? "")}</text></g>`;
    })
    .join("");
  svg.innerHTML = `<defs><radialGradient id="coreGlow"><stop offset="0%" stop-color="#5eead4" stop-opacity="0.55"/><stop offset="55%" stop-color="#818cf8" stop-opacity="0.25"/><stop offset="100%" stop-color="#05070b" stop-opacity="0"/></radialGradient></defs>
    <circle class="ring" r="${R}"/><circle class="ring" r="${R * 0.55}"/>
    ${pods.map((p) => `<line class="spoke" x1="0" y1="0" x2="${pos.get(p.id).x}" y2="${pos.get(p.id).y}"/>`).join("")}
    ${links.join("")}
    <g class="core"><circle r="92"/><text y="-6">${esc(core.symbol ?? "X → ∞")}</text><text class="sub" y="20">${esc((core.caption ?? "THE PRIME VISION").toUpperCase())}</text></g>
    ${nodes}`;
  svg.addEventListener("click", (e) => {
    const g = e.target.closest(".pod");
    if (g) openOrg(g.dataset.id);
  });
  svg.addEventListener("keydown", (e) => {
    const g = e.target.closest(".pod");
    if (g && (e.key === "Enter" || e.key === " ")) {
      e.preventDefault();
      openOrg(g.dataset.id);
    }
  });
  svg.addEventListener("mouseover", (e) => {
    const id = e.target.closest(".pod")?.dataset.id;
    for (const l of svg.querySelectorAll(".link")) l.classList.toggle("hot", !!id && (l.dataset.a === id || l.dataset.b === id));
  });
  $("#legend").innerHTML = Object.values(STATUS)
    .map((s) => `<span><i style="background:${s.color}"></i>${s.label}</span>`)
    .join("");
}

let PODS = [];
let ORGS = [];
let TREATISE = "/treatise/";
const podById = () => new Map(PODS.map((p) => [p.id, p]));

function renderPods(orgs) {
  const byId = podById();
  $("#podList").innerHTML = orgs
    .filter((o) => o.pods.length)
    .map((o) => {
      const st = statusOf(o);
      return `<button class="podcard" type="button" data-org="${esc(o.id)}"><div class="row1"><h3>${esc(o.name)}</h3><span class="tag ${st.cls}">${st.label}</span></div>
        <p>${esc(o.tagline)}</p>
        <p class="mono small" style="color:var(--dim)">${esc(o.era ?? "")} · ${o.pods.length} pods · ${o.pods.reduce((n, id) => n + (byId.get(id)?.ideas?.length ?? 0), 0)} ideas</p>
        <p class="small" style="margin-top:8px">${o.pods.map((id) => esc(byId.get(id)?.name ?? id)).join(" · ")}</p></button>`;
    })
    .join("");
  $("#podList").addEventListener("click", (e) => {
    const b = e.target.closest(".podcard");
    if (b) openOrg(b.dataset.org);
  });
}

function renderMoves(pods) {
  const done = store.get("room.moves.done", {});
  const lanes = { now: [], next: [], later: [] };
  for (const p of pods) {
    (p.next_moves ?? []).forEach((m, i) => {
      const lane = i === 0 && statusOf(p) === STATUS.active ? "now" : i <= 1 ? "next" : "later";
      lanes[lane].push({ pod: p, text: m, key: `${p.id}:${i}` });
    });
  }
  const titles = { now: "Now", next: "Next", later: "Later" };
  const SHOWN = 10;
  const item = (m, hidden) => `<label class="move${done[m.key] ? " done" : ""}"${hidden ? " hidden" : ""}><input type="checkbox" data-key="${esc(m.key)}" ${done[m.key] ? "checked" : ""}>
            <span><span class="pod">${esc(m.pod.short ?? m.pod.name)}</span>${esc(m.text)}</span></label>`;
  $("#moveLanes").innerHTML = Object.entries(lanes)
    .map(
      ([k, items]) => `<div class="lane"><h3>${titles[k]} · ${items.length}</h3>${items.map((m, i) => item(m, i >= SHOWN)).join("")}
        ${items.length > SHOWN ? `<button type="button" class="btn ghost more" data-more>Show all ${items.length}</button>` : ""}</div>`,
    )
    .join("");
  $("#moveLanes").addEventListener("click", (e) => {
    const b = e.target.closest("[data-more]");
    if (!b) return;
    for (const m of b.parentElement.querySelectorAll(".move[hidden]")) m.hidden = false;
    b.remove();
  });
  $("#moveLanes").addEventListener("change", (e) => {
    const key = e.target.dataset.key;
    if (!key) return;
    const d = store.get("room.moves.done", {});
    d[key] = e.target.checked;
    store.set("room.moves.done", d);
    e.target.closest(".move").classList.toggle("done", e.target.checked);
  });
}

function podBlock(p) {
  const st = statusOf(p);
  return `<details class="podblock" id="pod-${esc(p.id)}"><summary><b>${esc(p.name)}</b> <span class="tag ${st.cls}" style="font:600 9.5px var(--mono);padding:3px 5px;border-radius:4px">${st.label}</span><br><span class="muted small">${esc(p.tagline)}</span></summary>
    <p class="muted mono small">${esc(p.era ?? "")}${p.status ? " · " + esc(p.status) : ""}</p>
    <p>${esc(p.summary)}</p>
    ${p.numbers?.length ? `<div class="nums">${p.numbers.map((n) => `<div><b>${esc(n.value)}</b><span>${esc(n.label)}</span></div>`).join("")}</div>` : ""}
    ${p.ideas?.length ? `<h4>Ideas · ${p.ideas.length}</h4><ul>${p.ideas.map((i) => `<li class="idea"><b>${esc(i.name)}</b> — ${esc(i.one_liner)} <span class="d">${esc(i.date ?? "")}</span></li>`).join("")}</ul>` : ""}
    ${p.next_moves?.length ? `<h4>Next moves</h4><ul>${p.next_moves.map((m) => `<li>${esc(m)}</li>`).join("")}</ul>` : ""}
    ${p.people?.length ? `<h4>People</h4><ul>${p.people.map((m) => `<li>${esc(m)}</li>`).join("")}</ul>` : ""}
    ${p.chapter ? `<p><a href="${TREATISE}#${esc(p.chapter)}">Read in the treatise →</a></p>` : ""}
  </details>`;
}

function openOrg(id, focusPod) {
  const o = ORGS.find((x) => x.id === id);
  if (!o) return;
  const st = statusOf(o);
  const byId = podById();
  const orgName = new Map(ORGS.map((x) => [x.id, x.name]));
  $("#drawerBody").innerHTML = `
    <span class="tag ${st.cls}" style="font:600 10px var(--mono);padding:4px 6px;border-radius:5px">${st.label}</span>
    <h2>${esc(o.name)}</h2><p class="tagline">${esc(o.tagline)}</p>
    <p class="muted mono small">${esc(o.era ?? "")} · ${o.pods.length} pods</p>
    <p>${esc(o.summary)}</p>
    ${o.feeds?.length ? `<h3>Coordinates with</h3><p>${o.feeds.map((f) => `<a href="#" data-org="${esc(f)}">${esc(orgName.get(f) ?? f)}</a>`).join(" · ")}</p>` : ""}
    <h3>Pods</h3>${o.pods.map((pid) => byId.get(pid)).filter(Boolean).map(podBlock).join("")}
    ${o.chapter ? `<h3>Read</h3><p><a href="${TREATISE}#${esc(o.chapter)}">Treatise chapter →</a></p>` : ""}`;
  if (focusPod) {
    const d = document.getElementById(`pod-${focusPod}`);
    if (d) {
      d.open = true;
      setTimeout(() => d.scrollIntoView({ block: "start" }), 50);
    }
  }
  $("#drawer").classList.add("open");
  $("#drawer").setAttribute("aria-hidden", "false");
  $("#scrim").classList.add("open");
  for (const g of document.querySelectorAll(".orbit .pod")) g.classList.toggle("sel", g.dataset.id === id);
}

function openPod(id) {
  const p = podById().get(id);
  if (p) openOrg(p.org, id);
}

function closePod() {
  $("#drawer").classList.remove("open");
  $("#drawer").setAttribute("aria-hidden", "true");
  $("#scrim").classList.remove("open");
}

async function init() {
  $("#drawerClose").addEventListener("click", closePod);
  $("#scrim").addEventListener("click", closePod);
  document.addEventListener("keydown", (e) => e.key === "Escape" && closePod());
  $("#drawerBody").addEventListener("click", (e) => {
    const a = e.target.closest("[data-org]");
    if (a) {
      e.preventDefault();
      openOrg(a.dataset.org);
    }
  });
  // A single-file edition embeds its data as window.ROOM_DATA instead of serving /data and /api.
  const embedded = window.ROOM_DATA;
  const [session, config, vision, orgs, pods] = embedded
    ? [embedded.session ?? {}, embedded.config ?? {}, embedded.vision, embedded.orgs, embedded.pods]
    : await Promise.all([
        getJson("/api/session").catch(() => ({})),
        getJson("/api/config").catch(() => ({})),
        getJson("/data/vision.json"),
        getJson("/data/orgs.json"),
        getJson("/data/pods.json"),
      ]);
  for (const el of document.querySelectorAll(".owner-only")) el.hidden = session.role !== "owner";
  if (config.roomName) {
    $("#roomName").textContent = config.roomName;
    document.title = config.roomName;
  }
  const term = config.terminalUrl;
  for (const a of [$("#navTerminal"), $("#tileTerminal")]) {
    if (term) a.href = term;
    else a.hidden = true;
  }
  if (config.treatiseUrl) {
    TREATISE = config.treatiseUrl;
    for (const a of document.querySelectorAll('a[href^="/treatise/"]')) a.href = TREATISE + a.getAttribute("href").replace(/^\/treatise\/?/, "");
  }
  PODS = pods;
  ORGS = orgs.filter((o) => o.pods.length);
  renderHero(vision);
  renderOrbit(ORGS, vision.core ?? {});
  renderPods(ORGS);
  renderMoves(pods);
  const hash = new URLSearchParams(location.hash.slice(1));
  if (hash.get("org")) openOrg(hash.get("org"));
  else if (hash.get("pod")) openPod(hash.get("pod"));
}

init().catch((err) => {
  $("#thesis").textContent = `Could not load the room: ${err.message}`;
});
