// Terminal front end: plain ES module, no build step. State lives in the URL (shareable) and
// localStorage (per-viewer account rules); every panel reads its own /api/market/* endpoint.

const $ = (sel, root = document) => root.querySelector(sel);
const $$ = (sel, root = document) => [...root.querySelectorAll(sel)];

const store = {
  get(key, fallback) {
    try {
      const v = localStorage.getItem(key);
      return v === null ? fallback : JSON.parse(v);
    } catch {
      return fallback;
    }
  },
  set(key, value) {
    try {
      localStorage.setItem(key, JSON.stringify(value));
    } catch {
      /* private mode: settings just won't persist */
    }
  },
};

const DEFAULT_ACCOUNT = { equity: 100000, risk: 1000, levMajors: 5, levAlts: 2, oiFrac: 0.25, stopAtr: 1.5 };
const DEFAULT_WEIGHTS = { breakout: 3, momentum: 1.5, volume: 1, funding: 1, leverage: 1, oiFlow: 1, korea: 0.75 };

const params = new URLSearchParams(location.search);
const state = {
  tf: ["1d", "3d", "1w"].includes(params.get("tf")) ? params.get("tf") : store.get("tf", "1d"),
  exclude: params.get("excluded") ?? params.get("exclude") ?? store.get("exclude", ""),
  universe: Number(params.get("universe")) || store.get("universe", 30),
  pairSize: Number(params.get("pairSize")) || 25000,
  pairImpactBps: Number(params.get("pairImpactBps")) || 20,
  kraken: params.get("kraken") === "1",
  account: { ...DEFAULT_ACCOUNT, ...store.get("account", {}) },
  weights: { ...DEFAULT_WEIGHTS, ...store.get("weights", {}) },
  selected: null,
  ideas: [],
  isOwner: false,
};

// ---------- formatting ----------

