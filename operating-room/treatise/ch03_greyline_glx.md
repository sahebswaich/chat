# III. Greyline → GLX — building the equity-perp exchange (Nov 2025 → Jun 2026)

Between 23 November 2025 and early June 2026, one product — a perpetual future on a single US stock — passed through six business models. The contract settled by March 2026. What kept changing was the part Saheb would own: a retail app, a full licensed stack, equity in a MIAX joint venture, a revenue share as introducing broker, the whole MIAX futures complex, and finally a royalty on the fee pool. This chapter walks the models in order, then covers what they shared.

A perpetual future ("perp") never expires. It is held to the stock by the **funding rate** — the hourly payment between longs and shorts that ties the perp to the stock.

## The arc in one table {#glx-arc}

Each model kept the product and moved the economics. The pattern: Saheb designed a layer, found MIAX already held it or that owning it added little to the fee pool, and moved one layer up.

| Dates | Model | What Saheb would own | Why it gave way (per the documents) |
|---|---|---|---|
| 23–25 Nov 2025 | Thematic basket perps on MIAX → CFTC pilot → own exchange | A retail app, later an own DCM (exchange) | A "horse in the race" to raise $20–40M; the real target was single stocks |
| 26 Nov–2 Dec 2025 | Own DCM + DCO (clearinghouse) + FCM (futures broker), $100M seed | All three licences — "four companies" | Licences cost "$100M+ and 3-5 years"; MIAX already held all three |
| 5 Dec 2025–9 Jan 2026 | MIAX joint venture (NewCo) under an MOU | ≥40% or ≥80% of NewCo | Replaced on 27 Jan by an alliance; no reason recorded |
| 27 Jan–Apr 2026 | Exclusive alliance; Greyline Markets as Guaranteed Introducing Broker (GIB) | 80/20, then 90/10 of own-flow fees + 20% royalty on other flow | "The ambition kept growing"; MIAX would not sign the HoT as drafted |
| May 2026 | Buy the stack: $1B at $11B post | MIAX Futures, Dorman, Connamara | Needed MIAX to spin out its futures arm; later marked "stale" |
| May–Jun 2026 | Pure licensor: 36% of the gross fee pool, in perpetuity | A royalty in GLX LLC | Became American Perpetual (60% royalty, OCC clearing) by Sept 2026 |

> [!number] ~$1Q — V1 cleared notional at maturity ($463T customer demand × 2.2 market-maker multiplier)

> [!number] ~$340B/yr — venue fee pool at a 3.4 bps blended fee
> GLX's 36% ≈ $122B/yr topline; ≈ $68B/yr on the conservative $554T floor.

> [!number] 36% — GLX origination royalty on the gross fee pool (May 2026)
> Up from 20% in the Mar–Apr drafts; 60% in American Perpetual.

> [!number] 500 ms — sealed BLP liquidation auction window, floor 5% from mark

> [!number] 23×5 — trading hours, 23 hourly funding rates a day

> [!number] $1B at $11B post — the May 2026 buy-the-stack Series A ask

> [!number] 50 days — Path to Close: nine MIAX instruments, a $12M SAFE, Founding BLPs, a Silver Lake term sheet

*Sources: Executive Summary (2025-11-23); Greyline_OnePager (2025-12-11); MIAX_Heads_of_Terms (2026-01-27); 10_GLX_Path_to_Close (Apr 2026); MIAX.pdf (May 2026); GLX_Investor_Document (~May 2026); GLX_Complete_Operational_Document (May 2026); Advanced_TAM_Methodology (May 2026)*

## Basket perps and the $100B pathway (Nov 2025) {#glx-pathway}

The idea began as a wedge product Saheb did not expect to sell. Its job was to raise $20–40M and open a door at MIAX.

The first plan (23 Nov) had four steps: index perps on MIAX; a CFTC no-action pilot for single stocks; an own DCM built during the pilot; joint SEC/CFTC rulemaking. The legal trick: a single stock or an index of fewer than 10 names is a security-based swap, but a broad index of 10+ names with ≤30% in each is CFTC-only. So the app would trade thematic baskets — "AI", "Datacenters", "SMRs", "Oil & Gas", "Drones" — as "Trade Ideas on leverage", up to 20x, adjusted daily because "technology doesn't support hourly funding rates". Design: "Liquid Glass design under 2025 ios design standards + an orange theme". Todo: Persona for KYC, RQD or Apex for clearing, "MM: Find one to invest, Jump."

> [!quote] "Obviously, I don't actually expect these products to be very popular, it's mainly just to have a horse in the race" — Executive Summary, 2025-11-23

"The pathway to a 100b exchange" (25 Nov) added a second bridge, the **Continuous Single Stock Future**: a security future with a 10-year expiry and a daily cash adjustment as funding, capped at 15% margin (6.6x). "This is how coinbase did their 5 year BTC/ETH derivative." MIAX's rulebook already had security futures: "the shell exists".

On 26 Nov Saheb wrote to **Bridget Harris at Founders Fund**. His thesis was the "anatomy of a trade". A crypto exchange is a DCM, DCO and FCM in one. The US splits them and settles in daily batches, so a US perp venue needs all three. "We're basically building four companies at the same time." He asked for $30M and set aside on-chain perps: "The real money would be in the legal US single stock perpetuals on a DCM we control."

> [!quote] "The difference between a 1b brokerage app, and a 100b+ financial empire." — Founder's Fund letter, 2025-11-26

The first **Greyline** documents (27 Nov – 2 Dec) asked for a $100M Series Seed to license an own DCO, FCM and DCM. The take rate went from 10 bps to a 4–6 bps all-in stack: DCM 1.5–2.5, DCO 0.3–0.5, FCM 0.5–1.0, IB 0.5–1.5 and funding spread 0.5–1.0. The downside was a licence-resale floor of $150–200M, citing Kraken–Small Exchange ($100M) and Polymarket–QCEX ($112M) — "a risk free option on the future of markets". The TAM took US spot at ~$20T/yr and 5 bps: 10% capture → $1B revenue; 68% → $6.8B.

**Why it gave way.** The licences were the slow, costly part — "$100M+ and 3-5 years to obtain independently" — and MIAX held all three. On 5 December the plan flipped from build to partner.

> [!tension] Same-day valuations disagree: $100M pre-money (Greyline_Pitch_Deck_Full) vs $300M pre / $400M post (Greyline.docx, modified a day later).

*Sources: Executive Summary, Todo list, Swaich, The pathway to a 100b exchange (2025-11-23 to 25); Founder's Fund (2025-11-26); Untitled "GREYLINE" (2025-11-27); Greyline.docx and Greyline_Pitch_Deck_Full (2025-12-01/02); Greyline_OnePager (2025-12-11)*

## The MIAX joint venture (Dec 2025) {#glx-jv}

In December Saheb stopped trying to own the licences and asked MIAX to contribute them. Greyline would bring product, regulatory strategy, engineering and customers.

The proposal went through three versions in five days:

- **v1 (5 Dec)** — the first contract spec: AAPL, MSFT, NVDA, TSLA, AMZN, GOOGL, META; 1 share; 24/7/365; 5% initial (20x) / 2.5% maintenance margin; funding every 4 hours, capped at ±0.50%; an insurance fund, then auto-deleveraging (ADL — force-closing winning positions to cover a loss).
- **v2 (6 Dec)** — "three exemptions that matter": CFTC 39.14 settlement, 39.13(g)(2) margin period (1 day → 4 hours), and SEC security-futures margin. "Exemption #3 is the entire SEC conversation." A 2.5 bps fee split DCM 35% / DCO 35% / FCM 30%. 30% of ~$500B/day of US equity volume → $13B+/yr.
- **v3 (10 Dec)** — maker/taker 1/5 bps all-in; 50 bps liquidation fee; a worked NVDA liquidation; a Designated Market Maker rebate of +0.5 bps; $12B+ revenue at scale.

The **MOU** (11 Dec, 22 Dec, file state 9 Jan) set up a NewCo. MIAX would contribute its DCM, DCO and FCM licences and the Onyx matching engine, under 12 months' binding exclusivity. It would name an SVP-level liaison and co-invest in the seed once Greyline had raised half. The 22 Dec draft added a work-product clause: if MIAX launched equity perps within 24 months without the JV, it would compensate Greyline.

> [!quote] "Ownership in the railroad, not a ticket to ride it." — Greyline_OnePager, 2025-12-11

The 20 Dec data room added three documents. A Partnership Overview promised "Zero development risk" for MIAX and a 2027 launch. A regulatory memo used the Bitnomial precedent: "MIAX files, Greyline builds". A technical appendix classified the product as a **Security Futures Product (SFP)** — the joint SEC/CFTC category created in 2000. "We will file as a true perpetual—no artificial expiration. If regulators require the nominal term, we add it." The same day a spreadsheet, **GLX_Revenue_Model**, used "GLX" for the first time. On 29 Dec the Technical Architecture brought in **Dorman Trading** as FCM.

**Why it gave way.** The documents do not say. On 27 January the Heads of Terms replaced NewCo equity with an exclusive alliance and a fee split.

