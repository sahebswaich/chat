# VIII. One rail, every asset — crypto, FX, metals, world indices

The equity perpetual is the build. The asset classes after it are the return on that build. Once OCC carries hourly funding inside ordinary variation and every carrying firm has wired the four booking rules, "a new class is a new reference feed and a contract multiplier." Nothing else about the machine changes.

This chapter sets out that program. It follows the Class Expansion memo that American Perpetual sent to MIAX Products Leadership on September 14, 2026 (conformed September 28; it supersedes an August 19 edition). It covers:

- the five tests a class must pass;
- the three classes that pass, with their references, licenses, steps, pools and ceilings;
- the categories parked or refused, and why;
- the license term that already covers every later class.

The chapter closes with a clearly labeled synthesis: what the program means for Saheb's crypto vision.

Status: these are recommendations to the Exchange. Nothing has been decided, licensed or filed. Equities come first.

> [!quote] "Products change; infrastructure compounds." — CME Launch memo, July 27, 2026

## The rail, built once {#classes-rail}

The program's claim is simple. The expensive work is the street build, and it is the same for every asset class. Each later class adds one reference feed, one multiplier and a filing.

The machine is the one Chapter VII described. Every 5 seconds the Exchange samples the gap between the Mark and the Index. At :00 it freezes the average, divides by 24 and locks it. The locked row (lock time, rate, Mark, Index and status) goes to three places: feed message 18, the nine-column funding file, and OCC's once-daily intake. Firms book it under four rules and tie out to one OCC line.

**What a new class changes:**

