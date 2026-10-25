# IV. American Perpetual — the product and the machine

American Perpetual is a perpetual future on one U.S. stock. It has no expiry date and settles in cash on 100 shares. An hourly funding rate holds it to its stock. It is listed on MIAX Futures' Onyx platform, cleared at OCC (the Options Clearing Corporation), and regulated jointly by the SEC and CFTC as a security futures product (SFP), under the framework as written. The design is finished on paper: a 124-page Unified Technical Specification, a 38-page OCC Clearing Brief, two playbooks, 73 pages of runbooks and a pre-written notice for every event. As of the data-room compilation of September 30, 2026, nothing was filed and nothing was signed.

Only one part of the product is new. Funding, the hourly payment between longs and shorts that replaces expiry, is cleared by OCC as ordinary variation margin, inside the daily settlement OCC already runs. Everything else is restarted rather than invented.

> [!quote] "This product is the OneChicago OCX.NoDivRisk contract with the expiry removed and clearing-grade hourly funding added." — MIAX Brief End-to-End, Sept 2026

This chapter walks through the contract and the machine around it. The legal path is Chapter V. The licence economics (a 60% royalty on Covered Fees and a $40,000,000 signing payment) are Chapter VI and appear here only where the machine touches them.

## The contract on one page {#ap-contract}

The contract is a standard security future with one change: it has no expiry. Every term is fixed once for the whole class, in Rulebook Chapter 43 and Part A of the Specifications Supplement. After that, each name is one row in a schedule.

| Term | Value | Where it lives |
|---|---|---|
| Type | Cash-settled, no-expiry single-name equity SFP; joint SEC/CFTC jurisdiction | Rules 43.1, 43.7 |
| Unit | 100 shares; multiplier ×100, "never adjusted for any corporate action" | Rule 43.4 |
| Tick | $0.01 per share = $1.00 per contract; USD | Rule 43.5 |
| Expiry | None. No contract months, no roll; final settlement only on a Terminal Settlement Event | Rules 43.7, 43.16 |
| Universe | One class; 101 inaugural names "SPY through MIAX"; later names by day-before certification | Rules 43.2, 43.22 |
| Symbol | Ticker + P (NVDAP, SPYP, BRKBP, GOOGLP; Visa → VP; Citi → CP) | Sentinel & Symbology Card |
| Index / Mark | SIP consolidated NBBO midpoint / median(last, bid, offer) on the contract's book | Rules 43.8, 43.9 |
| Funding | Hourly: TWAP((Mark − Index)/Index) ÷ 24, locked at the top of the hour, final | Rules 43.10, 43.11 |
| Daily settlement | VWAP of the Mark, 3:59:30–4:00:00 p.m. ET | Rule 43.12 |
| Hours | SIP 23×5 tape: Sun 9:00 p.m. – Fri 8:00 p.m. ET, daily 8–9 p.m. break (from Dec 6, 2026) | Rule 43.6 |
| Halts / limits | Halts with the stock (regulatory, LULD, market-wide); no daily price limit; 5% collar; orders within ±20% of prior settlement; max order 1,000 | Rules 43.13, 43.14 |
| Margin | 15% federal floor (futures account); 20% FINRA 4210 or portfolio margin (securities account) | Rule 3.3.2 |
| Position limits | 25,000 contracts, or accountability at 25,000; reportable at 1,000 | Rules 43.18, 43.20 |
| Blocks / EFP | ECP-only blocks, minimum 15 contracts, reported within 15 minutes; EFP against the stock | Rule 43.24 |
| Clearing | OCC on Ovation; funding paid inside daily variation (OCC Rules 501/502) | Rule 43.11 |
| Tax | §1234B for customers; §1256(b)(1)(E), (g)(9) for dealers; no 60/40 claim | Brief p4 |

Rule 43.7 defines profit and loss in one sentence: "the change in the Mark Price since the position was established, multiplied by the trading unit, plus or minus net Funding Adjustments." The eligible universe is the options-eligible universe, and settlement at OCC lets a firm hold the perpetual in the same margin account as the stock and its options.

The recommended launch fee is $1.50 per contract per side, or $0.40 for market makers. Funding is not a fee, and "The Exchange never takes any of it." The Section 31(d) security-futures assessment of $0.0042 per round turn is passed through.

*Sources: MIAX Brief End-to-End (Sept 2026); Rulebook Insertion & Amendment Package v2.8 (Sep 30, 2026); Sentinel & Symbology Card v1.0 (Jul 7, 2026; rev. Sep 30, 2026); Runbooks v1.9 (Sep 17, 2026; rev. Sep 30, 2026)*

## The funding machine {#ap-funding}

Funding replaces expiry. Each hour, Onyx averages the gap between the contract and its stock and locks one rate. When the contract trades rich, longs pay shorts. When it trades cheap, shorts pay longs. The payment passes between holders, nets to zero and never touches the Exchange. The OCC Clearing Brief calls it the product's "enabling core, reusable across further perpetual classes to follow".

The Brief states the whole machine in six lines:

| Line | Formula | Note |
|---|---|---|
| Index | midpoint(consolidated NBBO) | The stock, from the SIP |
| Mark | median(Last, Bid, Offer) on the contract's own book | The contract |
| Premium | Mark − Index | What funding disciplines |
| Funding Rate | TWAP((Mark − Index) / Index) ÷ 24 | Flat TWAP over the hour, 5-second samples; published = applied per-hour value; final at the lock |
| Funding Adjustment | Funding Rate × Mark × net contracts × 100 | Positive rate: longs pay, shorts receive |
| Mark (paused) | Index + last valid Premium | Nothing accrues while paused; an hour with no valid sample still prints its row (rate 0, status paused, final) |

### Sampling and the lock

Onyx samples the premium ratio every 5 seconds, about 720 times an hour. The rate is the plain equal-weight average of those samples, divided by 24 once, at the lock. The lock fires at :00 on the Onyx clock and is then final, with no bust and no true-up.

No other step divides, scales or converts the rate. Rule 43.10(d) says this applies to "the Exchange, the OCC, any OCC Clearing Member, or any other person". Every booking anywhere is rate × mark × contracts × 100. That makes the system an audit identity: a clearing firm can recompute its wire to the penny from public data.

A predicted rate ticks every 5 seconds and converges into the lock "with no jump". Because the average is flat, "Nothing happens at :00 for a quoter", which is why the design chose it over Kalshi's end-weighted "WAPI".

### Two worked hours

1. **Headline case.** The rate locks at +0.000042 per hour on a $250.00 Mark. A customer long 10 contracts books 0.000042 × 250 × 10 × 100 = **$10.50**, and the shorts receive $10.50. Over a 23-lock cycle this is about 0.097% per funded day. A funded day has 23 hours, never 24.
2. **From samples.** In the 2–3 p.m. hour, 720 samples average +0.072%. Divided by 24, that gives +0.0030%. At a lock Mark of $250.25, 10 contracts pay **$7.51**.