> [!tension] JV equity floor: Greyline "no less than forty percent" (22 Dec draft) vs "no less than 80%" (unsigned file modified 9 Jan); which went to MIAX is unknown.

> [!tension] The OnePager lists an "MOU with MIAX" under "What we've secured"; every MOU copy in Drive is unsigned.

> [!tension] Funding interval: every 4 hours (5–10 Dec proposals) vs "hourly settlement" (20 Dec Partnership Overview).

> [!tension] Funding cap: ±0.50% per interval (5–10 Dec) vs ±0.10% (29 Dec architecture) vs no cap (Mar 2026 onward).

> [!tension] Funding interest term: SOFR − borrow (v1) vs SOFR + borrow spread (v2, final Equity Perp Proposal) vs none (v3, and rejected in the Mar spec).

> [!tension] The SFP margin floor is stated as 15% (most docs), "statutory 20%" (Feb deck), 15–20% (Nov memos) and "100% margin" under Reg T (Dec proposals).

> [!tension] The Tech Appendix's method gives TSLA 12–15% initial margin (7–8x), yet its proposed parameters give TSLA 5% (20x).

> [!tension] The Technical Architecture is headed "January 2025" but was created 29 Dec 2025 — almost certainly a typo for 2026.

*Sources: Greyline_MIAX_Equity_Perps v1/v2/v3 (2025-12-05/06/10); Equity Perp Proposal (2025-12-06); Greyline_MIAX_MOU unsigned (2025-12-11, mod 2026-01-09); MOU_Revised_Draft (2025-12-22); MIAX_Partnership_Overview, Regulatory_Pathway_Memo, Regulatory_Pathway_Technical_Appendix, GLX_Revenue_Model.xlsx (2025-12-20); greyline_technical_architecture (2025-12-29)*

## Strategic Alliance, Greyline Markets and the GLX name (Jan–Feb 2026) {#glx-alliance}

January turned the joint venture into an exclusive, open-ended revenue-share alliance. Greyline became the introducing broker: the customer-facing layer that sends orders to MIAX and clears through Dorman.

- **11 Jan** — engineer brief: "We're the IB—the product layer." The diagram reads MIAX ↕ FIX/FEI ↕ "GLX Platform" ↕ Dorman. Funding is hourly.
- **17 Jan** — Entity Requirements, a ~370-task checklist: $50M at $400M pre, 6 months to launch, $20B/day target. Sign Citadel Securities as "Primary liquidity provider", then Jump; "Sign 2 BLPs".
- **21 Jan** — Strategic LOI for market makers: "Founding Liquidity Partner" status, MFN fee tiers, and a non-binding seed indication of $2.5–5M, $5–10M or $10M+.
- **27 Jan** — **Heads of Terms** and long-form **Strategic Alliance Agreement** between **Greyline Markets, Inc.** and Miami International Holdings, including MIAX Futures Exchange (DCM + DCO) and Dorman Trading (FCM).

The alliance terms (both drafts unsigned):

- "Perpetual Futures" means funding-rate contracts "across all asset classes including equities, equity indices, digital assets, commodities, rates, and foreign exchange."
- Mutual exclusivity; indefinite term; exit only by consent or an uncured breach after 90 days.
- Maker/taker fees 80% Greyline / 20% MIAX; liquidation fees 100% Greyline; no DCO or FCM fees; funding earns nobody anything.
- Greyline funds the insurance fund at Dorman and pays for the CFTC exemption. Either side may walk if there is no relief in 24 months.
- Greyline owns the IP and MIAX gets an exclusive licence. The deal survives a MIAX change of control.

The **February investor deck** (saheb@greyline.markets) showed the result. Trading 24/5 (Sunday 6 PM – Friday 5 PM ET); hourly funding; **VeriClear** as DCO; the Backstop Liquidity Provider (BLP) as "Our Innovation"; **Connamara Systems** as technology partner; live trading in Q3 2026. Fees 2/5 bps, 2.8 bps net to Greyline; $10B/day → ~$1B revenue. "Only firms committing liquidity get access to invest in the round." End state: "THE UNIFIED DELTA-ONE VENUE — Perps → spot → options. Full broker-dealer."

**The name.** "GLX" moved from a spreadsheet (20 Dec) to the platform (11 Jan) to the brand: by March–April documents carry glx.com, and Path to Close budgets to buy the domain and the @GLX handle. No document says what GLX stands for.

> [!tension] The Feb deck says "MIAX signed" and "Exclusive alliance signed"; the HoT and SAA in Drive are unsigned, MIAX's signature block blank.

> [!tension] DCO identity: "MIAX DCO / MIAX Clearing" (Dec) vs "VeriClear" (Feb onward).

> [!tension] Trading hours: 24/7/365 (Nov–Dec 2025) → 24/5 (Feb–Mar 2026) → "23/5" (Apr 2026 onward).

> [!tension] Valuation drift: $400M pre (Jan) → "valuation set by lead" (Feb) → no-cap SAFEs (Mar–Apr) → $10B pre (May).

*Sources: greyline-engineer-brief (2026-01-11); Greyline Entity Requirements (2026-01-17); Strategic LOI Template (2026-01-21); MIAX_Heads_of_Terms and MIAX_Strategic_Alliance_Agreement (2026-01-27); Old Investor Deck ("February 2026"); MIAX.pdf (May 2026)*

## The introducing-broker build (Mar–Apr 2026) {#glx-gib}

By March, Greyline was a Guaranteed Introducing Broker under CFTC Rule 1.57 in a four-entity stack. It ran "the brain" and was paid 90% of the fees on its own customers' trades plus a 20% royalty on everyone else's.

| Entity | Registration | Role |
|---|---|---|
| MIAX Futures (Onyx) | DCM | Matching, mark-price and funding engines, fee collection, surveillance |
| VeriClear | DCO | Novation, clearing-member margin, daily Fedwire, default waterfall |
| Dorman Trading | FCM | Segregated customer funds, deposits, statements, tax forms |
| Greyline Markets | Guaranteed IB | UI, shadow ledger, margin engine, liquidation controller, funding calculator, API |

Greyline never touches customer money. Orders go to Onyx by FIX; fills come back on a drop copy. By 3:10 PM ET Greyline sends Dorman a file of funding, fees and liquidation charges, and VeriClear settles each clearing member's net by Fedwire at ~3:30 PM. Three books must agree: Greyline's sub-account funding, Dorman's customer funding and VeriClear's charge. Dorman executes Greyline-triggered liquidations without re-checking them.

The economics were "dual-lane":

- **Lane 1:** 90% Greyline / 10% MIAX on Greyline-originated volume.
- **Lane 2:** a 20% "Product Origination Share" off the top of every other trade. A $1M Robinhood taker trade at 5 bps ($500) pays Greyline $100, Robinhood $200 and MIAX $200. A Citadel market-maker trade at 2 bps ($200) pays $40 and $160.
- Liquidation fees go 100% to Greyline. Dorman keeps 50% of deposit interest; MIAX keeps market-data revenue.

The March Executive Summary asked MIAX for "$12M SAFE + signed Strategic Alliance Agreement" and put MIAX's 10% at ~$130M in Year 1. The Partnership Deck sold the BLP to market makers as "Robinhood PFOF economics applied to liquidations" and the auction as low-risk: "MIAX has built PRIME four times. This is the fifth port." It quoted MIAX CEO Tom Gallagher: "We built the church for Easter Sunday." In April the BLP Memo turned this into a coalition: sign Founding BLP MOUs before a mid-2026 "Round 1" meeting with regulators. "The Founding cohort exists once."

**Why it gave way.** Saheb later called this "Plan A" — IB, teach MIAX's stack, royalty, own frontend — and "then the ambition kept growing". Path to Close also warned the HoT "will not become the instrument MIAX signs": MIAX papers such deals through MIAX Products, LLC, as with its 2024 Bloomberg index licence.

> [!tension] Revenue split: 80/20 (Jan HoT/SAA, Feb deck) vs 90/10 + 20% royalty (Mar spec, later HoT/SAA); Path to Close's table shows 20/40 and 40/60 while calling the numbers "stable".

> [!tension] Deposit interest: "Dorman retains 100%" (Deck slide 9) vs 50% (slide 10, Executive Summary, SAA).

> [!tension] MIAX projections: Year 2 $25B/day → ~$320M and scale $50B → ~$640M (Exec Summary) vs Year 2 $50B → ~$640M and scale $100B → ~$1.2B (Deck).

*Sources: 05_GLX_Complete_Technical_Specifications (V1, Mar 2026); 08_GLX_Architecture_Reference (v2.5, Apr 2026); 01_Executive_Summary and 02_MIAX_Partnership_Deck (Mar 2026); 03_MIAX_Heads_of_Terms; 04_MIAX_Strategic_Alliance_Agreement; 01_Greyline BLP Memo (Apr 2026); 10_GLX_Path_to_Close (Apr 2026); GLX_Investor_Document (~May 2026)*

## The contract, hours, mark and index {#glx-contract}

