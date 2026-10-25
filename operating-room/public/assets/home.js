// Home: the unified vision at the core, pods orbiting it, eras, and the coordination board.
// Content comes from /data/vision.json and /data/pods.json (generated from the treatise).

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
      const r = 24 + Math.min(14, (p.ideas?.length ?? 0) * 1.2);
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
    if (g) openPod(g.dataset.id);
  });
  svg.addEventListener("keydown", (e) => {
    const g = e.target.closest(".pod");
    if (g && (e.key === "Enter" || e.key === " ")) {
      e.preventDefault();
      openPod(g.dataset.id);
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

function renderPods(pods) {
  $("#podList").innerHTML = pods
    .map((p) => {
      const st = statusOf(p);
      return `<button class="podcard" type="button" data-id="${esc(p.id)}"><div class="row1"><h3>${esc(p.name)}</h3><span class="tag ${st.cls}">${st.label}</span></div>
        <p>${esc(p.tagline)}</p><p class="mono small" style="color:var(--dim)">${esc(p.era ?? "")} · ${(p.ideas ?? []).length} ideas</p></button>`;
    })
    .join("");
  $("#podList").addEventListener("click", (e) => {
    const b = e.target.closest(".podcard");
    if (b) openPod(b.dataset.id);
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
  $("#moveLanes").innerHTML = Object.entries(lanes)
    .map(
      ([k, items]) => `<div class="lane"><h3>${titles[k]} · ${items.length}</h3>${items
        .map(
          (m) => `<label class="move${done[m.key] ? " done" : ""}"><input type="checkbox" data-key="${esc(m.key)}" ${done[m.key] ? "checked" : ""}>
            <span><span class="pod">${esc(m.pod.short ?? m.pod.name)}</span>${esc(m.text)}</span></label>`,
        )
        .join("")}</div>`,
    )
    .join("");
  $("#moveLanes").addEventListener("change", (e) => {
    const key = e.target.dataset.key;
    if (!key) return;
    const d = store.get("room.moves.done", {});
    d[key] = e.target.checked;
    store.set("room.moves.done", d);
    e.target.closest(".move").classList.toggle("done", e.target.checked);
  });
}

function openPod(id) {
  const p = PODS.find((x) => x.id === id);
  if (!p) return;
  const st = statusOf(p);
  const byId = new Map(PODS.map((x) => [x.id, x]));
  $("#drawerBody").innerHTML = `
    <span class="tag ${st.cls}" style="font:600 10px var(--mono);padding:4px 6px;border-radius:5px">${st.label}</span>
    <h2>${esc(p.name)}</h2><p class="tagline">${esc(p.tagline)}</p>
    <p class="muted mono small">${esc(p.era ?? "")}${p.status ? " · " + esc(p.status) : ""}</p>
    <p>${esc(p.summary)}</p>
    ${p.numbers?.length ? `<h3>Numbers</h3><div class="nums">${p.numbers.map((n) => `<div><b>${esc(n.value)}</b><span>${esc(n.label)}</span></div>`).join("")}</div>` : ""}
    ${p.ideas?.length ? `<h3>Ideas · ${p.ideas.length}</h3><ul>${p.ideas.map((i) => `<li class="idea"><b>${esc(i.name)}</b> — ${esc(i.one_liner)} <span class="d">${esc(i.date ?? "")}</span></li>`).join("")}</ul>` : ""}
    ${p.next_moves?.length ? `<h3>Next moves</h3><ul>${p.next_moves.map((m) => `<li>${esc(m)}</li>`).join("")}</ul>` : ""}
    ${p.people?.length ? `<h3>People</h3><ul>${p.people.map((m) => `<li>${esc(m)}</li>`).join("")}</ul>` : ""}
    ${p.feeds?.length ? `<h3>Coordinates with</h3><ul>${p.feeds.filter((f) => byId.has(f)).map((f) => `<li><a href="#" data-pod="${esc(f)}">${esc(byId.get(f).name)}</a></li>`).join("")}</ul>` : ""}
    ${p.chapter ? `<h3>Read</h3><p><a href="/treatise/#${esc(p.chapter)}">Treatise chapter →</a></p>` : ""}`;
  $("#drawer").classList.add("open");
  $("#drawer").setAttribute("aria-hidden", "false");
  $("#scrim").classList.add("open");
  for (const g of document.querySelectorAll(".orbit .pod")) g.classList.toggle("sel", g.dataset.id === id);
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
    const a = e.target.closest("[data-pod]");
    if (a) {
      e.preventDefault();
      openPod(a.dataset.pod);
    }
  });
  const [session, config, vision, pods] = await Promise.all([
    getJson("/api/session").catch(() => ({})),
    getJson("/api/config").catch(() => ({})),
    getJson("/data/vision.json"),
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
  PODS = pods;
  renderHero(vision);
  renderOrbit(pods, vision.core ?? {});
  renderPods(pods);
  renderMoves(pods);
  const open = new URLSearchParams(location.hash.slice(1)).get("pod");
  if (open) openPod(open);
}

init().catch((err) => {
  $("#thesis").textContent = `Could not load the room: ${err.message}`;
});