const fmtUsd = (v) => {
  if (v === null || v === undefined || !Number.isFinite(v)) return "—";
  const a = Math.abs(v);
  if (a >= 1e12) return `$${(v / 1e12).toFixed(2)}T`;
  if (a >= 1e9) return `$${(v / 1e9).toFixed(2)}B`;
  if (a >= 1e6) return `$${(v / 1e6).toFixed(1)}M`;
  if (a >= 1e3) return `$${(v / 1e3).toFixed(1)}K`;
  return `$${v.toFixed(2)}`;
};
const fmtKrw = (v) => (Number.isFinite(v) ? (v >= 1e12 ? `₩${(v / 1e12).toFixed(2)}T` : `₩${(v / 1e9).toFixed(1)}B`) : "—");
const fmtPx = (v) => {
  if (!Number.isFinite(v)) return "—";
  if (v >= 1000) return v.toLocaleString("en-US", { maximumFractionDigits: 1 });
  if (v >= 1) return v.toFixed(3);
  return v.toPrecision(4);
};
const pct = (v, d = 2) => (v === null || v === undefined || !Number.isFinite(v) ? "—" : `${(v * 100).toFixed(d)}%`);
const signed = (v, d = 1) => (v === null || v === undefined || !Number.isFinite(v) ? "—" : `${v >= 0 ? "+" : ""}${v.toFixed(d)}`);
const cls = (v) => (v > 0 ? "pos" : v < 0 ? "neg" : "");
const esc = (s) => String(s).replace(/[&<>"']/g, (c) => ({ "&": "&amp;", "<": "&lt;", ">": "&gt;", '"': "&quot;", "'": "&#39;" })[c]);
const ago = (ms) => {
  const days = (Date.now() - ms) / 86400000;
  if (days < 1) return `${Math.max(1, Math.round(days * 24))}h ago`;
  return `${days.toFixed(days < 10 ? 1 : 0)}d ago`;
};
const dateShort = (ms) => new Date(ms).toLocaleDateString("en-US", { month: "short", day: "numeric" });

function spark(values, w = 90, h = 22) {
  if (!values || values.length < 2) return "";
  const min = Math.min(...values);
  const max = Math.max(...values);
  const span = max - min || 1;
  const pts = values.map((v, i) => `${((i / (values.length - 1)) * w).toFixed(1)},${(h - ((v - min) / span) * h).toFixed(1)}`).join(" ");
  const up = values[values.length - 1] >= values[0];
  return `<svg class="spark" width="${w}" height="${h}" viewBox="0 0 ${w} ${h}" aria-hidden="true"><polyline fill="none" stroke="${up ? "var(--long)" : "var(--short)"}" stroke-width="1.4" points="${pts}"/></svg>`;
}

async function api(path, init) {
  const res = await fetch(path, { credentials: "same-origin", ...init });
  if (res.status === 401) {
    location.reload();
    throw new Error("signed out");
  }
  const data = await res.json().catch(() => ({}));
  if (!res.ok) throw new Error(data?.error?.message ?? `HTTP ${res.status}`);
  return data;
}

function syncUrl() {
  const p = new URLSearchParams();
  p.set("tf", state.tf);
  if (state.exclude.trim()) p.set("excluded", state.exclude.trim());
  if (state.universe !== 30) p.set("universe", String(state.universe));
  p.set("pairImpact", "1");
  p.set("pairImpactBps", String(state.pairImpactBps));
  p.set("pairSize", String(state.pairSize));
  p.set("kraken", state.kraken ? "1" : "0");
  history.replaceState(null, "", `${location.pathname}?${p}`);
  store.set("tf", state.tf);
  store.set("exclude", state.exclude);
  store.set("universe", state.universe);
}

function setSources(list) {
  const el = $("#sources");
  const seen = new Map();
  for (const s of list) {
    const key = s.name.split(":").slice(0, 2).join(":");
    if (!seen.has(key) || !s.ok) seen.set(key, s);
  }
  el.innerHTML = [...seen.values()]
    .map((s) => `<i class="${s.ok ? "" : "bad"}" title="${esc(s.name)}${s.ok ? " ok" : ": " + esc(s.error ?? "failed")}"></i>`)
    .join("");
}

const loadingRow = (cols, text = "Loading…") => `<tr class="empty"><td colspan="${cols}">${text}</td></tr>`;

// ---------- board ----------

function boardQuery() {
  const p = new URLSearchParams({ tf: state.tf, universe: String(state.universe) });
  if (state.exclude.trim()) p.set("exclude", state.exclude.trim());
  const a = state.account;
  p.set("equity", a.equity);
  p.set("risk", a.risk);
  p.set("levMajors", a.levMajors);
  p.set("levAlts", a.levAlts);
  p.set("oiFrac", a.oiFrac / 100);
  p.set("stopAtr", a.stopAtr);
  for (const [k, v] of Object.entries(state.weights)) p.set(`w_${k}`, v);
  return p;
}

function breakoutCell(b) {
  if (!b?.direction) return `<span class="muted">—</span>`;
  const arrow = b.direction === "up" ? "▲" : "▼";
  const color = b.holding ? (b.direction === "up" ? "pos" : "neg") : "muted";
  const when = b.barsSince === 0 ? "this bar" : `${b.barsSince} bar${b.barsSince === 1 ? "" : "s"}`;
  return `<span class="bo"><span class="dir ${color}">${arrow}</span> ${when} · ${dateShort(b.since)} · <span class="${cls(b.moveSince)}">${signed(b.moveSince * 100)}%</span>${b.holding ? "" : ' <span class="warm">failed</span>'}</span>`;
}

function renderBoard(data) {
  state.ideas = data.ideas;
  $("#tfLabel").textContent = data.timeframe.label;
  const rows = data.ideas.map((it, i) => {
    const korea = it.koreaVsGlobal;
    const kClass = korea >= 10 ? "hot" : korea >= 3 ? "warm" : "";
    const fClass = it.fundingApr > 0.3 ? "neg" : it.fundingApr < -0.1 ? "pos" : "";
    const width = Math.min(60, Math.abs(it.score) * 0.6);
    return `<tr data-sym="${esc(it.symbol)}" class="${state.selected === it.symbol ? "sel" : ""}">
      <td class="muted mono">${i + 1}</td>
      <td class="coin">${esc(it.symbol)}</td>
      <td><span class="side ${it.side}">${it.side.toUpperCase()}</span></td>
      <td class="num"><span class="scorebar"><b style="width:${width}px;background:${it.score >= 0 ? "var(--accent)" : "var(--short)"}"></b>${it.score.toFixed(1)}</span></td>
      <td class="num">${fmtPx(it.price)}</td>
      <td>${breakoutCell(it.breakout)}</td>
      <td class="num ${fClass}">${pct(it.fundingApr, 1)}</td>
      <td class="num">${pct(it.oiToMcap, 1)}</td>
      <td class="num ${kClass}">${korea ? korea.toFixed(1) + "×" : "—"}</td>
      <td class="num" title="Bound by ${esc(it.sizing.boundBy)}">${fmtUsd(it.sizing.notionalUsd)} <span class="muted">${it.sizing.leverage.toFixed(1)}×</span></td>
      <td>${spark(it.spark)}</td>
    </tr>`;
  });
  $("#boardTable tbody").innerHTML = rows.join("") || loadingRow(11, "No setups — every source may be down. Check the dots up top.");
  if (state.selected) renderDetail(state.ideas.find((x) => x.symbol === state.selected));
}

function renderDetail(it) {
  const el = $("#detail");
  if (!it) {
    el.hidden = true;
    return;
  }
  const comps = it.components
    .map((c) => {
      const v = Math.max(-1, Math.min(1, c.value));
      const left = v >= 0 ? 50 : 50 + v * 50;
      const width = Math.abs(v) * 50;
      return `<div class="comp"><span class="k">${esc(c.key === "oiFlow" ? "OI flow" : c.key)}</span>
        <span class="track"><span class="fill" style="left:${left}%;width:${width}%;background:${v >= 0 ? "var(--long)" : "var(--short)"}"></span></span>
        <span class="v">${signed(v * c.weight, 2)}</span><span class="note">${esc(c.note)} · weight ${c.weight}</span></div>`;
    })
    .join("");
  const s = it.sizing;
  const b = it.breakout;
  el.innerHTML = `<div><h3>${esc(it.symbol)} <span class="side ${it.side}">${it.side.toUpperCase()}</span> <span class="muted mono">${it.score.toFixed(1)}</span></h3>${comps}</div>
    <div><h3>Plan</h3><dl class="kv">
      <dt>Entry (mark)</dt><dd>${fmtPx(it.price)}</dd>
      <dt>Stop</dt><dd>${fmtPx(s.stopPrice)} <span class="muted">(${pct(s.stopPct, 1)})</span></dd>
      <dt>Target 2R</dt><dd>${fmtPx(s.targetPrice)}</dd>
      <dt>Size</dt><dd>${fmtUsd(s.notionalUsd)} · ${s.leverage.toFixed(2)}×</dd>
      <dt>Bound by</dt><dd>${esc(s.boundBy)}</dd>
      <dt>Caps</dt><dd>risk ${fmtUsd(s.caps.risk)} · lev ${fmtUsd(s.caps.leverage)} · OI ${fmtUsd(s.caps.openInterest)}</dd>
      <dt>Breakout</dt><dd>${b?.direction ? `${b.direction} through ${fmtPx(b.level)} on ${dateShort(b.since)} (${ago(b.since)})` : "none"}</dd>
      <dt>Since trigger</dt><dd class="${cls(b?.moveSince)}">${b?.direction ? signed(b.moveSince * 100) + "%" : "—"}</dd>
      <dt>ATR</dt><dd>${pct(it.atrPct, 2)}</dd>
      <dt>Volume</dt><dd>${Number.isFinite(it.volumeExpansion) ? it.volumeExpansion.toFixed(2) + "× median" : "—"}</dd>
      <dt>Perp OI</dt><dd>${fmtUsd(it.perpOiUsd)} <span class="muted">(HL ${fmtUsd(it.hlOiUsd)})</span></dd>
      <dt>OI change</dt><dd class="${cls(it.oiChange)}">${it.oiChange === null ? "building history" : pct(it.oiChange, 1)}</dd>
      <dt>Market cap</dt><dd>${fmtUsd(it.marketCap)}</dd>
      <dt>Venue max lev</dt><dd>${it.maxLeverage ?? "—"}×</dd>
    </dl></div>`;
  el.hidden = false;
}

async function loadBoard() {
  $("#boardTable tbody").innerHTML = loadingRow(11);
  try {
    const data = await api(`/api/market/board?${boardQuery()}`);
    renderBoard(data);
    setSources(data.sources);
    $("#updated").textContent = `updated ${new Date(data.generatedAt).toLocaleTimeString()}`;
  } catch (err) {
    $("#boardTable tbody").innerHTML = loadingRow(11, `Board failed: ${esc(err.message)}`);
  }
}

// ---------- korea ----------

async function loadKorea() {
  $("#koreaTable tbody").innerHTML = loadingRow(7);
  try {
    const data = await api("/api/market/korea");
    $("#koreaNote").textContent = `Upbit + Bithumb vs global · ${data.screened} coins screened · ₩${Math.round(data.usdKrw).toLocaleString()}/$`;
    $("#koreaTable tbody").innerHTML =
      data.rows
        .slice(0, 30)
        .map((r, i) => {
          const x = r.koreaVsGlobal;
          return `<tr><td class="muted mono">${i + 1}</td><td class="coin">${esc(r.symbol)}</td>
            <td class="num" style="color:var(--accent-2)">${r.interest.toFixed(1)}</td>
            <td class="num">${pct(r.koreaShare)}</td><td class="num muted">${pct(r.globalShare)}</td>
            <td class="num ${x >= 10 ? "hot" : ""}">${x ? x.toFixed(1) + "×" : "—"}</td>
            <td class="num">${fmtKrw(r.krwTurnover)}</td></tr>`;
        })
        .join("") || loadingRow(7, "No Korean data.");
  } catch (err) {
    $("#koreaTable tbody").innerHTML = loadingRow(7, `Korea failed: ${esc(err.message)}`);
  }
}

// ---------- leverage ----------

async function loadLeverage() {
  $("#levTable tbody").innerHTML = loadingRow(8);
  try {
    const data = await api("/api/market/leverage");
    $("#levNote").textContent = `Perp OI ${fmtUsd(data.totals.perpOiUsd)} across venues · 24h perp volume ${fmtUsd(data.totals.perpVolumeUsd)}`;
    $("#levTable tbody").innerHTML = data.rows
      .slice(0, 60)
      .map(
        (r) => `<tr><td class="coin">${esc(r.symbol)}</td><td class="num">${fmtUsd(r.perpOiUsd)}</td>
        <td class="num ${r.oiToMcap > 0.2 ? "hot" : r.oiToMcap > 0.1 ? "warm" : ""}">${pct(r.oiToMcap, 1)}</td>
        <td class="num ${cls(-r.avgFundingPct)}">${r.avgFundingPct === null ? "—" : r.avgFundingPct.toFixed(4) + "%"}</td>
        <td class="num ${cls(-r.hlFundingApr)}">${pct(r.hlFundingApr, 1)}</td>
        <td class="num">${r.turnover ? r.turnover.toFixed(2) : "—"}</td><td class="num">${r.venues}</td><td class="num">${r.hlMaxLeverage ?? "—"}</td></tr>`,
      )
      .join("");
  } catch (err) {
    $("#levTable tbody").innerHTML = loadingRow(8, `Leverage failed: ${esc(err.message)}`);
  }
}

// ---------- pair impact ----------

async function loadImpact() {
  $("#impTable tbody").innerHTML = loadingRow(7);
  $("#pairTable tbody").innerHTML = "";
  const p = new URLSearchParams({
    pairImpact: "1",
    pairImpactBps: String(state.pairImpactBps),
    pairSize: String(state.pairSize),
    kraken: state.kraken ? "1" : "0",
  });
  if (state.exclude.trim()) p.set("excluded", state.exclude.trim());
  try {
    const data = await api(`/api/market/impact?${p}`);
    $("#impTable tbody").innerHTML = data.coins
      .map((c) => {
        const bps = (v) => (v === null ? "∞" : v.toFixed(1));
        return `<tr><td class="coin">${esc(c.symbol)}</td><td class="num">${bps(c.buyImpactBps)}</td><td class="num">${bps(c.sellImpactBps)}</td>
          <td class="num">${bps(c.roundTripBps)}</td><td class="num muted">${bps(c.roundTripWithFeesBps)}</td>
          <td class="num">${c.kraken ? c.kraken.spreadBps.toFixed(1) : "—"}</td>
          <td>${c.passes ? '<span class="pos mono">✓</span>' : '<span class="muted mono">·</span>'}</td></tr>`;
      })
      .join("");
    $("#pairTable tbody").innerHTML =
      data.pairs
        .slice(0, 25)
        .map((x) => `<tr><td class="coin pos">${esc(x.long)}</td><td class="coin neg">${esc(x.short)}</td><td class="num">${x.impactBps.toFixed(1)} bps</td></tr>`)
        .join("") || loadingRow(3, `No pair fits ${state.pairImpactBps} bps at ${fmtUsd(state.pairSize)} a leg.`);
  } catch (err) {
    $("#impTable tbody").innerHTML = loadingRow(7, `Impact failed: ${esc(err.message)}`);
  }
}

// ---------- journal ----------

async function loadFills() {
  if (!state.isOwner) return;
  try {
    const data = await api("/api/fills");
    $("#fillTable tbody").innerHTML =
      data.fills
        .map(
          (f) => `<tr><td class="mono muted">${new Date(f.filledAt).toLocaleString("en-US", { month: "short", day: "numeric", hour: "2-digit", minute: "2-digit" })}</td>
          <td class="coin">${esc(f.coin)}</td><td><span class="side ${f.side === "buy" ? "long" : "short"}">${f.side === "buy" ? "LONG" : "SHORT"}</span></td>
          <td class="num">${fmtPx(f.price)}</td><td class="num">${f.size}</td><td class="num">${f.leverage ? f.leverage + "×" : "—"}</td>
          <td class="num">${fmtPx(f.mark)}</td><td class="num ${cls(f.moveSincePct)}">${signed(f.moveSincePct, 2)}% <span class="muted">${ago(Date.parse(f.filledAt))}</span></td>
          <td class="num ${cls(f.pnlUsd)}">${fmtUsd(f.pnlUsd)}</td><td><button class="linkbtn" data-del="${esc(f.id)}" title="Delete">✕</button></td></tr>`,
        )
        .join("") || loadingRow(10, "No fills yet. Paste a CSV from your exchange or funded account.");
  } catch (err) {
    $("#fillTable tbody").innerHTML = loadingRow(10, `Journal failed: ${esc(err.message)}`);
  }
}

// ---------- sharing ----------

async function loadShares() {
  const data = await api("/api/shares");
  $("#shareList").innerHTML = data.shares
    .map(
      (s) => `<li><span>${esc(s.label)} · ${esc(s.role)}${s.revokedAt ? ' · <span class="muted">off</span>' : ""}${s.lastUsedAt ? ` · used ${ago(Date.parse(s.lastUsedAt))}` : ""}</span>
      ${s.revokedAt ? "" : `<button class="linkbtn" data-revoke="${esc(s.id)}">Turn off</button>`}</li>`,
    )
    .join("");
}

// ---------- settings ----------

function fillSettings() {
  for (const input of $$("[data-acct]")) input.value = state.account[input.dataset.acct];
  $("#weights").innerHTML = Object.entries(state.weights)
    .map(([k, v]) => `<label class="field"><span>${k === "oiFlow" ? "OI flow" : k}</span><input data-w="${k}" type="number" min="0" max="10" step="0.25" value="${v}"></label>`)
    .join("");
}

function readSettings() {
  for (const input of $$("[data-acct]")) state.account[input.dataset.acct] = Number(input.value);
  for (const input of $$("[data-w]")) state.weights[input.dataset.w] = Number(input.value);
  store.set("account", state.account);
  store.set("weights", state.weights);
}

// ---------- wiring ----------

function selectTf(tf) {
  state.tf = tf;
  for (const b of $$(".tf button")) b.setAttribute("aria-selected", String(b.dataset.tf === tf));
  syncUrl();
  loadBoard();
}

function refreshAll() {
  syncUrl();
  loadBoard();
  loadKorea();
  loadLeverage();
  loadImpact();
  loadFills();
}

async function init() {
  $("#exclude").value = state.exclude;
  $("#universe").value = state.universe;
  $("#pairSize").value = state.pairSize;
  $("#pairImpactBps").value = state.pairImpactBps;
  $("#kraken").checked = state.kraken;
  for (const b of $$(".tf button")) b.setAttribute("aria-selected", String(b.dataset.tf === state.tf));
  fillSettings();

  const session = await api("/api/session").catch(() => ({ role: "view" }));
  state.isOwner = session.role === "owner";
  for (const el of $$(".owner-only")) el.hidden = !state.isOwner;

  $$(".tf button").forEach((b) => b.addEventListener("click", () => selectTf(b.dataset.tf)));
  $("#refresh").addEventListener("click", refreshAll);
  $("#exclude").addEventListener("change", (e) => {
    state.exclude = e.target.value;
    refreshAll();
  });
  $("#universe").addEventListener("change", (e) => {
    state.universe = Math.max(5, Math.min(36, Number(e.target.value) || 30));
    e.target.value = state.universe;
    syncUrl();
    loadBoard();
  });
  $("#impactGo").addEventListener("click", () => {
    state.pairSize = Number($("#pairSize").value) || 25000;
    state.pairImpactBps = Number($("#pairImpactBps").value) || 20;
    state.kraken = $("#kraken").checked;
    syncUrl();
    loadImpact();
  });
  $("#boardTable tbody").addEventListener("click", (e) => {
    const tr = e.target.closest("tr[data-sym]");
    if (!tr) return;
    state.selected = state.selected === tr.dataset.sym ? null : tr.dataset.sym;
    $$("#boardTable tbody tr").forEach((r) => r.classList.toggle("sel", r.dataset.sym === state.selected));
    renderDetail(state.ideas.find((x) => x.symbol === state.selected));
  });
  $("#settingsBtn").addEventListener("click", () => {
    const d = $("#settings");
    d.hidden = !d.hidden;
    $("#settingsBtn").setAttribute("aria-expanded", String(!d.hidden));
  });
  $("#applyRules").addEventListener("click", () => {
    readSettings();
    $("#settings").hidden = true;
    loadBoard();
  });
  $("#resetRules").addEventListener("click", () => {
    state.account = { ...DEFAULT_ACCOUNT };
    state.weights = { ...DEFAULT_WEIGHTS };
    fillSettings();
  });
  $("#csvBtn").addEventListener("click", () => ($("#csvForm").hidden = !$("#csvForm").hidden));
  $("#csvForm").addEventListener("submit", async (e) => {
    e.preventDefault();
    $("#csvMsg").textContent = "Importing…";
    try {
      const r = await api("/api/fills", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify({ csv: $("#csvText").value }) });
      $("#csvMsg").textContent = `Imported ${r.added} fill${r.added === 1 ? "" : "s"}.`;
      $("#csvText").value = "";
      loadFills();
    } catch (err) {
      $("#csvMsg").textContent = err.message;
    }
  });
  $("#fillTable tbody").addEventListener("click", async (e) => {
    const id = e.target.closest("[data-del]")?.dataset.del;
    if (!id || !confirm("Delete this fill?")) return;
    await api(`/api/fills/${encodeURIComponent(id)}`, { method: "DELETE" });
    loadFills();
  });
  $("#shareBtn").addEventListener("click", async () => {
    $("#shareOut").hidden = true;
    $("#shareDialog").showModal();
    loadShares();
  });
  $("#shareMake").addEventListener("click", async (e) => {
    e.preventDefault();
    const days = Number($("#shareDays").value);
    const body = { label: $("#shareLabel").value || "Desk", scope: "/", role: "view", ...(days > 0 ? { expiresInDays: days } : {}) };
    const r = await api("/api/shares", { method: "POST", headers: { "content-type": "application/json" }, body: JSON.stringify(body) });
    $("#shareOut").value = r.url;
    $("#shareOut").hidden = false;
    $("#shareOut").select();
    navigator.clipboard?.writeText(r.url).catch(() => {});
    loadShares();
  });
  $("#shareList").addEventListener("click", async (e) => {
    const id = e.target.closest("[data-revoke]")?.dataset.revoke;
    if (!id) return;
    await api(`/api/shares/${encodeURIComponent(id)}`, { method: "DELETE" });
    loadShares();
  });
  document.addEventListener("keydown", (e) => {
    if (e.target.matches("input, textarea")) return;
    if (e.key === "r") refreshAll();
    if (e.key === "1") selectTf("1d");
    if (e.key === "3") selectTf("3d");
    if (e.key === "w") selectTf("1w");
  });

  refreshAll();
  setInterval(() => {
    if (document.visibilityState === "visible") refreshAll();
  }, 120000);
}

init();