Every later model shares one contract: a cash-settled, never-expiring future on one US share, traded 23 hours a day, five days a week. "No greeks. No expiry. No roll."

- **Size:** 1 contract = 1 share (~$200 notional); $0.01 tick; USD collateral at the FCM.
- **Universe:** 7 megacaps (Dec 2025) → top 30 incl. SPY and QQQ (Feb) → top 100+ (Mar–Apr), scaling to 2,000+. A 24 Mar 2026 notebook ranked US tickers by daily notional and flagged SFP eligibility at an average close ≥ $5.
- **Hours:** Sunday 6 PM – Friday 5 PM ET, maintenance 5:05–5:40 PM; overnight priced off ATS venues (Blue Ocean, MOON, Bruce).
- **Mark price** (used for margin and liquidation) = median(Last Trade, Best Bid, Best Offer), the FTX method, computed inside Onyx. Halted or at Sunday open: Mark = Index + Last Premium.
- **Index** = ICE Consolidated Feed NBBO midpoint.
- **Controls:** collar ±10%; premium band ±5%; circuit breaker ±10% → 2-minute halt.
- **Corporate actions:** no dividend adjustment (to avoid §871(m)); splits automated off DTCC; spin-offs, M&A and special dividends above 10% go reduce-only and cash-settle.
- **Position limit:** 2.5M shares per account (the §41.25 default of 25,000 × 100-share contracts); market makers exempt.

> [!tension] Stock splits are handled "at IB level" (Tech Spec §26) vs at DCM/DCO level (§9/§11); the Playbook says standardise on §9/§11.

*Sources: 05_GLX_Complete_Technical_Specifications (Mar 2026); 01_Executive_Summary (Mar 2026); Old Investor Deck (Feb 2026); Untitled0.ipynb notional rank (2026-03-24)*

## Funding {#glx-funding}

By March 2026 funding was a pure pass-through of the perp's premium over the stock, averaged over an hour and paid hourly. It never changed again.

The formula, verbatim:

`Funding Rate = TWAP( (Mark − Index) / Index ) / 24`

- The premium is sampled every second (3,600 samples) and locked at each :00: drain give-ups, snapshot positions, lock. No recompute, no bust.
- Payment = Position Notional × Funding Rate, long to short or back. The venue earns nothing.
- No cap, no damper, no interest term (interest without a dividend term would bias shorts). Paying 23 times a day at /24 realises 95.8% of the premium daily.
- Example: AAPL index $200, perp averaging $200.40 → 0.20% premium → 0.00833% an hour; a 10,000-share long ($2M) pays $166.67.
- Settlement: novated by the DCO, with variation-margin character, itemised as a "Funding Adjustment" line in the one daily Fedwire.
- Precedents: Coinbase Derivatives / Nodal Clear Filing #2025-33 (the /24) and FTX. Contrasts: Bitnomial (8-hour, ±0.05% clamp + 0.01% interest), Cboe PBT (±0.002 clamp), Coinbase (EMA α = 0.75).

> [!quote] "Funding is not a fee and not a settlement — it is the economic substitute for expiry." — GLX_Funding_Mechanism, ≥ Jun 2026

That sentence carries the legal case: if funding substitutes for expiry, the contract is still one "for future delivery" and fits the SFP framework.

| Date | Interval | Formula | Cap | Interest |
|---|---|---|---|---|
| 5 Dec 2025 | 4 h | Premium + (SOFR − stock borrow) | ±0.50% | Yes |
| 6 Dec 2025 | 4 h | Premium + (SOFR + borrow spread) | ±0.50% | Yes |
| 10 Dec 2025 | 4 h | Mark below index → shorts pay longs | ±0.50% | No |
| 29 Dec 2025 | 4 h | clamp((Perp TWAP − Index TWAP) / Index TWAP, −0.1%, +0.1%) | ±0.1% | No |
| Mar 2026 → | 1 h, 23/day | TWAP((Mark − Index) / Index) / 24 | None | No |
| ≥ Jun 2026 | 1 h, per ICE-covered hour | Same | None | No |

Because dividends flow through funding, two side effects follow: a §871(m) withholding problem for non-US holders, and — the Investor Document notes — a predictable ex-dividend funding trade.

> [!tension] Funding count: fixed 23 per day (Reg Pathway, whitepaper) vs "rate count = ICE-covered hours" including overnight (Funding Mechanism).

> [!tension] The Op Doc calls Bitnomial's funding-as-variation-margin "on-point" (§31) but requires the "Coinbase Rule 1131 archetype, not the Bitnomial" (App. G.4).

*Sources: greyline_technical_architecture (2025-12-29); Greyline_MIAX_Equity_Perps v1–v3 (Dec 2025); 05_GLX_Complete_Technical_Specifications §4 (Mar 2026); 06_GLX_Regulatory_Pathway (Apr 2026); GLX_Funding_Mechanism (≥ Jun 2026); GLX_Complete_Operational_Document (May 2026); GLX_Investor_Document*

## Margin: the square-root curve {#glx-margin}

Margin scales with the square root of position size. Small positions get up to 25x; very large ones carry more margin than the 15% statutory floor the petition asks to remove.

The basis is FTX's practice and market-impact research: Kyle (1985), Almgren–Chriss (2000), Bouchaud/CFM, and a 2026 study of 942 Tokyo stocks showing impact grows with √size. Initial margin fraction (IMF) is what you post to open; maintenance fraction (MMF) is where liquidation starts.

| Version | IMF | MMF | k (mega/large/mid/small) | Leverage cap |
|---|---|---|---|---|
| Dec 2025 proposals | 5% flat | 2.5% flat | — | 20x |
| Dec 2025 Tech Appendix | 99th-pct daily move + buffer | 50–60% of IM | — | ~20–25x SPX, 7–8x TSLA |
| Mar 2026 spec (older) | max(Base_IMF, k × √shares) | max(2%, 0.6 × k × √shares) | 0.0001/0.0002/0.0003/0.0006 | 25/25/20/10x |
| Apr 2026 Reg Pathway | max(IMF_floor, k × √Q) | max(MMF_floor, 0.5 × k × √Q) | 0.0001/0.0002/0.0003/0.0006 | 25/25/20/10x |
| May 2026 spec, whitepaper | max(Base_IMF, k × √shares) | max(2%, 0.5 × k × √shares) | 0.0001/0.0003/0.0005/0.0006 | 25/25/20/10x |
| Clearing briefing, Op Doc | max(1/selected_leverage, k × √Q) | max(0.5%, 0.5 × k × √Q) | 0.0001/0.0002/0.0003/0.0006 | None at venue; FCM leverage dial |

NVDA at $135 and k = 0.0001, the same in every version:

- Below ~160,000 shares ($21.6M) the 4% floor binds: 25x.
- At 2.5M shares ($337.5M, the limit): 15.81% IMF, 7.91% MMF, 6.3x.
- At 20M shares: 44.72% IMF, $1.21B of margin, 2.2x — against ~$405M under a flat 15%.

"√Q runs MORE conservative than flat 15% across the institutional range; the floor binds only at small retail size."

In April the slope was tied to each broker's insurance fund (**Exhibit N**): a bigger fund at the clearing FCM earns a gentler curve.

| Tier | Insurance fund | k floor | NVDA shares where it bites |
|---|---|---|---|
| 1 | $50M | 0.0003 | ~17,778 |
| 2 | $250M | 0.0002 | ~40,000 |
| 3 | $500M | 0.00015 | ~71,111 |
| 4 | $1B+ | 0.0001 | ~160,000 |

On 2.5M NVDA shares a Tier 4 Goldman posts $53.4M; a Tier 1 broker posts $160.1M. Accounts run normal above IMF, reduce-only between MMF and IMF, and liquidate below MMF in ~600 ms rounds. Unrealised profit counts as margin — "the single biggest UX difference between offshore venues and a traditional futures broker".

> [!tension] Large/mid k: 0.0002/0.0003 (older spec, Reg Pathway, Op Doc) vs 0.0003/0.0005 (latest spec, whitepaper); HOOD is mid-cap at 20x in one, large-cap at 25x in the other.

> [!tension] MMF floor 2% (specs) vs 0.5% (Clearing briefing, Op Doc); small-cap 6% (Reg Pathway) vs 2% (whitepaper); multiplier 0.6 vs 0.5.

> [!tension] The Op Doc forbids publishing Base_IMF or a leverage cap, yet its clearing-member deliverable lists "Base_IMF, max leverage cap" and still cites Exhibit N.

> [!tension] The Op Doc's "100× equivalent at the methodology floor" does not follow from k = 0.0001 with no Base_IMF.

*Sources: Regulatory_Pathway_Technical_Appendix (2025-12-20); GLX Complete Technical Spec.docx (older, Mar 2026); 05_GLX_Complete_Technical_Specifications §6; 06_GLX_Regulatory_Pathway (Apr 2026); 08_GLX_Architecture_Reference (Apr 2026); glx_whitepaper §09B (May 2026); GLX_Clearing_Margin_Briefing; GLX_Complete_Operational_Document §26 (May 2026)*