### The cycle and the pause

A Trading Day has 23 locks, from 22:00 through 20:00. The settlement cycle runs close-to-close, covering every lock after the prior 4:00 p.m. closing lock through today's.

- A regular cycle has 23 rows: 4 evening, 7 overnight and 12 day.
- An early-close cycle has 20 rows.
- A name's first cycle has 19 rows.

The rule is "Build to the cycle, never to a constant."

Pause is the only non-normal state. It applies when the Index has no coverage or is halted, when Trading Status is Halt, Operational Halt or Closed, or when a Mark input is missing. During a pause the Mark rests at Index + last valid premium and nothing accrues. A partly live hour funds on its valid samples, however few. A fully paused hour still locks a row with rate 0. "A thin book is not a pause": there is no thin-book special case and no zero-rate fallback.

### Who pays

Funding is struck at each lock instant, not at an end-of-day snapshot. A trade counts at a lock only if it executed strictly before HH:00:00.000. Execution times are truncated to the second, never rounded. A position opened and closed between two locks pays no funding. A position held across a lock pays the whole hour.

> [!quote] "Striking at the locks rather than end-of-day is what makes funding un-gameable: you cannot flatten a second before the close and pay nothing." — Unified Technical Specification, Vol. I, Jul 7, 2026 (rev. Sep 30, 2026)

Screens show funding per live hour. An annualized figure, if shown at all, is "hourly rate × funded hours per day × trading days per year (23 × 252). Never × 24 × 365". It is "Never the headline number." A customer's equity is cash + unrealized P&L + unrealized funding.

> [!number] $10.50 — one worked hour of funding
> +0.000042/hr × $250 Mark × 10 contracts × 100. The ÷24 is applied once, at the lock; no divisor exists downstream.

*Sources: MIAX Brief End-to-End (Sept 2026); OCC Clearing Brief (Sept 2026); Unified Technical Specification v1.0, Vol. I and Annex C (Jul 7, 2026; rev. Sep 30, 2026); Rulebook Insertion & Amendment Package v2.8 (Sep 30, 2026)*

## Index and Mark: the two prices {#ap-index-mark}

The Exchange computes nothing upstream of the Index. It is the midpoint of the SIP consolidated NBBO: CQS for Tapes A and B, UQDF for Tape C. A sample counts only if the quote is two-sided and not crossed. A locked quote counts. There is no staleness test. An invalid sample is excluded, and the last valid value is carried for display only. The Harmonization Submission calls this "reliability by exclusion, never fabrication". In code it is "one accumulator plus one valid-sample counter".

The Mark is the median of last trade, best bid and best offer on the contract's own book. It applies when the book is two-sided and a trade has printed. Otherwise the Mark is Index + last valid premium, which is zero before a name's first valid instant. Blocks and EFRPs are not inputs.

Feed health works as a halt. A tape outage pauses that tape's names, a full SIP outage pauses all of them, and a Level 3 market-wide halt closes the perpetual, with the remaining locks printing as paused zero rows.

MIAX Futures is the SIP subscriber of record. The Index is published free as derived data, midpoint and status only, never the underlying quotes. A non-distributed audit record keeps the bid and offer behind every Index sample for five years.

### One record, three rails

Each lock writes one position-free record: lock time · rate · Mark · Index · Index status · Funding Status. The record goes out on three rails, "live off the feed, replay off the file":

1. **Message 18 "Funding Rate"** on the Onyx ToM and DoM feeds: a predicted value every 5 seconds and a settled value at each :00.
2. **The public funding file** `onyx_financials_funding_rate_YYYYMMDD.csv`. One file per cycle covers the whole class and sits on the Onyx Listings page. It is rewritten whole within seconds of each lock and never appended. It carries a running per-contract total, so a trade's share of the cycle is a single subtraction. This is the free "public historical-funding endpoint" of new Rule 6.21.
3. **The nightly furnish to OCC**, sent once after the closing lock on the settlement-price rail, together with the daily settlement price and any dividend amount. "OCC never reads the feed."

The specification's six invariants come down to this: one record per lock, never absent; the pool sums to zero before money moves; cash is rounded once, at the wire. Rate, Mark and Index carry nine decimals. "Binary floating point never decides cash."

> [!quote] "'anyone can recompute the number' is worth more than a data fee — the crypto venues run the same free posture." — Unified Technical Specification, Vol. I, Jul 7, 2026 (rev. Sep 30, 2026)

*Sources: Unified Technical Specification v1.0, Vol. I and Annex A (Jul 7, 2026; rev. Sep 30, 2026); Rule 41.23 Listing Submission, Index Source Appendix (draft, Sept 2026); Harmonization Submission (draft, Sept 2026)*

## Daily settlement and the money path {#ap-settlement}

The funding rate is set every hour, but cash moves once a day, on rails OCC already runs.

The Daily Settlement Price (DSP) is "the volume-weighted average of the Mark over the half-open interval (3:59:30, 4:00:00 p.m. ET], computed from the six five-second sub-intervals". With no volume in the window, it is the simple average of the six Marks. On a half-day the window is 12:59:30–1:00:00 p.m. Two different numbers exist at 4:00 p.m. The 16:00 funding row uses the Mark at the instant of the lock, while the DSP is the 30-second windowed VWAP. The specification's instruction is "Never conflate them."

Annex C writes variation as 100 × ((DSP_today − DSP_prior) × q₀ + Σ (DSP_today − pⱼ) × Δqⱼ). Funding rides in the same daily payment as its own itemized line. Settlement is the next business day: members pay OCC by 9:00 a.m. ET and OCC pays members at 2:00 p.m. ET (OCC Rules 101, 501/502, 1301).

> [!quote] "the settlement is two lines, variation and funding, and never a third." — OCC Clearing Brief, Sept 2026

### How OCC turns rows into cash

The Exchange furnishes position-free rows. OCC applies them to its finalized book. Only OCC can do this, because give-ups, allocations and transfers make the cleared book differ from the raw match. Each member's funding for a cycle, per OCC account, is:

**start-of-cycle position × the cycle's per-contract total + Σ (each trade's signed quantity × the per-contract total of the locks after it).**

Netting runs at two levels: first inside each FCM, then across clearing members at OCC, where the pool must equal zero at full precision. The check runs per name and per cycle, never across names. It holds by construction, because positions net to zero and every trade has two sides.

That check is "the one genuinely new control." If it fails, OCC corrects the position record and re-runs it. If it still fails, that name's cycle is held and paid later, never applied to later positions, while every other name settles. "No rate is re-made."

Give-ups move funding forward only. "OCC never re-allocates settled funding retroactively." Each account line is rounded once to the cent. The few cents by which the rounded lines miss zero stay with OCC, "the counterparty to every member."