- **The Exchange builds** one ingest adapter, one underlying-type code, instrument rows on the perpetual's own Onyx instance, and a collar value. There is no new message, file or engine, except for the foreign-index "switch" described below.
- **OCC adds** a scan class with its parameters, an underlying-type code, and a class Schedule C under the clearing agreement.
- **A carrying firm takes six steps:**
  1. Turn the class on in the Member Firm Portal.
  2. Run conformance on the new identifiers.
  3. Margin the class from OCC's parameters, with house margin above ("the Exchange sets no leverage").
  4. Carry it in a futures account, because non-equity classes are not security futures.
  5. Give the CFTC Rule 1.55 risk disclosure (plus NFA's virtual-currency disclosures for digital assets).
  6. Note that the tax treatment is §1256, taxed 60/40 as long-term/short-term.

The Runbooks put the legal shift in one line: "a class that is not a security future is CFTC-only, with no SEC filing and no security-futures customer rules." The member build adds nothing: "a new class needs at most one more product-list entry."

**One rate, four underlyings.** The memo works the same funding rate (+0.000042) on 10 contracts in each class:

| Class | Reference | Unit | Price | Funding for the hour |
|---|---|---|---|---|
| U.S. equity | NBBO midpoint | 100 shares | $250.00 | $10.50 |
| Bitcoin | Administrator's per-second index | 0.1 BTC | $100,000 | $4.20 |
| EUR/USD | Licensed composite | €10,000 | 1.1500 | $4.83 |
| Nikkei 225 | Official index (home-futures ratio off-hours) | $0.25 a point | 40,000 | $4.20 |

Reading across the platform documents (Annex A, the Symbology Card, the Playbooks and the Runbooks) gives about a dozen reusable principles. No single document lists them; this is the research's reading. Five matter most for later classes:

1. Define the class once, and vary only identifiers and risk bounds per name.
2. Extend existing platform structures only, so nothing re-certifies.
3. Funding is variation inside the clearinghouse's daily settlement, never a fee.
4. A lock is final, there is always a row, and each name nets to zero each cycle.
5. The reference carries validity gates and pauses itself when its feed is lost.

The fifth is the one a crypto index needs most. The memo builds it in: each sample is valid only if the republished value is current within stated seconds and the provider's status is normal.

> [!quote] "a new class is a new reference feed and a contract multiplier." — Class Expansion memo, Sept 14, 2026

*Sources: Class Expansion memo (Sept 14, conformed Sept 28, 2026) §3; Runbooks v1.9 F5, S2 (Sept 2026); How to Win Part 04A (Sept 2026)*

## Two invariants, five tests {#classes-tests}

Before a category becomes a class, it must pass five tests. The tests come from two invariants.

"A perpetual has no expiry to settle to: the funding tether is the product's entire identity." So:

1. The reference must be **exogenous**: "formed outside the product's own book, so the contract can never define itself."
2. The reference must be **arbitrageable**: "someone can hold or trade the underlying against the perpetual, so deviations are corrected by profit-seekers, not by trust."

The corollary is "no fictional prices". Funding accrues only while a disciplined reference is live. In a pause nothing accrues, margin marks to the last real price, and "a 3 a.m. liquidation cascade has nothing to grab." Because no price is ever fictional, the clearing needs no insurance fund and no auto-deleveraging. OCC's own default waterfall stands behind every contract. DCM Core Principle 3 and the CFTC's 2026 policy statement, which requires a reference reliable at every funding interval, "are these invariants written as law: the unanchored version cannot file."

**The five tests**, verbatim:

1. "An independent, continuous reference — executed or firm-quoted cash, alive at every funding interval, never derived from a derivative book." While a cash market is closed, its last print is carried by the ratio of two real futures prices and re-anchored at the next cash open.
2. "Financial carry only — funding prices financing; it cannot price warehouses, storage, or physical logistics."
3. "Discrete events resolvable by published rule."
4. "A clean regulatory seat — the security-futures frame for equities, or CFTC-only for excluded and exempt commodities; no bespoke relief."
5. "A licensable-or-buildable reference, with real distribution demand."

**The sorting rule.** A category that passes all five is a class. One that fails a test but has a named engineering fix is parked, with the fix stated. One that "fails on physics is refused — with the receipt."

| Verdict | Categories |
|---|---|
| Passes today | U.S. equities, ETFs and ADRs (the consolidated tape) · crypto majors (per-second order-book composites) · FX majors with gold and silver as currency pairs (24/5 electronic spot) |
| Passes behind a license | Foreign indices by the ratio method: Nikkei 225 · KOSPI 200 · Hang Seng TECH (Taiwan the first alternate). "Never the first class to launch" |
| Fails or parked | Copper and blended-roll commodities · compute and power · direct volatility · pre-IPO names · rates (pass, but parked) · anything unanchored |

> [!quote] "This one can be carried by an FCM to a pension, because every mark in its history traces to a real market." — Class Expansion memo, Sept 14, 2026

*Sources: Class Expansion memo §1 (Sept 14, 2026); CFTC policy statement as cited in Robinhood Brief (Sept 2026)*

## Class 1, briefly: equity depth comes first {#classes-equity-depth}

The launch class is also the first expansion. The 101 names file on one request. Later names certify forward, one Schedule entry each.

**The shelf strategy follows a "concentration doctrine":** one ticker per exposure, the deepest one.

- **Index:** SPY · QQQ · IWM · DIA
- **Metals:** GLD · SLV
- **Oil:** USO
- **Rates and credit:** TLT · IEF · LQD · HYG
- **Foreign:** EWJ · EFA · EEM · FXI
- **Volatility:** one volatility ETP
- **ADRs:** the mega-ADRs
- **New listings:** an IPO gate for newly public mega-caps

"Incremental cost: none. The machine exists."

The equity pool runs at about 0.63 bps of traded notional at launch fees and about 1.0 bps tiered. At $10T a year that is about $631M rising to $1.03B; at $40T a year, about $2.5B rising to $4.1B.

**Crypto arrives early through the equity class.** Six crypto-linked names sit in the 101:

- IBIT, the iShares Bitcoin Trust (No. 53)
- MSTR (No. 31)
- HOOD (No. 32)
- IREN (No. 66)
- COIN (No. 68)
- CRCL, Circle (No. 97)

The memo also counts an "ETF-wrapper lane" for crypto inside equities of $3–8T a year.

*Sources: Class Expansion memo §2, §4, §7 (Sept 14, 2026); Room Update (Sept 28, 2026) p18; Listing & Position-Limit Playbook v1.4 (Sept 2026)*

## Class 2: crypto majors — BTC · ETH · SOL · XRP {#classes-crypto}

Crypto is second in line and marked "READY TO BUILD". The class is exchange-listed, OCC-cleared, hourly-funded perpetuals on the four coins that carry most listable spot flow. Three things close the build: a reference license, fee terms at listing-day prices, and the session call.

> [!number] 91% — share of listable crypto spot flow in BTC · ETH · SOL · XRP
> BTC and ETH alone are 85% (July 2026 venue data). More names certify forward.

### The reference: CF Benchmarks, per second

Each coin takes the CF Benchmarks per-second real-time index. For bitcoin that is the BRTI (Bitcoin Real Time Index). The same family covers ETH, SOL, XRP "and some thirty assets beyond them". The indices are registered under the UK Benchmarks Regulation. The CFTC has accepted the family since 2017 for listed bitcoin futures, and "the first CFTC-approved U.S. perpetual (May 2026) settles on it." So the filing "cites an accepted index rather than proving a new one."

The memo describes the method as follows. The administrator takes a curated panel of exchanges and caps each venue's size. It combines the books, removes crossed orders, and takes the mid-price of the depth used, weighting deeper levels less. The output is one value a second. A venue drops out when its book goes quiet or strays. "The panel is chosen, not open — the largest offshore venue has never been in it — and that choice is what makes the number trustworthy."

**License.** The estimate is $100–500k a year fixed, plus a sub-cent per contract (private terms, confirmed at signing). It covers real-time republication as the Index Price, a public historical endpoint, and feed transport.

**Phase two** is an Exchange-own index: $500k–1M in year one and $200–400k a year to run. "The mathematics is the small part." The hard part is panel agreements, IOSCO governance and acceptance. It swaps in through the administrator-substitution clause each class chapter carries.

> [!number] $100–500k/yr — estimated CF Benchmarks license for the crypto class
> Plus a sub-cent per contract. An Exchange-own index would cost $500k–1M in year one, then $200–400k a year.

### The contract

- **Units:** sized to about $5–15k notional, for "the active trader an FCM carries". BTC 0.1; ETH ≈5; SOL ≈100; XRP set at listing.
- **Tick:** the clean increment nearest one basis point, so every name ticks at exactly $1.00 a contract. Integer contracts only.
- **Fee rule:** the customer fee is "the highest quarter-dollar landing under 2.0 basis points per side of contract notional at listing-day prices". On a $10,000 contract (0.1 BTC at $100,000) that is $1.75 a side. The market-maker fee is about 27–30% of the customer fee.
- **Session:** "the stated preference is 24/7 from day one." If platform or clearing calendars cannot support it at launch, the class opens on the equity session (23 locks a cycle) and extends by configuration. "Each added hour is one more row in the same file, and the computation never changes."

### Eleven steps to first listing

| # | What happens | Who | Clock |
|---|---|---|---|
| 1 | Class decided. "Nothing signs": the license already covers it (The Deal ¶3(d)) | MIAX | At the decision |
| 2 | Data license: scope, transport, republication, historical endpoint | MIAX | First |
| 3 | Contract values and fee schedule set at listing-day prices | MIAX | At listing |
| 4 | Platform: ingest adapter, underlying-type code, rows, collar | Onyx | In parallel |
| 5 | Clearing: the digital-asset addendum (seven items) | OCC liaison | Before clearing starts |
| 6 | Bitcoin perpetual filed by §40.3 voluntary approval; Chapter 44 under §40.6 | Regulatory, counsel | 45 days, extendable once by 45 |
| 7 | ETH, SOL, XRP by §40.2 self-certification | Regulatory | Business day before each listing |
| 8 | Exchange-set limits and accountability; Part 17 reporting; conduct rules around the funding window | Market Regulation | With the chapter |
| 9 | The street: product election, conformance, margin class, futures account, Rule 1.55 and NFA disclosures, §1256 note | Carrying firms | Before listing |
| 10 | Public pages and funding tiles | Market Data | With the listing |
| 11 | Day one: the equity session, or 24/7 | — | The first day |

**§40.3 versus §40.2.** Under **§40.3**, the Exchange asks the CFTC to approve a product. The review runs 45 days and can be extended once by 45. Under **§40.2**, the Exchange certifies a product complies and lists it the next business day. The plan puts the full showing on bitcoin alone: the Part 40 Appendix D cover sheet, the terms and conditions, the Core Principles analysis, and confidential treatment under §40.8. "The Commission's May 2026 order accepted this exact index and this mechanism; the record is complete on day one." The other three names then self-certify behind it. No federal position-limit layer applies, because crypto is not an enumerated commodity.

**OCC's digital-asset addendum** covers seven items, each in OCC's own form and judgment:

1. Scan-class setup and parameter publication.
2. The underlying-type code.
3. Confirmation that the class rides the existing intake unchanged.
4. The risk-parameter file code and revision convention.
5. The session question.
6. Portfolio treatment.
7. The class's Schedule C.

The precedent is OCC's clearing of CFE's cash-settled bitcoin futures from December 2017 until their delisting in 2019.

### Pools and ceiling

| Contracts a day | Day notional | Exchange-fee pool a year |
|---|---|---|
| 25,000 | ≈$180M | ≈$9.3M |
| 75,000 | ≈$550M | ≈$28M |
| 200,000 | ≈$1.5B | ≈$75M |

> [!number] $9.3M / $28M / $75M — crypto-class fee pool a year
> At 25k / 75k / 200k contracts a day, under the sub-2-bps fee rule.

The ceiling is far larger. Global crypto-perp volume was $92.9T in FY25: about $86T on centralized venues and about $7T decentralized. The U.S. regulated lane is about $0.5–1T a year. The memo's addressable range is $20–40T a year, which gives a pool of about $2–8B a year. Its demand receipt is October 10, 2025, a $19.1B forced-liquidation day. Elsewhere in the room, the first crypto-perp approval is cited as taking 9% off Cboe in a session and about 4% off CME and ICE (June 2, 2026).

> [!tension] "The categorization the May 2026 order rests on is under challenge in the commodity-perpetual litigation." The build can start at the decision. The filing date is "a judgment against that litigation's trajectory."

*Sources: Class Expansion memo pp3, 5–8, 11 (Sept 14, 2026); How to Win p18 (Sept 2026); The Deal p2 (Sept 30, 2026)*

## Class 3: FX majors, with gold and silver {#classes-fx-metals}

FX is "ONE DATA LICENSE FROM LAUNCH". It is the largest market on earth, and the only non-equity category whose reference is executed cash, continuously, 24/5. In FX the funding rate means more than a premium. It is "the interest-rate difference between the two currencies — what the forward market charges", here "priced by the market and published hourly on an exchange."

**The instruments.** There are nine, all at a $1.00 tick:

| Instrument | Unit |
|---|---|
| EUR/USD | €10,000 |
| USD/JPY | ¥1,000,000 |
| GBP/USD | £10,000 |
| AUD/USD | A$10,000 |
| USD/CAD | C$10,000 |
| USD/CHF | CHF 10,000 |
| USD/MXN | MXN 200,000 |
| XAU/USD (gold) | 2 oz |
| XAG/USD (silver) | 200 oz |

On EUR/USD a $0.0001 tick is about 0.85 bp. The settlement window is 4 p.m. ET or 4 p.m. London.

**Gold and silver are co-leads and "may lead it."** They trade as FX pairs on the same 24/5 electronic complex. Storage is negligible and carry is financial, so they pass on FX's own feed: "Real metal exposure, no wrapper." In July 2026 the LBMA precious-metals benchmarks were consolidated under one administrator, which makes the whole precious complex a single counterparty. Offshore, gold is the largest real-world-asset perpetual, and with silver it is about 65% of that flow.

**The class subtracts complexity.** There are no corporate actions and no §871(m). Tax is §1256 60/40. Regulation is CFTC-only: the currency pairs are excluded commodities, and gold and silver are exempt commodities. "The offshore CFD industry is FX perpetuals in disguise", while U.S. retail FX "sits in a bilateral dealer regime with no exchange-listed, centrally cleared alternative."

**Reference and license.** The Exchange licenses a continuous composite of executable spot from a regulated benchmark administrator, live Sunday 5 p.m. to Friday 5 p.m. ET. The estimate is $100–500k a year for the class. Phase two is an Exchange-own composite built from two or three venue licenses: $300–800k to build and $200–500k a year to run.

**Nine steps:**

1. Decide.
2. Get the composite license, "the only thing that takes time."
3. Set values.
4. Build on Onyx.
5. Add OCC's currency addendum.
6. File by §40.2 per pair, EUR/USD first (or §40.3 if FX goes first), with Chapter 45 under §40.6.
7. Prepare the street: Rule 1.55 only, not retail forex.
8. Publish.
9. Day one. FX extends to 24/5 first.

Whether a gold or silver cash-index perp is a referenced contract under the CFTC's position-limit rules (Part 150) is a question for counsel.

**Precedents.** OCC cleared PHLX world-currency options for decades. Kalshi's Commission-approved gold and silver perpetuals went live on September 10, 2026, self-cleared and 24/7: "the case here is the same product on the street's rails."

**Pools.** About $11M, $34M and $91M a year at 25k, 75k and 200k contracts a day (day notional about $250M, $760M and $2.0B).

**FX ceiling.** OTC FX trades $9.5T a day (BIS, April 2025, up 27% on 2022), about $2.4Q a year. Listed FX futures are about $10T a year and the retail-broker tape about $40T. Taking 5–10% as directional gives $120–240T addressable and a pool of about $12–48B a year.

**Metals ceiling.** The commodity tape is $170–200T a year, which gives $55–100T addressable and about $5.5–20B a year.

> [!quote] "Gold trades as a currency; copper does not." — Class Expansion memo, Sept 14, 2026

*Sources: Class Expansion memo pp3, 5–7, 9, 11 (Sept 14, 2026)*

## Class 4: foreign indices by the ratio method {#classes-foreign-indices}

Foreign indices pass the tests but wait on a license, and they are "never the first class to launch." Meanwhile, the ETFs EWJ, EFA and FXI carry the exposure on the equity shelf.

**The ratio method.** An index has no spot market, so the reference anchors to real prints in three states:

- **In home cash hours:** the official index.
- **In home-futures hours:** the last official close × (home-futures mid now ÷ home-futures mid at that close).
- **Outside both:** a pause.

The reference re-anchors at every home open, so drift is at most one overnight session, about half a basis point. "The switch" (two feeds, a rule, one division, a state flag) is the only new engine piece in the whole program. Launch is price-return. A dividend-adjusted version can follow using Osaka's dividend-index futures.

**Targets, in order:** Nikkei 225, then KOSPI 200, then Hang Seng TECH, with TAIEX as first alternate. Each license costs $250k–1M+ a year from the index owner, plus a home-futures market-data license. The Nikkei is licensed to three futures venues today. The proposed Nikkei unit is $0.25 a point, and the session runs about 16½–21½ hours a day.

**The walls are named, not chased:**

- China is closed by national policy.
- Continental Europe's indices are owned by their venues: "no license exists to win."
- FTSE is exclusive at CME through 2037, including its China 50.
- FTSE China A50 sits under Singapore's exclusive license.
- S&P and Nasdaq are exclusive at CME.
- MSCI sits at ICE.

**Nine steps:**

1. Open license talks, Nikkei first. "If the license terms are heavy, do not build."
2. Write a settings sheet.
3. Decide.
4. Build the Onyx switch and state flag.
5. Add an OCC foreign-index rider (holiday calendar).
6. File Chapter 46 under §40.6, plus §40.2 or §40.3, as broad-based foreign index futures (CFTC only).
7. Prepare the street.
8. Publish a public page with a clock showing which reference is live.
9. List the second index from a settings sheet.

The arbitrage that holds the perp to the index is to sell the perp, buy home futures and hedge the currency.

**Economics.** Home-venue gross turnover is about $570–725T a year. The listable set is about $18–30T:

- Nikkei ≈$5–8T
- KOSPI 200 ≈$8–12T
- Hang Seng ≈$3–6T
- TAIEX ≈$2–4T

At about 38% directional, that is $7–11T addressable and about $0.7–2.2B a year. The pool is "sized when a license lands."

> [!quote] "Solve the Nikkei once; the rest are settings." — Class Expansion memo, Sept 14, 2026

*Sources: Class Expansion memo pp3, 6–7, 9–11 (Sept 14, 2026)*

## Parked and refused — with the receipts {#classes-refusals}

The refusal list is part of the product. "Credibility in what a venue lists is made by what it declines to list." Every verdict comes with its reason.

| Category | Verdict | Receipt |
|---|---|---|
| Rates (constant-maturity Treasury construction) | Parked | Passes every test, but demand is served: the incumbent's dated benchmark-point experiment drew modest traction; offshore bond perps run ≈$24M; TLT on the shelf takes the duration bid |
| Marquee U.S. indices (SPX, NDX) | Out | Licensing is exclusive at CME; SPY and QQQ carry the exposure; a MIAX-own benchmark is "a someday, not a fight to open now" |
| Copper and blended-roll commodities | Parked | Every reference is another exchange's futures curve (roll cost baked in, "the USO lesson"); the data can be revoked; physical carry fails test 2 |
| Compute and power | Refused | "A perpetual needs a heartbeat; compute prints one number a day, on hardware that expires" |
| Direct volatility | Refused | "A statistic, not an asset"; wrapped through a vol ETP |
| Pre-IPO names | Refused | A security future needs a §12-registered listed underlying. The IPO gate is the constructive half: "even the 'SpaceX futures' everyone cites arrived only after its June IPO" |
| Credit, event, real estate | Wrapped or refused | LQD and HYG on the shelf; the rest "refused for cause" |

Copper is "the strongest candidate the discipline still refuses." Broker-layer copper perps ship today, so the demand is real. "Should a true continuous executable cash reference emerge, the five tests reopen the door." The August 19 edition moved copper into the refusals and recorded the FTSE lock through 2037.

The list also narrows Saheb's own earlier range. GLX's V2 roadmap proposed a "novel classification under CEA §4(c)" for "indices, commodities, FX, rates" and "a perpetuals-of-everything platform inside five years." A February 2026 deck spoke of "2,000 Products". The five tests replace breadth with a rule.

*Sources: Class Expansion memo §8–9, p13 (Sept 14, 2026); GLX Tech Spec §27 and Op Doc (Mar–May 2026); Greyline Old Investor Deck (Feb 2026)*

## The ceiling {#classes-ceiling}

The ceiling arithmetic is one ladder. The pool is about 1–2 bps of addressed volume, so each $10T a year addressed is worth about $1–2B a year in pool. The memo calls every ceiling "illustrative, and the far edge."

| Class | Addressable flow ($T/yr) | Pool ($B/yr) | Basis |
|---|---|---|---|
| U.S. equities, ETFs, ADRs | 425–500 | 26–50 | Cash $277T; index derivatives ≈$1.2Q; single-name options ≈$230T; 0DTE ≈$290T |
| Crypto majors | 20–40 | 2–8 | Global crypto perps $92.9T (FY25); U.S. regulated lane $0.5–1T |
| FX | 120–240 | 12–48 | OTC $9.5T a day ≈ $2.4Q a year; 5–10% directional |
| Metals | 55–100 | 5.5–20 | Commodity tape $170–200T; 30–50% directional |
| Foreign indices | 7–11 | 0.7–2.2 | Listable set $18–30T × ≈38% |
| **Program** | **≈625–890** | **≈45–130** | Expansion alone $200–390T |

> [!number] ≈$625–890T/yr — addressable flow across all classes
> At 1–2 bps, a pool of about $45–130B a year. With market makers' volume counted at 2.0–2.5×, the cleared-volume ceiling is about $1.3–2.2Q a year.

The near-term pools are small next to that. Crypto's $9.3–75M and FX-and-metals' $11–91M a year, on the same contracts-a-day ladder, are the numbers a launch decision runs on. Saheb's GLX-era documents had stated larger round figures: a fee pool of "~$150B/yr" (Competitive Memo) or "~$125B" (Connamara memo), and "V1 cleared notional ~$1 quadrillion across ten SFP categories." The class memo's $45–130B is the disciplined version, built class by class.

*Sources: Class Expansion memo §7, p11 (Sept 14, 2026); GLX Competitive Memo v54 (Apr 2026); GLX Connamara memo (May 2026)*

## The royalty already covers it {#classes-royalty}

Every later class is licensed already. No new agreement is needed, and AP owes no new deliverable. The memo says it plainly: "one license over every perpetual product, at one rate; a later class is the Exchange's own build on the licensed core, covered from its first listing — nothing further signs or is owed (¶3(d))."

The Runbooks repeat it for MIAX's finance team: "every perpetual product the Exchange or an affiliate lists during the term — any underlying — is licensed under the one agreement and bears the same royalty … from its first listing, with nothing to countersign." And: "AP's later work is not delivered and not owed; the Exchange builds each later product itself on the licensed core. No date to watch: the one exclusivity covers it."

**What the final Deal says (text dated September 30, 2026):**

- **Royalty:** 60% of Covered Fees, flat, quarterly, never reduced.
- **Covered Fees:** transaction fees actually collected on every perpetual product, net only of the SEC §31 assessment. No costs are deducted; market-data, data-license and index-source fees never reduce Covered Fees. So a CF Benchmarks or LBMA-composite license is MIAX's cost, not the royalty's.
- **Perpetual Product** is defined by characteristics, not asset. It covers anything with no scheduled expiry (or a self-extending one), anything with a periodic funding, carry or reset payment, or anything marketed as perpetual. Options, spreads and strips on these are included.
- **Exclusivity** covers U.S. DCMs and national securities exchanges, held by paying. It releases to non-exclusive if nothing lists within 18 months, or if no royalty accrues for 12 consecutive quarters. Non-U.S. venues of others and non-exchange uses stay with AP.

> [!number] 60% — royalty on every perpetual product, any underlying
> Of Covered Fees, from the first listing of each class, with nothing to countersign (The Deal ¶3(d)).

> [!tension] The rate changed through the room. The September 18 edition set 45% flat on the equity class and 35%/25% on later lines, with a $5M signing payment and $1M for founder availability. The September 28 "final" moved to one payment and one rate, and the memos never restate the numbers. The Deal's own text dated September 30 states 60% and $40M.

*Sources: The Deal pp1–2, ¶3(a), ¶3(d), ¶5 (Sept 30, 2026); Room Updates (Sept 18, 28, 30, 2026); Runbooks v1.9 F5 (Sept 2026); Class Expansion memo p2 (Sept 14, 2026)*

## Synthesis — what this means for the crypto vision {#classes-crypto-vision}

*This section is synthesis across sources, not the content of any single document. Where it calculates, it says so.*

The crypto vision Saheb began in November 2025 now has a regulated home that was never planned as a crypto exchange. It is a crypto perp on a DCM, cleared at OCC, carried by any FCM, and paying a royalty the Deal already grants. The early ideas did not vanish. Each landed somewhere in the class program, and most were changed by the five tests.

### Where the early ideas landed

| Early idea (date) | Where it lands | What changed |
|---|---|---|
| "Dividing a crypto exchange into three legal segregated components" (Greyline, Nov–Dec 2025) | DCM = MIAX Futures; DCO = OCC; FCM = the street's existing carriers | AP owns none of the three; it licenses the design |
| Insurance fund and ADL (Dec 2025), then the BLP auction (Apr 2026) | Nothing; OCC's default waterfall stands behind the contract | "No fictional prices" removes the need |
| "24/7 Perpetual Markets" (Future Greyline Ideas, Jan 5, 2026) | The crypto class: "24/7 from day one" is the stated preference | Only where the reference is live every second |
| "Global markets" (Jan 5, 2026) | FX, metals, foreign indices; turnkey §871(m) for foreign flow; non-U.S. rights kept by AP | License-gated, and ordered |
| "Whitelabel equity perps for coinbase / Robinhood through Dorman FCM" (Jan 5, 2026) | The Robinhood brief: "The design system is the firm's" | No white-label entity; each broker builds to one standard |
| Crypto perps and spot (GLX V2 roadmap, priority Medium) | Class 2, "READY TO BUILD" | Spot dropped; cleared at OCC |
| USDC deposits via Circle Mint (GLX V2) | Absent: USD only, no wallet collateral | Listed in what the design "deliberately doesn't carry" |

### The crypto perp on the rail, in one paragraph

A bitcoin perpetual on MIAX Futures would look like this. It references the CF Benchmarks BRTI, one value a second from a chosen panel. It trades 0.1 BTC a contract, about $10,000, at $1.75 a side and a $1.00 tick. Funding locks hourly into the same nine-column file and the same message 18 as the equity class, and settles inside OCC's next-day variation. Any FCM carries it in a futures account under Rule 1.55 and NFA's virtual-currency disclosures, and customers are taxed 60/40 under §1256. There is no insurance fund, no ADL and no wallet collateral. If the index goes stale, the hour pauses at rate zero. Every element is in the sources; the assembly is this chapter's. The contrast is the offshore model the Market Maker Brief describes: "Almost every offshore perpetual lives inside a closed venue: direct membership, self-cleared, wallet collateral — no broker can carry it, no clearinghouse stands behind it."

### 24/7 returns through crypto, not equities

Greyline's first spec (December 2025) was 24/7/365 for single stocks. By March 2026, GLX had moved equities to 24/5 and proposed reaching 24/7 in V2 through trade.xyz-style "Discovery Bounds". Those are a bounded mark band around the last external price, with a ratchet re-anchor: `upper_trigger = reference_price × (1 + discovery_bound × oracle_threshold)`, with liquidation suspended outside the bounds. The two GLX documents disagree on the bands: the Tech Spec has ±5/7/7/10% by tier, the Op Doc ±1/2/3/6%.

AP dropped the device for equities. When the SIP is dark, the equity perp pauses; it does not price. The room explains the general stance: "every gate on its inputs is a place where a printed rate can be argued."

Crypto is where 24/7 comes back without any bound, because the BRTI is live every second. The only gate is calendars: Onyx's session and OCC's clearing hours. OCC's extended-hours clearing was approved on September 23, 2026. The equity class is proposed for the full 23×5, and nothing in the room yet clears a weekend. Precedents for 24/7 clearing exist elsewhere: Nodal Clear began clearing margined futures 24×7 in May 2025, and Kalshi's metals perps run 24/7 self-cleared.

> [!tension] The memo prefers 24/7 crypto from day one. OCC's approved extended-hours clearing is 23×5, and no source shows OCC agreeing to weekends. If 24/7 is the point of the crypto class, the OCC session question in the digital-asset addendum is the gating item.

### Against the offshore benchmarks

The GLX documents measured the prize against offshore leaders:

- **Hyperliquid:** $2.95T cumulative volume and $844M revenue with 11 people (Competitive Memo). The Connamara memo gives $4T and about $900M of profit instead.
- **Trade.xyz:** about $600B annualized in equity and commodity perps. S&P DJI licensed the S&P 500 for perps on March 18, 2026.
- **The failure case:** October 10, 2025, with $19.1B liquidated and $2.1B auto-deleveraged.

The GLX design spec named Hyperliquid "top tier" and Lighter "minimalist" as the interfaces to match. It asked for "Robinhood-style home screens where total equity is the primary focal point". AP's display standard does exactly that through item 8, the account equation.

AP's argument is not that it beats these venues on features. It is the one the memo makes for metals against Kalshi, and it applies to crypto too: "the same product on the street's rails". U.S. persons can reach it through brokers they already use, and the losses of a cascade fall on margin calls and OCC's waterfall, not on other customers' profits. That argument is this chapter's reading, built from the sources' own contrasts.

### What the royalty means for the crypto line

The following is arithmetic on the memo's figures, stated in no document:

- At 60%, the crypto pool of $9.3M / $28M / $75M a year would pay AP about $5.6M / $17M / $45M a year.
- At the crypto ceiling of $2–8B, the royalty would be about $1.2–4.8B a year.
- MIAX's 40% at the lowest rung (about $3.7M) covers the estimated $100–500k license several times over.

On these figures the crypto line pays its own way from the first rung, and AP has to deliver nothing new for it.

The crypto field is also moving:

- Kalshi holds the first CFTC-approved perpetual (bitcoin, on the BRTI, May 29, 2026).
- Coinbase sells nano perp-style futures at $0.10 a side.
- Robinhood announced U.S. crypto perps through its own FCM on September 29, 2026.
- Payward plans onchain U.S. perps through allowlisted Hyperliquid markets.
- Rothera, part-owned by MIH, runs a 24/7 order book.

The sources show none of these clearing at OCC. AP's equity claim, "a single fungible contract at OCC" reachable through every FCM, would carry over to crypto unchanged.

### What is still open

- **The decision is MIAX's.** It follows equities, and the license covers the class only once the Deal signs.
- **Litigation.** The commodity-perpetual case could move the categorization behind the May 2026 order.
- **The session call.** 24/7 depends on platform and clearing calendars.
- **License terms.** The CF Benchmarks terms are private estimates until signing.
- **Rights outside the U.S.** Under the Deal, non-U.S. venues and non-exchange uses stay with AP. If the "Global markets" idea is ever pursued outside the U.S., it would rest on rights AP still holds. No document plans that.

*Sources: Class Expansion memo (Sept 14, 2026); The Deal (Sept 30, 2026); Market Maker Brief p6 (Sept 2026); Room Update (Sept 28, 2026) p17; GLX Tech Spec §27, Op Doc §45–51, Competitive Memo v54, Perpetual Exchange Examples V1.2 (Mar–May 2026); Future Greyline Ideas (Jan 5, 2026); Greyline MIAX proposal and Pathway docs (Nov–Dec 2025); How to Win pp4–6, 18 (Sept 2026)*

<!-- END CHAPTER -->