## Liquidation: the BLP auction, the insurance fund and "no ADL" {#glx-liquidation}

Saheb's most original design was a liquidation auction for market makers that would rule out offshore-style cascades and auto-deleveraging. It was the centrepiece from January to April 2026. In May he dropped it.

**How it grew.** December's waterfall was crypto-style: trader → insurance fund → ADL → DCO guaranty fund, with **Min Insurance Fund = Max OI × Stress Gap × Liquidation Rate × Slippage**. On 5 January came the BLP idea. In February BLPs absorbed positions at the bankruptcy price. By March the auction came first and ADL was gone.

> [!quote] "Backstop Liquidity Providers between the insurance fund and ADL mechanism." — Future Greyline Ideas, 2026-01-05

**The mechanism.** When an account breaches maintenance, its broker cancels open orders and sends the minimum partial close to Onyx as a LIQUIDATION order. Onyx broadcasts a request to every registered BLP. BLPs bid sealed within **500 ms**, must take the full size, and cannot bid below Mark × (1 − 5%) for a long or Mark × (1 + 5%) for a short. Best price wins; the trade prints off-book at zero fees. If nobody bids, the fallback is IOC orders in 25% tranches, 200 ms apart. It is a simplified port of **MIAX PRIME (Rule 515A)**, MIAX's options price-improvement auction.

BLPs must bid every request. In return they get exclusive auction flow and 0/2 bps book fees. Target cohort: Citadel Securities, SIG, Jane Street, DRW, Jump. The flywheel: deeper book → higher limits → more open interest → more auction flow → deeper book.

**Why ADL cannot happen.** VeriClear sees only each clearing member's net position, and force-closing one FCM's customer to cover another's loss would breach CEA §4d segregation. The comparison is 10 Oct 2025 offshore: $19.1B liquidated in 24 hours, and Hyperliquid's ADL closing $2.1B across ~19,000 wallets in 12 minutes.

> [!quote] "No cascades. No ADL. The risk engine doesn't allow them." — 01_Greyline BLP Memo, Apr 2026

**The insurance fund** moved four times: a segregated DCO account (Dec) → a Greyline house account at Dorman fed by the 50 bps liquidation fee, seed "$XXXM (open item)" (Jan–Mar) → mandatory per-broker funds gating leverage (Apr) → a "$1B+ first-loss layer" (Connamara.pdf) or a $1B fund from a Series B "sized to rival Binance's" (Durban memo).

**Why it gave way.** "And then I dropped it. Not deferred — dropped." V1 liquidates on the Onyx order book, "the permanent architecture", because "the BLP architecture was solving a problem that does not exist on this venue… MIAX is already the attraction." The Op Doc removes auction and fund and accepts recourse: "This is not a crypto-style never-owe world."

> [!tension] BLP status: centrepiece of the whitepaper, Series A deck, Reg Pathway and Clearing briefing vs "dropped… permanent architecture" (Investor Doc), which still mentions "Liquidation auction fills (under V2)".

> [!tension] MIAX.pdf and Connamara.pdf (May) still route all liquidations through the auction in the month the Op Doc deletes it.

> [!tension] Insurance fund: mandatory IB-level fund (Reg Pathway), $1B Series B fund (Durban memo), "$1B+" (whitepaper) vs "The venue operates no insurance fund" (Clearing briefing).

> [!tension] "No GLX-IB customer ever owes money on a liquidation" (Arch Ref) vs recourse, "not a crypto-style never-owe world" (Op Doc).

> [!tension] The Clearing briefing says "Customer accounts never go negative" (Part 11) and that a negative residual "is a debit… pursued through ordinary collection" (Part 5).

> [!tension] Without the margin grant "the BLP auction program does not function" (Reg Pathway) vs it "would function mechanically at any margin level" (Clearing briefing).

> [!tension] ADL placement: the 5 Jan idea puts BLPs between the insurance fund and ADL; by March the auction is first and ADL is "structurally impossible".

*Sources: greyline_technical_architecture (2025-12-29); Future Greyline Ideas (2026-01-05); Old Investor Deck (Feb 2026); 05_GLX_Complete_Technical_Specifications §7, §14 (Mar 2026); 01_Greyline BLP Memo and 02_Greyline_Founding_BLP_MOU (Apr 2026); 06_GLX_Regulatory_Pathway; GLX_Clearing_Margin_Briefing; GLX_Memo_Durban; Connamara.pdf; GLX_Investor_Document; GLX_Complete_Operational_Document §33*

## Fees and the fee pool {#glx-fees}

Revenue is one line: a flat maker/taker fee in basis points on notional. Everyone — MIAX, clearing members, brokers and Saheb — is paid from that pool.

| Participant | Maker | Taker |
|---|---|---|
| Retail / customer | 2 bps | 5 bps |
| Registered market maker / BLP | 0 bps | 2 bps |
| BLP auction fills | 0 | 0 |
| Liquidation fee (to insurance fund) | 50 bps of notional | — |

"Fee = Contracts × Price × BPS rate." No volume tiers. The blend: "~40% of trades × 5 bps + ~50% × 2 bps + ~10% × 4 bps = 3.4 bps blended per trade", assuming market makers trade ~85% maker and retail ~80% taker. Other documents use 2.5 bps (Series A deck) or 3.5 bps (revenue model, Feb deck).

| When | Split | Source |
|---|---|---|
| Dec 2025 | DCM 35% / DCO 35% / FCM 30% | MIAX proposal v2 |
| Jan 2026 | 80% Greyline / 20% MIAX; liquidation fees 100% Greyline | HoT, SAA |
| Mar–Apr 2026 | 90/10 on own flow + 20% royalty on other flow | Tech Spec, Arch Ref |
| May 2026, operator | ~100% retained Year 1, ~79% mature; brokers get 40% of customer fees | Whitepaper |
| May 2026, licensor | GLX ~30–36% / integrators ~35–45% / MIAX remainder | Fee Architecture |
| May 2026, licensor | Integrators 40% / Saheb 36% / MIAX 24% | Investor Document |
| Sept 2026 | 60% of transaction-fee revenue + $40M at signing | AP compilation |

The 40/36/24 split gives integrators 40%, then divides the remaining 60% 60/40 between IP holder and operator: 0.6 × 0.6 = 36%. Benchmarks: the "25–33% rule" floor; S&P DJI/CME ~15–19%; S&P DJI/Cboe ~30–50%; MSCI ~25–35%; Hyperliquid HIP-3's 50% as ceiling.

> [!tension] Fee rail: daily in the VeriClear Fedwire (latest Tech Spec, Playbook, Clearing briefing) vs a monthly invoice (older spec, Arch Ref, Fee Architecture, Op Doc: "The DCO sweeps fees with variation margin" is false).

> [!tension] The Fee Architecture calls the prior "~79% retention" and "20% origination royalty" "history, not terms".

*Sources: Greyline_MIAX_Equity_Perps v2/v3 (Dec 2025); MIAX_Heads_of_Terms (2026-01-27); 05_GLX_Complete_Technical_Specifications §2, §15; 08_GLX_Architecture_Reference; glx_whitepaper §03; GLX_Fee_Architecture_Reference; GLX_Investor_Document §8; AP_ALL_DOCUMENTS_ONE_FILE (2026-09-30)*

## Market size: $463T × 2.2 ≈ $1Q {#glx-tam}

The May 2026 method builds the market bottom-up from what customers would move onto perps, then multiplies by market-maker turnover. It lands near one quadrillion dollars a year of cleared notional.

**The napkin.** Crypto perps trade 3–5× spot. Applied to $277T of annual US cash-equity trading, that gives $830T–$1.4Q. The conservative 2× gives $554T.

**The bottom-up.** Ten V1 categories that fit the SFP wrapper sum to $425–501T of customer demand, mid **$463T**. Three carry ~93%: equity-index ETF perps $260T, single-stock perps $110–140T, and migration from total-return swaps $35–55T. Multiply by a **2.2× market-maker circulation** multiplier (range 2.0–2.5×, from CME E-mini, Cboe SPX, Eurodollar and crypto dealer shares): ~$1Q, 3.6× spot. About 75% of the ~$1.2Q equity-index complex stays put (mandates, non-linear products, §1256 tax, plumbing); the absorbed quarter is mostly retail 0DTE flow.

> [!quote] "Perp is ODTE without the expiry." — Advanced_TAM_Methodology, May 2026

**Phase 2** adds foreign index, FX, foreign single stocks, commodities, rates, foreign TRS and direct crypto: $515–885T × 2.2 ≈ $1.5Q more, ~$2.5Q by 2035.

**To money.** $1Q × 3.4 bps ≈ **$340B/yr**; 36% ≈ $122B. On the $554T floor: $188B pool, $68B royalty — against CME's $6.5B of 2025 revenue.

> [!tension] TAM bases drift: ~$20T/yr spot (Nov 2025) vs ~$500B/day (Dec) vs "$100T+" (Feb) vs $277T/yr (Apr onward); $275T vs $277T between decks.