> [!quote] "OCC computes the cash, not the rate." — OCC Clearing Brief, Sept 2026

*Sources: OCC Clearing Brief (Sept 2026); Unified Technical Specification v1.0, Annexes B and C (Jul 7, 2026; rev. Sep 30, 2026); Runbooks v1.9, C1 and O2 (Sep 17, 2026; rev. Sep 30, 2026)*

## Margin: four layers, nothing net-new {#ap-margin}

"Nothing about the margin model is net-new." The perpetual inherits the OneChicago/OCC single-stock futures model in four layers.

| Layer | Set by | What it is |
|---|---|---|
| A · Clearing margin | OCC | STANS: 10,000-scenario Monte Carlo, 99% expected shortfall, two-day margin period of risk (Rule 601); gross SPAN for segregated futures accounts |
| B · Customer parameters | OCC | MFE OFRA SPAN scan-range file, updated monthly |
| C · Regulatory floor | CFTC + SEC | 15% of current market value, initial and maintenance, since Dec 24, 2020 (17 CFR 41.45(b)(1) / 242.403(b)(1)) |
| D · Portfolio margin | OCC / FINRA | Nightly RBH/CPM values (TIMS), one requirement across perp, stock and options; floor $37.50 per contract (FINRA 4210(g)(7)(B)) |

A customer's initial margin is "scan range % × underlying price × 100 shares". At 15% on a $75 stock, that is $1,125. The Exchange publishes no margin numbers. "No per-name leverage figure — leverage is broker-set."

The account type sets the floor. A futures account pays 15%. A securities account pays 20% under FINRA Rule 4210's strategy-based schedule unless it is portfolio-margined. Chapter V covers the ask to FINRA to close that gap. Market makers registered as Security Futures Dealers are margined house-side under Rule 3.3.2(e) once the SEC approves it.

Funding sits in neither margin number. It is "not a STANS or TIMS scenario input, not a customer-margin add-on; no funding-driven recalibration, exchange margin program or separate fund."

OCC's set-up work is to re-light the dormant security-futures scan class (discontinued Sept 18, 2020) and map each name into the class group of its stock and options.

*Sources: OCC Clearing Brief (Sept 2026); Unified Technical Specification v1.0, Annex B §B.7 (Jul 7, 2026; rev. Sep 30, 2026); MIAX Brief End-to-End (Sept 2026)*

## Position limits and accountability {#ap-limits}

Limits are "two levels of one number". Every name is held at 25,000 contracts, either as a hard limit or as an accountability level, and a name moves between the two only when its data moves.

The federal regime (17 CFR 41.25(b)(3)) has three branches. The class uses two of them.

- **Default limit.** At most 25,000 contracts net or same side, which is 2,500,000 shares. The figure was raised from 13,500 in 2019.
- **(B) accountability instead of a limit.** This applies when six-month volume exceeds 2,500,000,000 shares and free float exceeds 40,000,000. A holder above 25,000 contracts must give information on request and stop increasing when ordered: "a large holder is seen rather than stopped."
- **(A) higher limit.** Up to 12.5% of free float ÷ 100 contracts, where float exceeds 20,000,000 shares. This is reserved name by name and not adopted at launch.

Federal text applies limits in the last three trading days of an expiring month. A perpetual never expires, so the limit applies at all times (Rule 43.18). The playbook calls this "the more conservative reading, not a relaxation". The precedent is OneChicago's weekly futures, in a §41.24 submission dated Dec 20, 2013.

The reportable level is 1,000 contracts. Limits are reviewed every six months on June and December data, and a lowered limit must be met within 30 days. Hedge and spread exemptions are filed before exceeding and decided within 5 Business Days (Rule 43.25). A split that pushes a position over the limit is not a violation. "OCC does not enforce exchange limits; the Exchange does." FCMs load pre-trade controls from a machine-readable limits file, so "a change is a parameter update, not a build."

Applied to consolidated six-month data, the rules put **33 names on accountability and 68 on the 25,000-contract limit.** SPCX, SKHY and CBRS start on the limit and are tested for (B) after six months of trading.

At August 26, 2026 prices, 25,000 contracts is worth about:

- $93M of SMCI;
- $108M of MIAX;
- $111M of IBIT;
- $528M of NVDA;
- $4.36B of ASML.

> [!number] 25,000 contracts — one number for every name
> 33 names on accountability, 68 on the limit; the (A) branch up to 12.5% of float is reserved, not adopted.