> [!tension] Category fee pool: ~$150B (Competitive Memo) vs ~$125B (Connamara docs) vs ">$100B" (MIAX.pdf) vs ~$340B (whitepaper, Investor Doc).

> [!tension] Perps' share of crypto trading: 75% (Series A deck) vs 84% (Investor Doc).

> [!tension] The documents flag their own $1Q and $11.8T figures as aggressive; the sanity check rests on the crypto perp-to-spot ratio.

*Sources: Advanced_TAM_Methodology (May 2026); GLX_Royalty_Economics (~2026); glx_whitepaper §01–03; GLX_Investor_Document §7; 09_GLX_Competitive_Memo (Apr 2026); GLX_Series_A (May 2026); Greyline.docx (Dec 2025)*

## Regulatory asks and the fee exemption {#glx-reg}

The product lives inside an existing statute: the Security Futures Product framework of 2000, idle since OneChicago closed in 2020. Two substantive asks unlock it; the rest adapt rules to a 1-share contract.

1. **Margin floor.** Replace the 15% minimum (Exchange Act §7(c)(2)(B)(iii); SEC Rule 242.403) with the √Q method, via an SEC §36 order paired with CFTC Rule 41.42(d).
2. **Future delivery.** Confirm that hourly funding satisfies "contract of sale for future delivery" (CEA §1a(44); Exchange Act §3(a)(55)(A)), via a CFTC §4(c)(1)(B) class order plus an SEC interpretation.

Supporting items: staff guidance on credit extension (Release 8107) and risk disclosure (§41.41(b)); and a large-trader threshold rescaled from 1,000 contracts (only 1,000 shares) to ~100,000 shares.

**The fee exemption.** Regulatory fees were sized for OneChicago's 100-share contracts. At 1 share and $1Q of notional (5T round-turns a year) they would swamp the trading fee. At the standard NFA rate ($0.02 a side per contract) a 1,000-share trade pays $20 a side, more than the exchange fee on stocks under ~$40.

| Fee | Today | Asked |
|---|---|---|
| SEC §31(d) | $0.0042 per round-turn → ~$21B/yr | Full §31(f) exemption (2002 precedent, 16 days) |
| NFA Bylaw 1301 | $0.04/RT → ~$200B/yr | Restore the 2012 rate, $0.00008/RT |
| FINRA TAF | $0.00011 + $0.014 minimum | $0.00008/RT, minimum waived |
| Total | $221B/yr (22.10 bps) futures account; $25.6B (2.56 bps) securities account | $400M/yr (0.04 bps) |

> [!quote] "The 2012 parity framework lapsed during a four-year volume gap. GLX is the volume returning." — Fee Exemption v7, May 2026

**Channel and timing.** The plan rides joint SEC/CFTC harmonisation: the Atkins–Pham statement (5 Sept 2025), Michael Selig sworn in as sole CFTC Commissioner (22 Dec 2025), and the Atkins–Selig MOU (11 Mar 2026), with staff contacts Teply (SEC) and Tente (CFTC). Round 1 is a joint meeting with CFTC DMO, CFTC DCR and SEC Trading & Markets, MIAX present, Founding BLP MOUs signed. Petition at weeks 12–15, orders at months 5–8, first trades **7–11 months** after the alliance closes. The 30 May 2026 CFTC policy statement (with BTCPERP) routed equity perps to Rule 40.3 review plus joint SEC review, and the one-pager reframed the petition as class authority: "reviewed once, self-certified forever".

May documents add launch blockers: MIAX Futures' §6(g) registration (6–12 months); VeriClear's §17A registration and a $2B capital test; ISG admission (Bitnomial took ~5.5 years); a perpetual addendum to the risk-disclosure statement. The documents name their own risks: who holds office after 2026, the §7(c)(2)(B)(iii) reading ("the only genuine legal question"), and the calibrated weekend-gap loss.

> [!tension] Exemption count: two (Competitive Memo) vs "four exemptions mapped" (Exec Summary) vs six (Playbook, Reg Pathway) vs 4 + 3 + 3 (Op Doc) vs three gating asks (MIAX.pdf).

> [!tension] SEC §31: a reduced $0.00008/RT rate (Playbook, MIAX.pdf) vs full exemption (Fee Exemption v7).

> [!tension] CFTC route: Rule 40.3 prior approval (Tech Spec §3, Op Doc) vs "§40.6 self-cert" (Tech Spec §10, Feb deck) vs 40.5 (Exec Summary).

> [!tension] March 2026 harmonisation credited to "Atkins and Pham" (Connamara.pdf) vs Atkins and Selig (Op Doc).

*Sources: 06_GLX_Regulatory_Pathway (Apr 2026); MIAX_Execution_Playbook (v2); Fee Exemption.pdf (v7, May 2026); GLX_Regulatory_One_Pager_UPDATED (≥ Jun 2026); GLX_Complete_Operational_Document (May 2026); GLX_Investor_Document §6; GLX Complete Technical Spec §28*

## Tax {#glx-tax}

The contract is a §1234B security future, not a §1256 contract: no 60/40 treatment, and three practical problems.

- **Reporting.** Every disposition gets its own 1099-B line, so a million round-turns can mean a million lines. Wash-sale, straddle and constructive-sale rules apply; the UI warns on long stock + short perp (§1259).
- **§871(m).** Non-US holders face 30% dividend-equivalent withholding. With dividends priced through funding, the proposed base is funding over an ex-date window — which needs an IRS private letter ruling (PLR).
- **Funding payments.** Character unsettled; ordinary income on a 1099-MISC is the conservative default. A PLR costs ~$38,000 and takes 6–9+ months.

> [!tension] Holding period: "short-term… regardless of holding period" (Apr Reg Pathway) vs the long side follows the holding period (May tax memo).

> [!tension] §871(m): a launch blocker (Op Doc §35, tax memo, one-pager) vs "Not applicable in V1" (Op Doc §37, Tech Spec) vs "doesn't apply in V1 wrapper" (TAM doc).

*Sources: GLX_Tax_Characterization (v1, May 2026); 06_GLX_Regulatory_Pathway App. B; GLX_Complete_Operational_Document §35, §37; Greyline Entity Requirements (2026-01-17)*

## Tech stack and architecture {#glx-tech}

The build was split so MIAX added a few engines to systems it already ran, Dorman did almost nothing new, and Greyline (with Connamara) built the broker-side brain. The asset was the **shadow ledger**: a live per-customer position book that is the only gate for pre-trade margin checks.

**January sketch.** ~60–80K lines of code: ledger 8–12K, risk 5–8K, liquidation 4–6K, API 8–10K, web 15–20K, mobile 12–18K. Go back end (QuickFIX/Go), PostgreSQL + TimescaleDB, React, React Native, AWS. "The platform runs itself—humans handle exceptions."

**March split.** MIAX: mark and funding engines, a feed extension carrying mark/funding/index, the PRIME auction port, a bps fee engine from MIAX Pearl Equities. VeriClear: a "Funding Adjustment" settlement line. Dorman: "intentionally minimal" — accept a daily file. Greyline/Connamara: ledger, sub-accounts (20), margin engine, liquidation controller, funding calculator, reconciliation, ops dashboard, API, web and native apps.

> [!quote] "The shadow ledger is the rulebook expressed as backend computation. The unified frontend is the rulebook expressed as customer experience." — GLX_Tech_Stack_Memo, ~Apr 2026

The ledger is "service, not library": one deployment per broker, same code, isolated data. As **Greyline Solutions** it became a 12-component package for any broker: ledger, themable frontend ("Robinhood looks like Robinhood"), API, connectivity, FCM file generator, KYC, payments, certification and more. "The rulebook is the asset; the infrastructure that runs the rulebook is the moat."

| Layer | Technology | Owner |
|---|---|---|
| Onyx extensions, VeriClear config | C++ / MCS | MIAX — Zach |
| Shadow ledger | OPEN: C++ on Connamara EP3 vs Java 21 + LMAX Disruptor | "Decision belongs to Dan" |
| Connectivity, public API | Go (QuickFIX/Go) | Connamara |
| Frontend, terminal, mobile | TypeScript/React, TradingView, React Native | Brett Harrison |
| Ops and data | Python, Kafka (audit log), Postgres, ClickHouse; AWS with Direct Connect to MIAX NY5 | Connamara |

**API:** REST + WebSocket, no withdraw scope, and an "OpenAPI 3.1 spec at /v1/openapi.json" that "any AI agent can ingest". **Payments:** Plaid bank transfer, wire, and USDC via Circle Mint + CCTP across seven chains, converted into USD at Dorman's BMO Harris segregated account — the only crypto rail in the GLX corpus, an on-ramp rather than collateral. The Op Doc later locks "USD-Fedwire-only collateral".

**Design.** Design Spec V1.2 (12 Mar 2026) rated Hyperliquid (top tier), Lighter (minimalist), Bybit (standard) and Binance (comprehensive) as good; dYdX (dull), OKX (complex), QFEX (legacy) and Ostium (unrefined) as poor. The palette moved from November's orange to a "Lunar" grey/blue: "we want to be the venue for 100m+ notional positions."

> [!tension] USDC custody: "At no point does USDC sit in a Greyline-controlled wallet" vs a build item for "Greyline-controlled wallet infrastructure on the CCTP mint-native chain".

> [!tension] USDC and mobile are P0 in the latest spec but V2 "Low" and "Medium" in its own roadmap.

> [!tension] The Build Manifest says "no premium band, no funding cap, no FVL"; the Op Doc keeps the ±5% premium band and makes Fair Value Limits a launch blocker.

*Sources: greyline-engineer-brief (2026-01-11); 05_GLX_Complete_Technical_Specifications (Mar 2026); GLX_Tech_Stack_Memo (~Apr 2026); GLX_Technical_Build_Manifest (~May 2026); Perpetual Exchange Examples / GLX Design Specification V1.2 (2026-03-12); GLX_Complete_Operational_Document*

## The MIAX relationship: Skunk Works, the SAFE and the Path to Close (Mar–Apr 2026) {#glx-close}

MIAX was the only US group with a DCM, a leverage-capable DCO and an FCM under one roof, so every model ran through it. By April the relationship had a 50-day plan with named people on both sides.

**MIAX in the documents.** NYSE-listed since 14 Aug 2025; four options exchanges, 18.2% share; 2025 revenue $431M. Its clearinghouse, from the Minneapolis Grain Exchange, was grandfathered on 21 Dec 2000. On 21 Jan 2026 it sold 90% of MIAXdx (ex-LedgerX) to a Robinhood/SIG venture.

**Skunk Works (Mar).** MIAX's development calendar was full "through Q1 2027". Greyline proposed a 2–4 person unit across MIAX, VeriClear and Dorman, on MIAX payroll, with 0.25–0.50% Greyline equity, milestone-vested; its "Director of Special Projects" would join the GLX board.

**The MIAX SAFE.** $12M from MIH, post-money YC, 15% discount, no cap ("MIAX converts at 85%"). Path to Close added **Performance Warrants**: $0.01 strike, 3.5% of fully diluted post-Series A, four milestone tranches, 10-year expiry, plus a permanent MIH board seat.

**Nine instruments** MIAX would actually sign: Product Licensing Agreement (MIAX Products, LLC); Exchange Services Framework + Rulebook Side Letter; VeriClear Clearing Side Letter; Guaranteed IB Agreement (Dorman); Onyx connectivity; Exchange Data Agreement; Insurance Fund Segregation Letter; the $12M SAFE; the Performance Warrant.

**The pairings.**

- BLP outreach: Saheb + **John Smollen**, MIAX EVP New Product Development — 30 years at Goldman Sachs and Cboe, Cboe Member Vice Chairman in 2006. "Smollen opens doors and runs the MOU conversation with Saheb."
- The definitive stack: Saheb + **Joe Ferraro** (Joseph W. Ferraro III), SVP & Deputy GC of MIH and President of MIAX Products since 10 Nov 2025 — "one person at MIAX who can drive and sign the full stack".
- The Series A: Smollen → SIG → Dooley → **Egon Durban** at Silver Lake.

**The 50 days.** Days 1–14: entity, SAFE and warrants signed, $12M wired, glx.com bought, soft calls to Citadel and SIG, then DRW and Jump. Days 14–35: data room, Zach Dexter as COO, CCO hired, MOUs signed, Head of Markets, 2–4 Founding BLP SAFEs. Days 35–50: Durban, diligence, term sheet. Named risks: SIG is "triple-hatted" (path to Silver Lake, MIAXdx co-owner, BLP target), Dexter's non-compete, warrant tax at MIH. The April Regulatory Pathway lists the alliance as the "Current bottleneck", dependent on "Joe Ferraro / Tom Gallagher".

> [!tension] The May Series A deck shows "MIAX STRATEGIC ALLIANCE [SIGNED]" and "$12M SAFE SIGNED"; Mar–Apr documents present both as asks, and every alliance draft in Drive is unsigned.

> [!tension] The Connamara memo cites "Four CFTC-registered entities under a signed strategic alliance"; the HoT/SAA in the data room are unsigned.

> [!tension] MIAX market cap: ~$3B (Exec Summary, Deck) vs ~$5B (Investor Document).

*Sources: 07_MIAX_Skunk_Works (Mar 2026); 01_Executive_Summary and 02_MIAX_Partnership_Deck (Mar 2026); 10_GLX_Path_to_Close (Apr 2026); 06_GLX_Regulatory_Pathway (Apr 2026); GLX_Series_A (May 2026); 11_GLX_Connamara_Acquistion; GLX_Investor_Document §4*

## Buy the stack (May 2026) {#glx-buy}

In May the plan inverted: instead of renting MIAX's licences, GLX would buy them, funded by a $1B Series A at $10B pre-money / $11B post-money led by Silver Lake.

**The transaction (MIAX.pdf, V.1).**

- Silver Lake writes $300–500M and takes a board seat; Founding BLPs subscribe; Bloomberg is invited.
- MIH sells MIAX Futures (DCM + DCO, with Onyx IP and VeriClear) and Dorman to GLX for $265–765M, mostly in GLX preferred.
- The vehicle is a **CFTC §38.3(d) Transfer of Designation** into "GLX Perps, LLC" — MIH's own route for MGEX in 2020. Order ~Sept 2026; first listing Q1 2027.
- Pre-close: sell the Bloomberg B500 licence and the Minneapolis wheat book to CME.
- Connamara becomes **GLX Tech** by reverse triangular merger: "~$40–60M, mix of cash and GLX, Inc. Series A preferred".
- Dorman becomes **GLX-Dorman**, a dual Full FCM + Full BD — "the IBKR shape" — so "my AAPL collateralizes my AAPL-PERP". "The Reg 1.57 GIB-and-FCM split retires."
- People: Zach Dexter as President of GLX Perps; asks for Ferraro and Smollen. "Introduce GLX to SIG via John Smollen. The first move."

> [!quote] "We're buying Dorman to make Dorman bigger." — Dorman.pdf, May 2026

| Year | Stage | Cleared | Revenue | Implied value |
|---|---|---|---|---|
| 2027 | Year 1 | ~$7T | ~$1.7B | $60–100B |
| 2028 | Year 2 | ~$40T | ~$9B | $150–300B |
| 2029 | IPO | ~$150T | ~$44B | $700B–$1T |
| 2031–32 | V1 mature | ~$1Q | ~$270B | $3T+ |
| 2035 | Phase 2 | ~$2.5Q | ~$670B | ~$11.8T |

The Investor Document calls this **Plan C**, pitched to MIAX directly: redirect Bloomberg into Bloomberg Beta equity, sell the ag book to CME, roll the registrations into GLX for parent equity, "like Naspers managing Tencent". The MIAX contact replied: "it's kind of like SIG and TikTok."

> [!quote] "I was Rockefeller. The perp was my oil. I was going to be the perpetuals exchange." — GLX_Investor_Document, ~May 2026

**Why it gave way.** Plan C "required MIAX to actually agree to spin out their futures complex… a real institutional ask, and the timing was uncertain." A trimmed Plan D kept the DCM and DCO at MIAX and built a clean-sheet FCM-BD in Florida with white-label distribution; no separate Plan D document exists in the notes. The Op Doc closed the branch: "Mark MIAX.pdf as stale… the canonical commercial frame is the Term Sheet."

> [!tension] Series A size: $100M with Silver Lake LTC as sole financial lead (Durban memo) vs $1B at $11B post (whitepaper, MIAX.pdf) vs no figure (Series A deck).

> [!tension] Year 1: $4T → $1B at 2.5 bps (Series A deck) vs ~$7T → ~$1.7B (whitepaper §10) or ~$2B (§09).

> [!tension] Entity names: GLX Perps, LLC vs GLX Exchange LLC; GLX Tech, Inc. vs GLX Solutions, Inc.; Connamara's legal forms inverted between MIAX.pdf and Connamara.pdf.

> [!tension] Customer protection: Part 190 futures accounts (Op Doc) vs securities accounts with SIPC "permanently" (Connamara.pdf, MIAX.pdf).

> [!tension] The Durban memo is headed "May 2026" but cites Milken (3 Mar) as "last month" — drafted ~April.

*Sources: MIAX.pdf "The MIAX Transaction" (V.1, May 2026); glx_whitepaper (May 2026); Connamara.pdf and Dorman.pdf (May 2026); GLX_Memo_Durban; GLX_Series_A (May 2026); GLX_Investor_Document §5; GLX_Complete_Operational_Document §75*

## Pure licensor, 36%, and the bridge to American Perpetual (May–Jun 2026) {#glx-licensor}

The last GLX model owns nothing operational. GLX licenses the product to MIAX and takes 36% of the gross fee pool, forever.

> [!quote] "GLX's sole role is product originator." — GLX_Complete_Operational_Document, May 2026

Under this "On Margin" framing GLX is not a broker, holds no customer money, and is "not in the money path". There is no auction, insurance fund or ADL; each FCM liquidates through ordinary orders on the lit book. Every broker builds its own shadow ledger. "Connamara is a vendor doc, not a counterparty."