> [!tension] Rivals carry 200,000-contract limits (CME, Coinbase, Bitnomial; Kalshi's cap); AP starts at the federal 25,000 and raises names only on data.

*Sources: Listing and Position-Limit Playbook v1.4 (Sep 16, 2026; rev. Sep 30, 2026); Rule 41.23 Listing Submission (draft, Sept 2026); Specifications Supplement v1.3 (Sep 22, 2026; rev. Sep 30, 2026); How to Win (Sept 2026)*

## The 101 names {#ap-names}

The launch roster is 101 names, "SPY through MIAX". All 101 go in one request, list as one batch and start trading on the same day, T.

| Nos. | How chosen |
|---|---|
| 1–35 | "the thirty-five of September 4" (2026) |
| 36–100 | "sixty-five more by average daily dollar volume" |
| 101 | MIAX (Miami International Holdings), the Exchange's parent, listed as an Affiliate Security under new Rule 43.2(d) after the Regulatory Oversight Committee approves it |

By type, the roster is:

- 12 ETFs;
- 2 trust-issued receipts (GLD, a gold trust; IBIT, a bitcoin grantor trust);
- 4 ADRs (TSM, ARM, SKHY, BABA);
- 1 New York Registry share (ASML);
- 82 common stocks.

It includes three 2026 listings: SpaceX (SPCX, June 12), Cerebras (CBRS, May 14) and the SK hynix ADS (SKHY, July 13). Six-month volume, measured to August 26, 2026, runs from NVDA's 19,437,733,539 shares down to MIAX's 200,988,820.

| No. | Ticker → symbol | What it is | Branch | Why it matters |
|---|---|---|---|---|
| 1 | SPY → SPYP | S&P 500 ETF | Accountability | Carries the exposure the marquee index licences keep elsewhere |
| 5 | NVDA → NVDAP | Nvidia | Accountability | Largest volume; 25,000 contracts ≈ $528M |
| 31 | MSTR → MSTRP | Strategy Inc. | Accountability | Bitcoin-treasury equity |
| 32 | HOOD → HOODP | Robinhood | Accountability | Also the retail launch-partner target |
| 53 | IBIT → IBITP | iShares Bitcoin Trust | Accountability | Bitcoin exposure on day one |
| 66 | IREN → IRENP | IREN | Accountability | Bitcoin miner / AI cloud |
| 68 | COIN → COINP | Coinbase | Limit | Parent of a rival venue |
| 97 | CRCL → CRCLP | Circle Internet Group | Limit | USDC stablecoin issuer |
| 101 | MIAX → MIAXP | Miami International Holdings | Limit | The Exchange's own parent |

Six of the 101 are crypto-linked: IBIT, MSTR, COIN, HOOD, IREN and CRCL. They are the first bridge to the crypto work in other chapters. Before any crypto class is filed, they give an OCC-cleared perpetual on a bitcoin trust and on the main U.S. crypto equities.

**Accountability (33):** SPY, QQQ, NVDA, MSFT, AAPL, AMZN, GOOGL, TSLA, AVGO, AMD, INTC, MU, MRVL, ORCL, PLTR, CRWV, MSTR, HOOD, RKLB, IWM, EWY, WMT, NFLX, IBIT, GDX, CSCO, NOW, BAC, XLE, IREN, XLF, SMCI, EEM.

**Limit (68):** SMH, GLD, META, SNDK, TSM, QCOM, WDC, AMAT, LRCX, ASML, ARM, LITE, DELL, APP, GEV, SPCX, NBIS, BE, SKHY, STX, CRM, MRNA, LLY, V, JPM, XOM, CRWD, PANW, BRK.B, CAT, COHR, GS, COST, CVX, KLAC, UNH, COIN, JNJ, SNOW, TXN, MA, MRK, GLW, SHOP, CBRS, XLV, CRDO, VRT, UBER, HD, XBI, ADI, MCD, KO, GE, BKNG, IBM, BABA, ADBE, ALAB, BA, INTU, PG, CRCL, C, ANET, XLI, MIAX.

Every name must pass six listing tests (Chapter V), re-run on the filing date: "a name that has slipped is held." After launch, each new name needs one Schedule row and one certification, received the business day before its first session. "Which names to list next is the Exchange's choice; the agreement sets no order and no minimum." For scale, OneChicago listed futures on about 1,500 equities at its peak in November 2014.

> [!number] 101 names — one request, one batch, one day
> 33 accountability / 68 limit; 12 ETFs, 2 trust receipts, 4 ADRs, 1 NY Registry share, 82 common stocks.

*Sources: Specifications Supplement v1.3 (Sep 22, 2026; rev. Sep 30, 2026); Rule 41.23 Listing Submission, App. A (draft, Sept 2026); Listing and Position-Limit Playbook v1.4, Part IV (Sep 16, 2026; rev. Sep 30, 2026); How to Win (Sept 2026)*

## Corporate actions: four lanes, no residue {#ap-corporate-actions}

A dated future can carry an awkward adjustment to its expiry and settle it there. A perpetual has no expiry to absorb it. So the design adjusts only where the arithmetic is exact and terminates the contract everywhere else.

> [!quote] "Because the contract has no expiration, nothing a stock does to it can be carried to an expiry and flushed there: it is adjusted only where the arithmetic is exact, and terminated where it is not" — Corporate Actions Operations Playbook v1.2, Sep 16, 2026

One classifier sends every event to exactly one lane: "declared cash → A; whole-number ratio → B; anything else with value or a re-basing → C if the name survives with a Consolidated NBBO, D if it does not". Rule 43.15 says "four categories, and into no others."

| Lane | Events | Treatment | Example |
|---|---|---|---|
| A · Cash | Ordinary, special, capital-gain, return-of-capital, ADR gross | On the ex-date, prior settlement steps down by the declared per-share amount (4 decimals) under OCC Rule 2803(o); the value arrives through variation | $0.50 dividend: 32.40 → 31.90; a 10-lot long gains $500 |
| B · Whole split | 2:1, 3:1, 4:1, whole stock dividends | Contracts ×N, prior settlement ÷N to $0.0001; same symbol, ID and 100-share unit | 3-for-1: 10 × 100 × $300 = 30 × 100 × $100 |
| C · Structural, name survives | Reverse and odd splits, spin-offs, valued rights, stock-for-stock mergers | Trades through the last cum session, settles at that DSP, terminates; a successor lists next session with zero open interest | "No one valued SPN." |
| D · No continuing market | Cash merger, delisting, liquidation, NBBO loss, halt over 10 trading days, OCC stops clearing | Cash settlement at the first available of: deal cash → last reliable NBBO midpoint → primary official close → OCC value | $52.00 cash merger |

Four rules hold across the lanes.

- **Ex-date symmetry.** The Index and the prior settlement step down together. The premium does not move, and funding charges nothing extra. The Brief calls this "symmetry, not a patch." Funding never pauses for a corporate action.
- **No conversion, baskets or valuation.** "the market converts the ratio, not the Exchange. Nothing about the 100-share unit changed, and no one divided a contract by ten."
- **Resting orders are purged** before every A or B event.

In-place adjustment of structural events only works when an expiry flushes the residue. Eurex's R-factor shows the drift otherwise, with one contract moving from 1,000.0000 to 998.5180 shares in February 2026. A reverse split also cannot be count-adjusted without creating fractional contracts.

The desk makes three moves on every event: decide, report to OCC, publish, using one of four pre-written Corporate Action Alerts. "No one estimates a value — every number is an issuer's declared amount or a market price."

A final settlement happens only by rule. The Termination Notice designates the last session as the contract's maturity date, following the September 2020 precedent when OneChicago accelerated its maturities. An OCC standing rule then sets the price. On its last day, a terminating name "is an expiring future".

### §871(m), made clean

Foreign holders of a delta-one position on a U.S. dividend payer face dividend-equivalent withholding under §871(m). Lane A's published factor doubles as the withholding base: **base = factor × 100 × contracts**. A non-U.S. long receives its gain less 30% (or the treaty rate) on that base. "It does not avoid §871(m) — it makes §871(m) clean." This opens the product to foreign flow. How to Win cites the July 2026 Korea leverage unwind, which margin-called 1.2 million retail accounts, as evidence of that demand.

Rival venues handle dividends three other ways. CME forecasts them in the basis. Kalshi passes them through funding. Coinbase and Nadex do not adjust. Only Bitnomial adjusts in cash by rule, as AP does.

> [!quote] "Four lanes. No conversion, no valuation, ever." — MIAX Brief End-to-End, Sept 2026

*Sources: Corporate Actions Operations Playbook v1.2 (Sep 16, 2026; rev. Sep 30, 2026); Unified Technical Specification v1.0, Vol. II (Jul 7, 2026; rev. Sep 30, 2026); OCC Clearing Brief (Sept 2026); MIAX Brief End-to-End (Sept 2026); How to Win (Sept 2026)*

## What OCC must decide, and what it builds {#ap-occ}

OCC has one decision to make, and everything waits on it. **Funding must be variation**: a novated Funding Adjustment that moves between clearing members on the existing daily wire, nets to zero and never touches the venue. Nothing goes to the CFTC or SEC until OCC agrees (link 12 of the launch sequence).

The Clearing Brief ("Built once for OneChicago. Ready for Ovation.") makes three asks:

1. Onboard the product on Ovation, OCC's new clearing platform, restarting the dormant single-stock futures clearing. The Brief specifies "no ENCORE integration of any kind"; ENCORE is OCC's mainframe from 2000.
2. Clear funding through members as variation.
3. Run the corporate actions OCC already wrote: the NoDivRisk dividend engine (Rule 2803(o)) and the split count method. "Everything structural terminates clean: no open-interest conversion, ever."

MIAX Futures became OCC's fifth participant exchange when the clearing agreement was announced on May 20, 2026. As filed (SR-OCC-2025-008), that agreement covers futures "other than security futures", so it needs a written amendment. The amendment would cover funding as variation and the zero-sum control, and would extend the settlement-price indemnity to funding rows, offered up front on the model of OneChicago's Amendment No. 1.

The class then enters through Schedule C and a new-product proposal. It also needs an extended-hours designation under OCC's ETH Procedure, which was approved September 23, 2026 (Order 34-106469).

OCC builds three new pieces. Everything else is configuration.

1. **Intake** of the nightly cycle set.
2. **Computation** of each member's cycle funding, with the per-name zero-sum control.
3. **A Funding Adjustment line** on DDS (Data Distribution Service): a separately typed amount beside futures mark-to-market, one per OCC account.

The work spans eight OCC teams and seven decision families, each with a default. It comes with 32 conformance scenarios (T01–T32) and 8 worked fixtures.

Two points are marked **[confirm-OCC]**, because only OCC can decide them and either could change a filed term:

- **The no-maturity sentinel.** Will every OCC surface accept 99991231 / 9999-12-31? The runbooks call this "The riskiest confirmation in the program." OCC's clearing-member CSV layouts "require a full YYYYMMDD series date".
- **Full-session clearing.** Will OCC clear through the full 23×5 session? If not, the trading hours change before filing.

OCC files one rule change, with the SEC under Rule 19b-4 and with the CFTC under Part 40, in three parts:

- a Terminal-Settlement standing rule;
- an express routing of the class to Rule 2803;
- the agreement amendment.

This filing "gates clearing go-live, not the listing." Default needs no new rule. Accrued, unsettled funding is unsettled variation and ranks that way in OCC's existing waterfall.

OCC's own timetable sets the pace. External scenario testing resumed June 29, 2026. External Parallel Testing runs September 21, 2026 to January 2027. Ovation go-live is projected for 1H 2027.

> [!quote] "One product clears cleanly; one clearer decides the field." — OCC Clearing Brief, Sept 2026

> [!tension] Launch is keyed to Ovation go-live, projected 1H 2027 ("for a 2027 launch"), while three rivals filed perpetual SFPs on September 18, 2026.

*Sources: OCC Clearing Brief (Sept 2026); Unified Technical Specification v1.0, Annex B (Jul 7, 2026; rev. Sep 30, 2026); Runbooks v1.9, C1–C6 (Sep 17, 2026; rev. Sep 30, 2026); How to Win (Sept 2026)*

## Onyx: what changes on the platform {#ap-onyx}

The platform change is small and pinned. Annex A is a delta against MIAX's own posted v1.3a interfaces (July 31, 2026), "so scoping this build is reading, not discovery." Every addition extends a structure that already exists. "Nothing in this annex is a question."

### Message 18

The feeds gain one message, **type 18 "Funding Rate"**. Types 18, 19 and 20 were verified free on both ToM and DoM. Message 18 carries:

- Instrument ID, timestamp and lock time;
- Rate Type (P predicted, S settled);
- the signed per-hour rate, already ÷24;
- Mark and Index;
- Index status (live / no-coverage / SIP feed dead / halt);
- Funding Status (normal / paused).

A P record goes out every 5 seconds and freezes into an S record at each :00. The message is outside the refresh service and travels in MACH's skip-safe envelope, which keeps it backward-compatible. "Front ends take the Index from message 18: the Exchange provides it, so no firm computes its own."

### Saying "never expires"

The perpetual reuses the Simple Instrument record with new values:

- Instrument Type 'P';
- Underlying Asset Type 'S';
- Unit of Measure 'SHR', quantity 100;
- Product Group Code = ticker + P.

The hard part is a date field on a contract that has no date. The answer is one sentinel per surface:

| Surface | Sentinel | Why |
|---|---|---|
| Onyx Contract Date (YYYYMM) | 999912 | Maximum month |
| OCC series date (MMY) | 99991231 | 8-digit series date |
| OCC and text layers (MatDt) | 9999-12-31 | ISO maximum |
| Onyx two-byte binary dates | 65535 = June 6, 2149 | Never 0, which decodes to 1970-01-01 and "reads as expired" |
| Daily reports | "PERP" | Human-readable |

The clearing identity line is **FUT / FFSCSX / 99991231 / 9999-12-31 / XMFE**. One caution matters for every firm's code: "there is NO FIX SecurityType for a security futures product". In FIX 5.0 SP2, "SFP" means Structured Finance Product, so the perpetual clears as FUT. The order and execution interfaces (FOI, FEI, FXD) get no logic change, and "No firm re-certifies."

### A second production instance

Onyx runs one recycle (5:05–5:40 p.m.) and one Live Order Window (5:45 p.m.) for all Financials products. Both fall inside the perpetual's session. The perpetual therefore runs on **its own second Onyx instance**, which recycles in the tape's 8–9 p.m. break. The rejected alternative was to let the perpetual go dark in the early evening while the stock trades.

The session follows the SIP's 23×5 production from **December 6, 2026**, in four Market States: Pre-Opening (in the break), Extended 1 (9:00 p.m.–9:30 a.m.), Regular (9:30 a.m.–4:00 p.m.) and Extended 2 (4:00–8:00 p.m.). "The perpetual trades only when the Reference Security's primary market trades." On the Nov 27 and Dec 24, 2026 half-days it closes at the tape's 1:00 p.m. Firms add one feed channel and session set. If the SIP moves its hours, the change is "one setting … one filing … one announcement … the arithmetic does not change."

### Build order

Annex A fixes ten steps. Pin the release, then build the instrument record ("everything keys off it"), engine configuration, samplers and the lock pipeline, "freeze → ÷24 → stamp → status → always-a-row". Message 18, the funding file and the OCC nightly file follow in parallel, then the second instance, then Firm Test Bed and UAT. Only two items are true engine builds: a sampler-restart checkpoint and the second instance. MIAX types six values itself, each with a default.

The change set ships as the next release after v1.3a. MIAX's Technical Alert of September 28, 2026 sets Financials production for Sunday, November 8, 2026. The room's wording can be read as dating either v1.3a or the release after it. Annex E then sweeps every MIAX Futures web page. It finds 21 surfaces that change and says explicitly that every other page does not, "so this sweep is auditable".

> [!number] 65535 — "never expires" in two bytes
> June 6, 2149, the maximum two-byte day count. Zero would decode to 1970 and read as expired.

*Sources: Annex A Onyx Change Set (Jul 7, 2026; rev. Sep 30, 2026); Sentinel & Symbology Card v1.0 (Jul 7, 2026; rev. Sep 30, 2026); Annex E Site & Publications Change Catalog v1.2 (Jul 8, 2026; rev. Sep 30, 2026); Runbooks v1.9, X1–X9 (Sep 17, 2026; rev. Sep 30, 2026)*

## The failures designed out {#ap-controls}

The controls assume that no one will notice a problem in time. Each failure therefore has a check that runs on its own, a recovery that runs on its own, and a log that a person reviews.

> [!quote] "Nothing in this chapter depends on a person noticing something in time. Each failure below has a check that runs on its own, and a recovery that runs on its own; the desk reviews the log." — Runbooks v1.9, O6, Sep 17, 2026

The operations desk's list (Runbook O6) names nine failures:

| Failure | Automatic check | Automatic recovery |
|---|---|---|
| Corporate action missed | Two independent sources, matched daily against every name | Either source opens a record and pages the desk; nothing publishes until sources agree |
| Wrong number reaches OCC or a notice | Numbers come from declared or market sources, "never typed"; "the Alert is generated from the record, not written" | Hold and page with both values |
| Ex-date value missing next day | Definitions run checks every open event | Run stops, pages, reloads |
| Nightly file late or short a row | Platform builds and sends it at the closing lock; row count checked against the cycle | Auto-resend; page after the second failure |
| Zero-sum check fails | OCC checks per name, per cycle | That name waits; every other name settles |
| Onyx restarts mid-hour | Checkpointed running average | Resume; "the rate is never defaulted to 0 while valid samples exist" |
| OCC unavailable | Funding locks at the Exchange regardless | Rows kept; resend later |
| Member default | Funding is variation | Ranks as unsettled variation at OCC |
| Event with no notice | Contract already paused | Lane D waterfall "needs no judgment" |

The platform's list (X9) adds four checks:

- a lock always writes a row, and the row can never be changed;
- SIP sequence numbers and heartbeats;
- duplicate guarding on trade reports;
- an empty-book check after every order purge.

The OCC list (C6) covers OCC downtime ("nothing is recomputed"), wrong positions, a failed zero-sum and OCC layout changes.

Finality is itself a control. "A funding lock is never corrected: it is final when published" (Rule 43.10(f)). A completed settlement is never reopened. An error in a DSP is reversed by the next cycle's mark. Error-trade review uses a ±5% no-bust range around the Mark, and it "never reopens a locked Funding Rate or a computed Daily Settlement Price."

*Sources: Runbooks v1.9, O6, X9, C6, O4 (Sep 17, 2026; rev. Sep 30, 2026); Annex E /market-regulation-policies (Jul 8, 2026; rev. Sep 30, 2026)*

## Autonomous by design: what runs itself, what a person signs {#ap-autonomous}

The runbooks break operations into jobs. Each job takes a record in, puts a record out and checks one against the other. Every number in the product is a declared amount or a market price, so no step needs judgment except the ones the law reserves to a person.

> [!quote] "Every step in Part 3 is a job with an input, an output and a check: the input a record, the output a record, the check a comparison of the output to its source before anything leaves the building." — Runbooks v1.9, Part 5, Sep 17, 2026

**These run on their own:** listing tests and limit lines; Schedule entries and day-before filings from templates; instrument records; locks, settlement prices and every file; corporate-action intake through to the Alert; surveillance thresholds; billing and the royalty statement; and the calendar, generated from T.

**A person always signs these fifteen acts:**

1. a filing with the CFTC or the SEC;
2. adoption of a Schedule entry and its limit line;
3. a report, a facts submission or an instruction to OCC;
4. an Alert or circular;
5. the last day, the successor and any closing-only period;
6. a fee or product-setting change;
7. a payment;
8. an exemption;
9. an accountability order;
10. an error-trade decision;
11. a disciplinary decision;
12. a market-maker designation;
13. a firm's readiness sign-off;
14. the go call and a manual halt;
15. a Board approval.

The corporate-actions runbook adds one more signature inside the flow. For each dividend, "A person signs the row before it enters the file."

### Three records and an agent

The program keeps three records, however they are stored:

- the **name register**, one row per name for its life;
- the **event record**, one row per corporate action;
- the **decision register**, which holds every open parameter, set once with a default.

The decision register's rule is "Set it once, write it into the runbook it belongs to, and stop asking." Completion has the same test everywhere: "A step is done when its record exists." The room ships an `_AI_READABLE` folder of machine-readable copies so that an agent can do the work.

> [!quote] "An AI agent loaded with the machine-readable folder runs Part 3 as written — it prepares each step's record and stops where the step names a person" — Runbooks v1.9, Part 5, Sep 17, 2026

The tooling stays open: "which agent, sheet, queue or dashboard is the Exchange's choice and its experts' craft."

AP has no role in operations. The glossary entry for AP ends: "It runs no step here." Until first listing, and never beyond the 18-month longstop, the founder gives walkthroughs and written clarifications only, "not engineering, development, testing, operation, filing".

> [!number] 15 — acts a person always signs
> Everything else is a job with a record in, a record out and a check, which an AI agent can run as written.

*Sources: Runbooks v1.9, Parts 4–5 and Appendix B (Sep 17, 2026; rev. Sep 30, 2026); How to Win, Part 06 (Sept 2026); The Deal (Sep 30, 2026)*

## Liquidity: a workstream, not a hope {#ap-liquidity}

How to Win gives liquidity an owner, a cohort, an incentive and a test.

> [!quote] "Liquidity is a workstream with an owner, a cohort, an incentive and a test — not a hope." — How to Win, Sept 2026

The plan has four parts:

- **Owner.** The Exchange's market-maker desk, under Rule 2.1.9.
- **Cohort.** MIAX's own member market makers first, then the offshore perpetual trading firms. To join, a firm needs one feed channel, a conformance run and a designation at listing.
- **Test.** These are the recommended terms; MIAX sets the final ones. They follow the B500 program certified June 16, 2026:
  - designation per name;
  - in the stock's regular hours, two-sided at least 90% of the time, at least 5 contracts a side, within the greater of $0.20 or 1.5× the stock's spread;
  - in the rest of the session, 50% of the time, 1 contract;
  - measured monthly, halts excluded;
  - two months short in a name loses the designation there;
  - designations carry automatically to successor listings.
- **Incentive.** A market-maker fee of $0.40 per side, about 27% of the regular fee, with no rebates. Width, size and time are published (the Rule 3.3.2(e) holding-out standard). Incentives may stay confidential.

Four flows are expected to arrive without being paid for:

- retail, through a Robinhood securities account holding the perpetual beside stock and options;
- the carry desk: long stock, short perpetual, earning funding ("the hourly funding print is a borrow market");
- the options desk, using a delta-one hedge that never rolls;
- portfolio-margin offsets.

There is **no liquidation engine**: no auction, no automatic deleveraging, no insurance fund. A losing account meets its carrying firm's margin call. A failing carrying firm meets OCC's waterfall. "the offshore venues' risk engine is not in the path."

*Sources: How to Win, Part 03A (Sept 2026); Runbooks v1.9, S3 (Sep 17, 2026; rev. Sep 30, 2026); MIAX Brief End-to-End, §08A (Sept 2026)*

## Ten chains, sixty-six links {#ap-chains}

The launch plan runs as ten parallel chains. The 66 links are numbered across all chains in the order they happen. The documents call it "the order, not a calendar". Every document is already drafted, so "No phase waits for drafting".

Three gates hold the order:

- **Link 12.** Nothing goes to the Commissions until OCC agrees that funding is variation.
- **Link 31.** Nothing is made public until the listing request files.
- **Links 41 and 50.** Nothing lists until the CFTC order and a go check where every line reads yes.

| Chain | Starts | Links | Finish line |
|---|---|---|---|
| 1 · The Deal | Now | 1 → 2 → 3 → 57 | First listing recorded; royalty starts |
| 2 · Clearing (OCC) | Day 1 | 5 → 12 → 13 → 14 → 15 → 21 → 30 → 32 → 36 → 48 | OCC rules in effect; series in Ovation |
| 3 · Platform (Onyx) | Day 1 | 6 → 16 → 23 → 24 → 47 | Release live with 23-hour session |
| 4 · Market data & Index | Day 1 | 11 → 22 → 37 | Vendors told |
| 5 · Market makers | Day 1 | 7 → 19 → 20 → 38 → 44 → 59 → 60 | Quoting measured |
| 6 · Firms | Day 1 | 8 → 17 → 18 → 35 → 49 → 58 | Customer sales open |
| 7 · Regulatory set | Day 1 | 9 → 10 → 27 → 28 → 29 → 31 → 39 → 40 → 41 → 42 → 45 | Market Regulation items |
| 8 · Public face | Test bed | 26 → 33 → 46 | Site walked |
| 9 · Messaging | Day 1, quiet | 4 → 25 → 34 → 43 → 55 | Launch announced |
| 10 · The Go | All lines yes | 50 → 51 → 52 → 53 → 54 → 56 | T+1 payment ties out |
| After launch | T | 61 → 62 → 63 → 64 → 65 → 66 | "Finished when never" |

The links that carry the most weight:

- **2 · Signing (Day 1).** Four papers in one sitting; the signing payment wires and the OCC conversation opens.
- **27–28 · Letter and meeting.** The recognition letter goes to both Chairmen, followed by a joint staff meeting. The risk-disclosure brief goes to FINRA and NFA at that meeting.
- **29 · Tests and approvals.** The six listing tests are re-run for all 101 names. The Regulatory Oversight Committee approves No. 101 (MIAX), and the Board approves.
- **31 · Filed together.** The §41.23(b) request, Form 19b-7 and Form 19b-4 go in on the same day. The quiet period ends.
- **41 · The order.** The CFTC order and Form 19b-7 take effect. Form 19b-4 does not gate day one.
- **50 · The go check.** Every line must read yes, from the order and OCC's rules to a money chain proved end to end.
- **52–54 · Listing day.** The 101 list as one batch. A one-page ISG notice goes out at T−1. Names 1–101 trade at T.
- **56 · T+1.** The first cycle ties out at every firm. Customer postings plus rounding must equal the DDS Funding Adjustment line, sign reversed.
- **57 · First listing recorded.** The royalty starts. If this falls within 18 months of signing, the exclusivity longstop is met.

The after-launch coda is the running business: a new name (61), the twice-yearly limit review (62), corporate actions (63), the trading day (64), the quarterly royalty (65) and a new perpetual class on the same rails at the same rate (66). It closes with "Finished when never — this is the business."

Messaging rules: the Exchange controls the brand; the product is "new", never "first" or "only"; funding is never annualized in a headline.

> [!number] 66 links — ten chains, three hard gates
> Link 12 (OCC agrees), link 31 (filings go in together), links 41 and 50 (the order and the go check).

*Sources: How to Win, Part 04 (Sept 2026); MIAX Brief End-to-End, §10 (Sept 2026); Runbooks v1.9, Part 2 and R2 (Sep 17, 2026; rev. Sep 30, 2026)*

## Why the design rejects crypto-perp features {#ap-vs-crypto}

The perpetual is the structure that won crypto. It carries more than 90% of global crypto-futures volume, over $200 billion a day in 2025, almost all of it offshore. AP keeps the structure. It drops every crypto feature that exists only because those venues have no clearinghouse.

> [!quote] "The structure that won crypto, brought to regulated equity." — OCC Clearing Brief, Sept 2026

The specification lists three things the design "deliberately doesn't carry":

1. **No funding cap and no interest-rate term.** In the specification's words: "Crypto funding is a premium plus an interest component, clamped; ours is the pure premium passthrough, uncapped." The basis of a cash-settled equity future already includes carry, and containment happens upstream, through the collar, the median Mark, the hourly average and surveillance. Rule 43.10(f): "The Funding Rate is an uncapped pass-through; containment is upstream."
2. **No insurance fund and no auto-deleveraging (ADL).** "Crypto venues need both because they have no clearinghouse." This product has OCC: gross customer margin, a guaranty fund and a default waterfall (OCC Rule 1006; Part 39). "No venue insurance fund exists and none is needed."
3. **Tape-following, not 24/7.** The Index is the SIP feed, so funding runs only while the consolidated tape runs: "funding never runs on a synthetic index."

> [!quote] "Losses are mutualized by a CCP — never socialized by haircutting winners." — Unified Technical Specification v1.0, Jul 7, 2026 (rev. Sep 30, 2026)

On three points the design matches or beats the crypto pattern:

- funding every hour, against crypto's typical eight-hour interval;
- settled rows plus a predicted stream, in "Bitnomial's exact surface shape";
- a published Mark and Index, with a free public history of the same values the clearinghouse settles.

One crypto practice survives, moved down to the broker. A carrying firm's duties include "auto-liquidation against OCC-published margin parameters". The venue has no liquidation engine, but a firm still closes out an account that misses a call.

> [!tension] Uncapped funding is a deliberate break from crypto; the risk is spiky rates in thin names, answered only by the market-maker program, collar, median and TWAP.

*Sources: Unified Technical Specification v1.0, Vol. I and Vol. II §5.4 (Jul 7, 2026; rev. Sep 30, 2026); OCC Clearing Brief (Sept 2026); Rulebook Insertion & Amendment Package v2.8, Rule 43.10(f) (Sep 30, 2026)*

## The field, briefly {#ap-field}

By late September 2026, four rivals had built or filed single-stock contracts, and Nadex had filed perpetuals on ten names. AP argues that the category is won on "listings, liquidity and limits", and that only an OCC-cleared venue can pull all three levers. "Fees are a schedule the Exchange sets and can change on a filing; a matching engine is a purchase. Neither is a moat."

| Axis | American Perpetual | CME dated SSF | KalshiEX | Coinbase Derivatives | Bitnomial |
|---|---|---|---|---|---|
| Structure | No expiry; hourly funding | Quarterly expiries; rolls | No fixed maturity; daily funding | No fixed expiry; hourly funding | No expiry; funding 3×/day |
| Names | Any eligible; 101 at launch | 50+ mega-caps | 58 | AAPL as model | 10 |
| Dividends | Ex-date factor on variation | In the basis | Via funding | No adjustment | Cash adjustment |
| Margin | 15% (20% FINRA securities) | 15% SPAN floor | 15.50% | ≥15% | 15.25% |
| Limits | 25,000 or accountability | 200,000 | 50,000; 200,000 cap | 200,000 | 200,000 |
| Clearing | OCC, >100 members | CME Clearing | Kalshi Klear | Nodal Clear | Bitnomial Clearinghouse |

Fees per side: AP $1.50 ($0.40 for market makers); CME $0.60 plus quarterly rolls; Kalshi's perpetual schedule a 12.0 bps taker rate at the first tier, which is $30 on a $25,000 contract.

AP's moat is clearing. "The moat is the clearing, because clearing is where the capital is." Firms carry the perpetual in their existing FCM accounts and portfolio-margin it beside the stock and its options. "Every product a silo adds deepens the silo; every product this venue adds deepens the network." Chapter V covers each rival's legal footing.

*Sources: How to Win, Parts 01–03 (Sept 2026); MIAX Brief End-to-End, §03 (Sept 2026)*

## Design principles reusable for crypto classes {#ap-principles}

Once the machine runs, it does not care what the underlying is. OCC carries hourly funding inside variation, and firms have wired the four booking rules. From then on, any underlying with a reliable reference runs unchanged. A new class needs only a new reference feed and a contract multiplier. "The member-side build is one-time and the same for every future perpetual product (a new class needs at most one more product-list entry)."

The expansion order:

1. **U.S. equities, deeper:** more names, ADRs, wrapper ETFs, an IPO gate.
2. **Crypto majors, BTC · ETH · SOL · XRP**, about 91% of listable spot flow. This needs a registered per-second index licence; the first name files for §40.3 approval and the rest self-certify under §40.2.
3. **FX majors, plus gold and silver** as currency pairs.
4. **Foreign indices**, Nikkei 225 first, when licensed. "never the first".

Rates, marquee U.S. indices, copper, compute, pre-IPO names, credit and direct volatility stay out.

The legal route for crypto is simpler than for equities: "a class that is not a security future is CFTC-only, with no SEC filing and no security-futures customer rules." There are precedents:

- OCC cleared Cboe Futures Exchange bitcoin futures from December 2017 to 2019.
- The CFTC approved Kalshi's bitcoin perpetual, on CF Benchmarks' BRTI, on May 29, 2026.
- Kalshi's gold and silver perpetuals went live September 10, 2026.

Each later class is the Exchange's own build. It falls under the same agreement at the same rate (Deal ¶3(d)), and AP delivers nothing further. Chapter VIII sets out the class program in full.

### Thirteen principles that carry over

1. **Define the class once.** Vary per name only identifiers and risk bounds, so listing becomes a schedule row.
2. **Extend existing structures only.** A free message slot, a new enum value, a new CSV. No firm re-certifies.
3. **Say "never expires" on each surface** with the field's maximum value, never zero.
4. **Use one Product per name**, so controls scoped to a product hit one name.
5. **Funding is variation** inside the clearinghouse's daily settlement. It is never a fee and never the venue's money.
6. **A lock is final, there is always a row, and each name's cycle sums to zero** before money moves.
7. **Publish the funding history free**, "fetched, not sent", so anyone can recompute it.
8. **Adjust only where the arithmetic is exact; otherwise terminate and relist.**
9. **Every number is a declared amount or a market price.** That lets operations be automated, with people signing only what the law reserves.
10. **Design failures out** with automatic checks and logs, not vigilance.
11. **Build to the cycle, never to a constant.**
12. **Bring vendors in first.** "one vendor build of the message parser and the booking module reaches every firm on the platform".
13. **The oracle is the consolidated reference**, with validity gates and an automatic pause on feed loss: "Exclusion, not estimation, is the reliability guarantee." For crypto this means a registered per-second index, a two-sided-and-not-crossed validity rule, and a pause instead of a synthetic price.

> [!number] ~91% — share of listable crypto spot flow in BTC · ETH · SOL · XRP
> The second class in the expansion order, on the same OCC rails and the same agreement.

*Sources: How to Win, Part 04A (Sept 2026); Runbooks v1.9, F5, S1, S2 (Sep 17, 2026; rev. Sep 30, 2026); Annex A Onyx Change Set (Jul 7, 2026; rev. Sep 30, 2026); Harmonization Submission (draft, Sept 2026)*

## Open risks in the machine {#ap-risks}

The design itself is finished. What remains open are confirmations and clocks held by other parties, and the room names each of them.

- **Sentinel acceptance.** If any OCC surface rejects 9999-12-31 / 99991231, the instrument has no identity there. Ovation "has no perpetual or no-expiry concept".
- **Full-session clearing.** If OCC will not clear the full 23×5 session, the trading hours change before filing.
- **Clocks.** Ovation go-live is projected for 1H 2027. The SIP's 23×5 production starts December 6, 2026. No document says what happens if listing comes before that date.
- **The standing rule.** Reading 17 CFR 41.25(c)(3) as authority for a standing class rule is called "the efficient reading" of text "drafted as a case determination". OCC counsel may resist it.
- **IDs on splits.** Ovation may create a "new derivative" for every corporate action. That would break the ID continuity lanes A and B depend on.
- **Lock timing.** A position held at a lock pays the whole hour, and one opened and closed between locks pays nothing. That behaviour is not on the surveillance list.
- **Tax on funding.** The character, timing and Form 1099-B treatment of the hourly Funding Adjustment are left to each firm's tax team.
- **Street cost.** The second instance means one more feed channel and session set at every firm.

> [!tension] The design is called "finished", yet two OCC confirmations could still change filed terms, and neither can be asked until after signing.

*Sources: Runbooks v1.9, C1 (Sep 17, 2026; rev. Sep 30, 2026); OCC Clearing Brief (Sept 2026); Corporate Actions Operations Playbook v1.2, App. D (Sep 16, 2026; rev. Sep 30, 2026); Risk Disclosure Supplement Brief (Sept 2026)*

<!-- END CHAPTER -->