**The royalty.** "36% of the gross fee pool on every perpetual-futures product MIAX lists under the rulebook, in perpetuity, regardless of underlying reference, methodology, or marketing name." Saheb's points sit in **GLX LLC**, a Delaware single-purpose entity whose only asset is the MIAX royalty agreement, against "the binding term sheet I have with MIAX". Capitalised at 15–20×: ~$1.0–1.4T on the $68B floor, ~$1.8–2.5T on the $122B topline.

**The offer.** "I am offering you up to 3.5 of my 36 points, at $30 million per half-point" — $210M for 9.72%, implying $2.16B for the whole. Proceeds to Saheb personally, free and clear; exclusive to Silver Lake Long-Term Capital and Egon Durban. Reasons: fast capital, a decades-long partner, and the next things — a consumer cross-margin app and ventures in "space, minerals, and energy".

**Why licensing.** Every operating layer is "a teaching exercise" that only "participates in the operating margin around the fee pool I already have a share of." "If I am the only person in America who knows how to do any of this, why would I teach anyone but MIAX?" And: "That work didn't fit me. The licensor seat did."

**The bridge.** "On May 20, 2026, MIAX Futures and OCC signed a clearing and settlement agreement expressly to cross-margin MIAX Futures products." The Op Doc leaves open "Whether GLX clears at OCC instead of at VeriClear", which would remove the §17A and capital-test blockers. By 30 Sept 2026 the AP data room shows the answer: **American Perpetual LLC (Originator)**, OCC clearing, "60% of the products' transaction-fee revenue" plus "$40,000,000 wired at signing", Connamara as backup build team. The AP compilation never names GLX or Greyline; the lineage rests on the same founder, venue, spec and pathway.

> [!tension] Royalty sale: 3–5 points for $100–350M, implying $0.72–4.2B (Royalty Economics) vs ≤3.5 points at $30M per half-point, implying $2.16B (Investor Document).

> [!tension] Headline basis: ~$68B/yr with $122B "not used" (Royalty Economics) vs $122B topline and $68B "sub-conservative floor" (Investor Document).

> [!tension] Royalty drift: 20% (Mar–Apr) → ~30–36% band → 36% (May) → 60% (AP), with the base moving from "gross fee pool" to "transaction-fee revenue".

> [!tension] What MIAX actually agreed is unsettled: a "signed" alliance (deck), a "binding term sheet" (Investor Doc), or the stale acquisition (MIAX.pdf).

*Sources: GLX_Complete_Operational_Document §1, §33, §74A, §75 (May 2026); GLX_Investor_Document §5, §8, §11–14; GLX_Royalty_Economics; GLX_Fee_Architecture_Reference; AP_ALL_DOCUMENTS_ONE_FILE (2026-09-30)*

## The competitive memo {#glx-competition}

The argument: a regulated category goes to the first venue that lists it and stays there for decades. GLX's edge was meant to be the pathway and the risk engine, not the app.

> [!quote] "The first exchange to list captures the entire category for fifty years." — 09_GLX_Competitive_Memo (v54), Apr 2026

- **Precedents:** CME equity index futures (1982), CME Treasuries (1977), ICE energy (early 2000s).
- **Category:** $86T of CEX perps in 2025; 2× $277T US cash trading → $500T notional → "~$150B/yr" fee economics, about Visa plus Mastercard. GLX target: "tens of billions annually".
- **Offshore proof:** Hyperliquid — $2.95T cumulative, $844M revenue, eleven people, no VC. Trade.xyz — >$100B cumulative in five months, $600B annualised, and an official S&P 500 licence (18 Mar 2026). 10 Oct 2025 — $19.1B of cascading liquidations.
- **Moat:** relief attaches to MIAX's rulebook, so a rival needs its own 12–24 month petition. Kraken's $550M Bitnomial deal lacks an options business and an auction. "Hyperliquid runs on legal contingency. GLX runs on durable statute."
- **Rival to ally:** the Feb deck listed Architect ($35M, Bermuda) as competition; by April its founder, Brett Harrison, was running GLX's frontend.

**24/7 via Discovery Bounds.** V1's 23×5 is "the one structural non-parity item versus offshore". The fix is trade.xyz's Discovery Bounds: while the stock is closed, the mark is held to a band around the last external price, with a ratchet: `upper_trigger = reference_price × (1 + discovery_bound × oracle_threshold)`, lower symmetric. Liquidation is suspended outside the band. Tech Spec bands: mega ±5% with one reset (±15.8% effective), large ±7% (±22.5%), mid ±7% hard, small ±10% hard. Target: 6–12 months after V1.

> [!tension] Discovery Bounds: ±5/7/7/10% with 1/1/0/0 resets (Tech Spec) vs ±1/2/3/6% with 3/3/3/2 re-anchors (Op Doc).

> [!tension] Hyperliquid: $844M revenue (Competitive Memo, whitepaper), $857M (Investor Doc), ~$900M profit and $4T volume (deck, Durban, Connamara memo); 12 employees (Nov 2025) vs 11.

*Sources: 09_GLX_Competitive_Memo (v54, Apr 2026); GLX_Series_A (May 2026); Old Investor Deck (Feb 2026); 05_GLX_Complete_Technical_Specifications §27; GLX_Complete_Operational_Document §45–51; Untitled "GREYLINE" (Nov 2025)*

## Capital: every raise, SAFE and target {#glx-capital}

The size of the ask tracked the model, from a $20–40M seed to a $1B Series A to a $210M sale of royalty points.

| Date | Ask | Terms |
|---|---|---|
| 23 Nov 2025 | $20–40M seed | Build an own DCM after basket perps |
| 26 Nov 2025 | $30M | COO-led priced seed; "3-5m seed" too "startup-y" |
| 27 Nov–2 Dec 2025 | $100M Series Seed | $100M pre, then $300M pre / $400M post |
| 17 Jan 2026 | $50M at $400M pre | Series Seed form; 4-person board |
| Mar 2026 | $12M MIAX SAFE | 15% discount, no cap; market-maker SAFEs at 5% discount |
| Apr 2026 | $25M Founding BLP SAFE | ~5 firms; no cap; converts at 95% of Series A |
| ~Apr 2026 | $100M Series A | Silver Lake LTC sole financial lead |
| May 2026 | $1B at $11B post | Silver Lake lead; no SAFEs, no bridge |
| May 2026 | ≤3.5 of 36 royalty points | $30M per half-point |

**The Founding BLP SAFE.** Only firms that sign the Founding BLP MOU before the petition is filed may invest. Post-money YC SAFE, **no valuation cap**, converting at **95% of the Series A price**. Target $25M across ~5 firms, in bands of $2.5–5M, $5–10M or $10M+. The window closes when the Series A starts, and the Series A has one investor, so the SAFE is the BLPs' only way onto the cap table. The MOU binds two things — register as a BLP, and file a comment letter on the petition — in exchange for 0/2 bps fees, the auction, MFN within the cohort and 14-day withdrawal rights.

**The VC list** (14 Dec 2025 – 13 Jan 2026): ~140 targets in four columns. "Engineers" are crypto and infrastructure funds. "Power Play" is politically connected: Craft (David Sacks), 1789 (Donald Trump Jr.), Narya (JD Vance), Thrive (Joshua Kushner), Founders Fund ("Peter/Equity Perps"). "CTFC/SEC" lists funds with ex-regulators (a16z, Paradigm, Electric, CoinFund). "Lifestyle" covers Jake Paul, Lucy Guo and Christina Angermeyer. Under "Messaged no response": Founders Fund, Paradigm's Justin Slaughter, Electric, Arthur Hayes' Maelstrom, Gary DeWaal, Brian Quintenz and others.

> [!quote] "Pre-approval, Greyline is a regulatory pathway company. Post-approval, it's a regulated exchange franchise in a category with no domestic competitor" — GLX_Memo_Durban, "May 2026"

> [!tension] BLPs are invited into the Series A "alongside the financial lead" (BLP Memo) vs the lead is the sole Series A investor (SAFE term sheet).

> [!tension] Founder framing drifts: "23-year-old founder", "8 years in crypto", "Building in crypto since 2016", "Decade in crypto markets".

*Sources: Executive Summary (2025-11-23); Founder's Fund (2025-11-26); Greyline.docx (2025-12-02); Greyline Entity Requirements (2026-01-17); List of VCs (2025-12-14); 02_MIAX_Partnership_Deck (Mar 2026); 03_Greyline_BLP_SAFE_Term_Sheet and 02_Greyline_Founding_BLP_MOU (2026-04-16); GLX_Memo_Durban; MIAX.pdf; GLX_Investor_Document*

## Hiring {#glx-hiring}

Every plan kept a small core team around partners' staff. The roles shifted from builders to regulatory and market-structure operators.

| Date | Roles | Pay / equity |
|---|---|---|
| Nov 2025 | Liquid Glass designer, exchange engineer; GC; CTO | GC $400–600K; CTO $500–750K + equity |
| 25 Dec 2025 | Chief of Staff ("a capital formation role disguised as a Chief of Staff"); Founding Engineer | CoS $170–190K or $200–250K + 1%; Eng $220–260K + 1.25% |
| 11 Jan 2026 | Engineer (Go; remote → Miami) | $200–250K + 0.5–0.75% |
| 17 Jan 2026 | Head of Engineering, CCO, FinOP, GC, CRO, independent director | Founder $300–500K |
| Mar–Apr 2026 | Zach Dexter (COO), CCO, Head of Markets; ex-LedgerX team | COO 2%, HoM 1%, CCO 0.75% vs a ~$40B 2029 IPO |
| May 2026 | Heads of Markets, Regulatory, Engineering | Series A option pool |

The founding-engineer brief set the tone: "Lock in the DCM, barrel as many assets as possible, secure market makers, build the liquidity moat before anyone else files." HQ Miami; engineering Chicago.

*Sources: Founder's Fund and Untitled "GREYLINE" (Nov 2025); greyline-chief-of-staff and greyline-founding-engineer (2025-12-25); greyline-engineer-brief (2026-01-11); Greyline Entity Requirements (2026-01-17); 10_GLX_Path_to_Close (Apr 2026); GLX_Series_A (May 2026); 11_GLX_Connamara_Acquistion*

## Future Greyline Ideas and the V2 roadmap {#glx-future}

The five-line "Future Greyline Ideas" note of 5 January 2026 anticipated most of what followed.

1. "Portfolio Margin for equities spot, options, and perps in one account."
2. "24/7 Perpetual Markets"
3. "Global markets"
4. "Backstop Liquidity Providers between the insurance fund and ADL mechanism."
5. "Whitelabel equity perps for coinbase / Robinhood through Dorman FCM."

**V2 roadmap (Mar 2026):** 24/7 (High); spot + perps brokerage (High); options with OCC clearing (Medium); a unified account with portfolio margin, $150K minimum (Medium); crypto perps/spot (Medium); intraday settlement 2–3× a day (Medium); equities as collateral (Low); USDC deposits (Low).

**Phase 2 (whitepaper):** direct crypto perps 2030, commodities 2032, rates 2033, foreign equities 2034–35. Other documents add a novel CEA §4(c) classification for indices, commodities, FX and rates "without SEC co-jurisdiction", a "perpetuals-of-everything platform inside five years", and "Premarket secondaries". Because the alliance's "Perpetual Futures" definition already covered "digital assets", the GLX design links straight back to Saheb's earlier crypto work.

*Sources: Future Greyline Ideas (2026-01-05); 05_GLX_Complete_Technical_Specifications §27; 01_Executive_Summary and 07_MIAX_Skunk_Works (Mar 2026); 09_GLX_Competitive_Memo (Apr 2026); glx_whitepaper §11; GLX_Series_A (May 2026); MIAX_Heads_of_Terms (2026-01-27)*

## Timeline {#glx-timeline}

| Date | Event | Source |
|---|---|---|
| 23 Nov 2025 | Basket perps on MIAX → $100B exchange; $20–40M seed | Executive Summary |
| 25 Nov 2025 | "The pathway to a 100b exchange" | Perps folder |
| 26 Nov 2025 | Letter to Bridget Harris, Founders Fund | Founder's Fund |
| 27 Nov–2 Dec 2025 | First Greyline docs: $100M seed, own DCO/FCM/DCM | Greyline.docx |
| 5–10 Dec 2025 | Pivot to MIAX partnership: proposal v1 → v3 | MIAX proposals |
| 11 Dec 2025 | MOU draft (NewCo JV); OnePager | MIAX MOU |
| 20 Dec 2025 | Data room; first "GLX" (revenue model) | Old data room |
| 22 Dec 2025 | MOU revised (≥40%); Selig sworn in at CFTC | MOU_Revised_Draft |
| 29 Dec 2025 | Technical Architecture; Dorman enters | Tech architecture |
| 5 Jan 2026 | Future Greyline Ideas: first BLP mention | Future Greyline Ideas |
| 11 Jan 2026 | Greyline recast as IB; "GLX Platform" | Engineer brief |
| 17 Jan 2026 | Entity Requirements: $50M at $400M pre | Entity Requirements |
| 21 Jan 2026 | Strategic LOI; MIAX sells 90% of MIAXdx | LOI; Path to Close |
| 27 Jan 2026 | Greyline Markets ↔ MIAX HoT + SAA (80/20) | HoT; SAA |
| Feb 2026 | Investor deck: 24/5, VeriClear, BLP, Connamara | Old Investor Deck |
| 11 Mar 2026 | Atkins–Selig harmonisation MOU | Op Doc |
| 12–13 Mar 2026 | Design Spec V1.2; Technical Spec V1 (90/10, √Q, PRIME auction) | Technical/Build |
| Mar 2026 | Executive Summary, Partnership Deck, Skunk Works: $12M SAFE ask | Data room |
| Apr 2026 | Reg Pathway, Arch Ref v2.5, Competitive Memo v54, Path to Close | Data room |
| 16 Apr 2026 | Founding BLP MOU + BLP SAFE term sheet | Founding BLP folder |
| ~Apr 2026 | Durban memo: $100M Series A | GLX_Memo_Durban |
| May 2026 | Whitepaper, MIAX.pdf ($1B at $11B post), Connamara.pdf, Dorman.pdf, TAM, tax memo, Fee Exemption v7 | Various |
| May 2026 | Investor Document: 36% royalty, offer to Silver Lake LTC | Investor Doc |
| May 2026 | Operational Document: licensor-only; MIAX.pdf "stale" | Op Doc |
| 20 May 2026 | MIAX Futures–OCC clearing and settlement agreement | Op Doc §74A |
| 30 May 2026 | CFTC policy statement + BTCPERP | Funding Mechanism |
| ≥ Jun 2026 | Funding Mechanism spec; Regulatory One-Pager | GLX docs |
| 30 Sept 2026 | American Perpetual: 60% royalty + $40M, OCC clearing | AP compilation |

*Sources: notes 09_Greyline, 07_GLX_A and 08_GLX_B timelines; documents as cited in each row*

## People {#glx-people}

| Name | Role | Relation to GLX | Source |
|---|---|---|---|
| Saheb Swaich | Founder & CEO: Greyline, Inc. → Greyline Markets, Inc. → GLX, Inc. / GLX LLC | Author of the spec, rulebook, risk engine and petition; holds the 36 royalty points | All |
| **John Smollen** | MIAX EVP New Product Development; 30 years at Goldman Sachs and Cboe; Cboe Member Vice Chairman 2006 | Warm-intro layer to Citadel / SIG / Jane Street / DRW / Jump; co-signs BLP outreach; opens SIG → Dooley → Durban | Path to Close; whitepaper; MIAX.pdf |
| Joe Ferraro (Joseph W. Ferraro III) | SVP & Deputy GC, MIH; President, MIAX Products | Signs the nine-instrument stack; "knows the DMO and DCR room" | Path to Close; whitepaper |
| Tom Gallagher | MIAX Chairman & CEO | Alliance sign-off ("Current bottleneck"); "church for Easter Sunday" | Deck; Reg Pathway |
| Zach Dexter | LedgerX co-founder/CTO, later CEO; MIAXdx CEO to early 2026 | Target COO (2%); President of GLX Perps in the buy plan | Path to Close; MIAX.pdf |
| Dan | Connamara leader (possibly Daniel Curry, per the AP data room — unconfirmed) | Decides the shadow-ledger language | Tech Stack Memo; Connamara.pdf |
| Jim; Maureen | Connamara senior team; Maureen chaired the NFA Board 2020–2024 | Acquisition invitees | Connamara.pdf |
| Brett Harrison | Ex-President, FTX US; founder of Architect | Owns frontend and Greyline Solutions | Tech Stack Memo; MIAX.pdf |
| Egon Durban | Silver Lake Co-CEO; Long-Term Capital | Series A lead target; exclusive royalty buyer | Durban memo; Investor Doc |
| Dooley | SIG | Introduction to Durban | Path to Close |
| Bridget Harris | Founders Fund | 26 Nov 2025 letter; "Messaged no response" | Founder's Fund; List of VCs |
| Unnamed MIAX contact | MIAX | "it's kind of like SIG and TikTok" | Investor Doc |
| Atkins; Selig; Pham; Peirce | SEC Chair; CFTC Chair; ex-Acting CFTC Chair; SEC Commissioner | The regulatory window | Reg docs |
| Teply; Tente | SEC and CFTC staff | Harmonisation contacts | Op Doc |
| Citadel Securities, SIG, Jane Street, DRW, Jump | Market makers | Founding BLP cohort; ~$25M SAFE | All |
| MIAX/MIH, VeriClear, Dorman, Connamara, Silver Lake LTC | Exchange, DCO, FCM, engineering, investor | The stack and its funder in every model | All |

*Sources: notes 09_Greyline, 07_GLX_A and 08_GLX_B people tables; 10_GLX_Path_to_Close; glx_whitepaper §06–07; MIAX.pdf §02, §19*

<!-- END CHAPTER -->
