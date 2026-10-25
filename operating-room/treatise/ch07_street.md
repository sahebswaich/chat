# VII. The street — market makers, brokers and the app

A listed perpetual is only as real as the firms that can carry it. American Perpetual answers "who has to build what" in one sentence, and the partner documents repeat it: every firm that carries the contract "builds the same thing: four inputs, four booking rules, one screen, one report line." The exchange computes the rate, OCC moves the money, and the firm books one line and shows it.

This chapter covers the street layer of the September 2026 data room: the Launch Partner Brief, the clearing-member annex, margin as a customer meets it, the Market Maker Program, the Robinhood brief and its four app screens, the Connamara option and the public site. It then turns to the competitors that appeared between CME's relaunch on July 27, 2026 and Robinhood's crypto-perp announcement on September 29, 2026.

Everything here is prepared, and none of it is engaged. MIAX Futures has not engaged an integration partner. Robinhood has agreed to nothing. Every handout says "Products are subject to regulatory approval and are not currently available for trading."

## The briefs and who reads them {#street-briefs}

AP wrote one brief per audience. All of them draw on one technical specification (UTS v1.0, revised September 30, 2026), so no firm has to work anything out for itself. "Training is reading, not discovery."

| Document | Reader | Date | Length | What it asks for |
|---|---|---|---|---|
| Launch Partner Brief v2.4 | FCMs, clearing members, market makers | Sept 2026 | 24 pp (28 bound) | An NDA, a conformance slot, a switch |
| UTS Annex C — FCM/CM Build | Member engineering and operations | July 7, rev. Sept 30, 2026 | 12 pp | The whole member build |
| UTS Annex D — Public Site | MIAX web and product teams | July 7, rev. Sept 30, 2026 | 3 pp | Naming, notices, downloads, copy rules |
| Fact Sheet; Contract Specifications | Customers | 2026 | 2 pp each | — |
| Market Maker Brief | Market makers, principal trading groups | Sept 2026 | 12 pp | Names you would make, a contact, an NDA |
| Robinhood Brief | Robinhood Markets, Inc. | Sept 2026 edition | 14 pp (18 bound) | An NDA, two notices, a screen, a switch |
| Connamara Integration Brief | Connamara Systems (Daniel Curry, CRO) | Sept 2026 | 25 pp | An NDA and a working session |
| Street Build memo | MIAX Products Leadership | Sept 16, conformed Sept 28, 2026 | 5 pp | A yes or no on one outside team |

**Authorship is layered on purpose.** The Launch Partner Brief, Market Maker Brief, Fact Sheet and Contract Specifications carry "© Miami International Holdings". Each reads "FROM: MIAX Futures, with American Perpetual LLC (Originator)". The Robinhood Brief is "© 2026 American Perpetual LLC".

AP drafted the partner materials in the Exchange's voice so MIAX could adopt them as its own. After signing, "the work & every contact are the Exchange's". The briefs go out first, and the mutual NDA then opens Annex C. AP "keeps no operational role."

> [!tension] Every partner brief speaks for MIAX, but the room shows MIAX issuing none of them. Until signing they are AP's drafts.

The Robinhood Brief's version label is inconsistent. The September 18 room update calls it v1.9 and the folder guide calls it v2.0. The text itself says "September 2026 edition".

*Sources: Launch Partner Brief v2.4 (Sept 2026); UTS Annex C, D (July 7, rev. Sept 30, 2026); Market Maker Brief (Sept 2026); Robinhood Brief (Sept 2026); Connamara Integration Brief (Sept 2026); Room Updates (Sept 18, 28, 30, 2026)*

## The Launch Partner Brief {#street-launch-brief}

The Launch Partner Brief is the document a carrying firm takes "to the meeting upstairs". It covers three things:

- **The product:** "a no-expiry, cash-settled future on 100 shares of a single U.S. equity — held to its stock by an hourly funding rate, listed on MIAX Futures, cleared at OCC, carried in the accounts your customers already have."
- **The build:** "Four booking rules. One added line on your OCC report."
- **The business:** one cleared book for the whole street, and a member build done once that carries every later class.

The cover makes the demand case in four numbers:

- perpetuals traded more than $200B a day offshore in 2025;
- they are more than 90% of global crypto-futures volume;
- the top 200 U.S. names' own cash tape trades $589B a day;
- more than 100 OCC clearing members are "already in place".

### The machine in six lines

| Line | Formula | What it means |
|---|---|---|
| Index | `midpoint(consolidated NBBO)` | The SIP quote midpoint, used only when two-sided and not crossed |
| Mark | `median(Last, Bid, Offer)` | The contract's own price on its own book |
| Premium | `Mark − Index` | "What funding disciplines" |
| Funding Rate | `TWAP((Mark − Index)/Index) ÷ 24` | Flat average of 5-second samples (~720 an hour), final at the lock |
| Funding Adjustment | `Rate × Mark × net contracts × 100` | Positive rate: longs pay, shorts receive |
| Mark (paused) | `Index + last valid Premium` | Only an hour with no valid sample locks at rate 0 |

The **funding rate** is the hourly payment between longs and shorts that ties the perp to its stock. It is uncapped ("no clamp on the rate"). What contains it sits upstream: a 5% trading collar, the median Mark and the hour-long average.

In the brief's worked hour, the rate is +0.000042 on a $250.00 Mark, about 0.097% per funded day. A holder long 10 contracts pays 0.000042 × 250 × 10 × 100 = $10.50, and the shorts receive $10.50.

**Contract terms.**

- **Size and tick:** 100 shares; $0.01 a share, or $1.00 a contract.
- **Hours:** Sunday 9:00 p.m. to Friday 8:00 p.m. ET, with a daily 8–9 p.m. break. That gives 23 funded hours a day, "never twenty-four". The SIP's 23×5 production starts December 6, 2026.
- **Daily settlement:** the volume-weighted Mark over 3:59:30–4:00:00 p.m. ET. Cash moves through OCC the next business day: members pay by 9:00 a.m. ET and OCC pays out by 2:00 p.m.
- **Margin and limits:** a 15% margin floor; a 25,000-contract position limit or accountability level; reporting at 1,000 contracts.

### Fees and the all-in cost

The recommended launch schedule is $1.50 per contract per side, flat, and $0.40 for market makers. Price-bucket tiers are "the named evolution".

Funding is never a fee: "it passes between position holders and nets to zero; the venue collects nothing on it."

With a typical FCM commission and the pass-throughs, a customer pays about 0.83–1.24 bps a side on a $250 name. Offshore base takers pay about 4.5–5.5 bps, "before the offshore venue's own spread costs".

The pass-throughs are small:

- **SEC §31:** $0.0042 per round turn.
- **NFA:** $0.01 a side, in futures accounts only.
- **FINRA TAF:** $0.000135 a contract, paused for October–December 2026.

> [!number] 4–7× — cheaper all-in than offshore base-taker fees
> ≈0.83–1.24 bps a side on a $250 name, against ≈4.5–5.5 bps offshore, before the offshore spread.

### Onboarding: "An NDA, a conformance slot, a switch"

Four steps: an NDA, UAT, internal approval, enable. "There is no product contract to sign", because "exchange products are never negotiated".

There are four starting points:

- an FCM or OCC clearing member activating MIAX Futures privileges under the May 20, 2026 participant-exchange arrangement;
- a market-making firm;
- a broker-dealer or wealth platform filing a Form 7-R;
- a retail broker coming in through a carrying FCM.

Access needs nothing new: "Nobody needs MIAX Futures Clearing House membership for this class — ever."

*Sources: Launch Partner Brief v2.4 (Sept 2026) pp1–23; Fact Sheet (2026); Contract Specifications (2026)*

## The member build: four inputs, four booking rules, one screen, one report line {#street-member-build}

The member build is done once and is the same for every asset class: "every future perpetual class rides it unchanged." The only recurring per-name clearing item is OCC's margin-data entry. "Your firm never computes a rate, never recalculates an index, and never encounters a missing row."

> [!number] 4 · 4 · 1 · 1 — inputs, booking rules, screen, report line
> The whole member-side build, identical at every firm and reused by every later class.

### The four inputs

| # | Input | What it carries | Detail |
|---|---|---|---|
| 1 | Feed message 18 | The Funding Rate record | Predicted rate every 5 s (type 'P'); settled print at :00 (type 'S'). Number 18 is "proposed" |
| 2 | Funding file | `onyx_financials_funding_rate_YYYYMMDD.csv` | Nine columns, rewritten whole at each lock, "never appended"; fetched, not sent |
| 3 | OCC DDS "Funding Adjustment" line | "The money" | Per OCC account: securities-customer, segregated futures, house |
| 4 | Instrument definitions | Type 'P' plus no-expiry sentinels | 999912; 65535 (= June 6, 2149) on feeds; 9999-12-31 in text; 99991231 at OCC |

The file's nine columns run:

1. product code
2. Instrument ID
3. lock time
4. rate
5. Mark at lock
6. Index at lock
7. Index status
8. Funding Status
9. the cycle's running per-contract total

The sentinels are placeholder far-future dates. A no-expiry contract still has to fill date fields built for expiring ones, and a zero "decodes to 1970 and reads as expired".

### The four booking rules

1. **"Compute and show each lock as unrealized funding, and count it in equity."** The accrual is rate × Mark-at-lock × contracts as of the lock × 100, at full precision. "Never round a per-lock accrual."
2. **"Positions as of the lock time govern."** The position at :00 wears the hour. Round trips inside the hour accrue nothing. A trade after the 4 p.m. closing lock rolls to the next cycle.
3. **"A locked row is final."** There is no bust and no true-up. A paused hour is rate 0, and no row is ever missing. "Take the count from the cycle, never from a constant": 23 rows normally, 20 on an early close, 19 in a name's first cycle.
4. **"Post once, at the wire."** One labeled "Funding Adjustment" cash line, posted inside the daily variation payment and itemized beside variation.

### One record, three deliveries, one tie-out

Each live hour the Exchange locks one record per name: lock time, rate, Mark, Index, Index status and Funding Status, "final at :00, no bust." The record goes out three ways: on the feed, in the file, and as a furnish to OCC.

Once a day, OCC computes each member's funding as start-of-cycle position × the cycle's per-contract total, plus each trade × the total of the locks after it. It checks that each name's pool nets to zero, rounds once and prints the DDS line. The cash rides the next business day's variation wire.

The tie-out is one identity: "Σ customer cent-rounded postings + your rounding adjustment = your DDS Funding Adjustment line with its sign reversed."

> [!quote] "If the tie-out otherwise misses, a position is off somewhere — never the rate." — Launch Partner Brief, Sept 2026

The brief spells out three edge cases:

- **A name that fails OCC's zero-sum check after correction** is held and paid later. "Only the settlement date moves."
- **Give-ups** get "one replay, after finality." A trade executed at 10:14 a.m. and given up at 3:00 p.m. bears funding at the carrying firm from the 11:00 lock. "Accrued funding is derived state", so no balance ever moves between firms.
- **A flat account** "can carry a Funding Adjustment line for hours it owned earlier in the cycle."

Variation settles in the same wire. The cycle and the variation window "cover the same clock … neither overlap nor leave a gap."

*Sources: UTS Annex C §C.1–C.4 (rev. Sept 30, 2026); Launch Partner Brief v2.4 pp8–11 (Sept 2026); Connamara Integration Brief pp6–7 (Sept 2026)*

## The clearing-member annex {#street-fcm-annex}

Annex C turns the four rules into a build for each role. Most roles build far less than the full stack.

| Role | Account door | Portfolio margin | What it builds |
|---|---|---|---|
| OCC clearing member, no customers | House | — | The DDS line only |
| Full FCM + full BD | Either (genuine election) | Yes | Full stack |
| BD adding SFPs by Form 7-R | Securities, mandatory | Yes | Full stack |
| Futures broker adding SFPs by Form BD-N | Futures, mandatory | "Structurally foreclosed" | Full stack |
| Prime broker | Either | Yes | As full FCM/BD |
| Market maker / Security Futures Dealer | Outside the customer regime | — | Feed handler, give-in back-fill, close-only control |
| Prop trading firm | — | — | As market maker |
| Introducing broker; retail app ("Usually an IB or introducing BD") | Inherits the carrier's | — | The display set only |

**Registration is by notice, "not full dual registration".** A security future is both a security and a futures contract, so the firm handling customer orders registers with both the SEC and the CFTC.

- **A broker-dealer** adds the futures side on Form 7-R with NFA, effective on filing. It carries the perp in a securities account, with SIPC protection and Rule 15c3-3.
- **An FCM** adds the securities side on Form BD-N. It carries the perp in a futures account, under CEA §4d segregation and without SIPC.

**Before a customer's first order** the firm needs:

- account approval;
- the joint risk disclosure plus a supplement for "no-expiration, funding-bearing security futures" (customer sales wait for FINRA and NFA to publish it);
- an account-election disclosure.

**The onboarding checklist** is the same at every firm:

- a message-18 feed handler;
- a funding-file pickup job;
- the DDS line routed to a funding sub-ledger;
- a lock-time position snapshot;
- give-in back-fill;
- a close-only order-entry control;
- statement templates;
- disclosure and account approval;
- large-trader reporting;
- the customer display;
- OCC intake on Ovation ("no ENCORE");
- connectivity to the perp's own Onyx instance;
- extended-hours clearing;
- UAT on one script.

One UAT check reads: "a 65535 feed date read as June 6, 2149 — never as expired, with no 32-bit time conversion overflowing." FIX order entry and drop copy are unchanged, and Onyx risk protections are "Configuration, not build". In the annex's words: "nothing waits on anything novel from your vendors: one feed message, one file, one report line."

**Corporate actions run in four lanes.** "One classifier, four lanes: declared cash → A; a whole-number ratio → B; anything else with value or a re-basing → C where the name survives with a consolidated NBBO, D where it does not."

- **Lane A** cuts the prior settlement price by the dividend.
- **Lane B** multiplies counts and divides the price.
- **Lane C** settles the contract and relists fresh.
- **Lane D** settles through a four-tier price waterfall.

"No position conversion ever hits your books." The pitfall the annex flags: "a 0.50 step read against a stale cached prior is a phantom −1.5%." Close-only periods are the member's to enforce, since "The matching engine cannot distinguish opening from closing."

> [!tension] One tax question is open: is the hourly Funding Adjustment part of the contract's gain or loss, or a separate item, and where does it go on Form 1099-B? Each carrying firm's tax team must settle it before launch.

*Sources: UTS Annex C §C.0–C.8 (rev. Sept 30, 2026); Launch Partner Brief v2.4 pp12–23 (Sept 2026); Connamara Integration Brief pp17–18 (Sept 2026)*

## Margin, as customers meet it {#street-margin}

The Exchange sets no margin level of its own. The federal 15% (initial and maintenance) is a floor. What a customer posts depends on the account door the firm uses.

| Rung | Account | What the customer posts | Notes |
|---|---|---|---|
| 1 | Futures account | SPAN on OCC scan ranges, floored at 15% | No offset against stock or options |
| 2 | Securities, strategy-based | 20% (FINRA 4210(f)(10)) | The Exchange asks FINRA to conform to 15% |
| 3 | Securities, portfolio margin | Near 15%, floor $37.50 a contract | One computation across perp, stock and options |
| 4 | Market maker (Security Futures Dealer) | Outside the customer regime | From SEC approval of Rule 3.3.2(e) |

**Funding is never an input to the requirement, but it counts in equity.** "A persistent negative carry erodes equity toward a house call."

**One NVDAP contract** (the perp on NVIDIA), worked through:

- **Notional:** at a $180.00 Mark, 100 × $180 = $18,000.
- **Strategy-based margin:** 20% = $3,600, or 5× leverage.
- **Portfolio margin:** the "illustrative unhedged risk-scan result" is $2,700, or 6.7×. That is exactly 15%.
- **Equity on a long bought at $178.50:** the price gain is +$150.00 and five locks at $0.756 cost −$3.78, so equity is +$146.22.

OCC margins the clearing member separately: "STANS on the net portfolio, SPAN gross for a segregated futures account — never on a customer's screen."

> [!number] $2,700 — margin on one NVDAP contract at a $180 Mark (6.7×)
> The portfolio-margin risk scan, equal to 15% of $18,000 notional. Strategy-based margin is $3,600 (5×).

**Portfolio margin is a ten-step path.** On the FINRA side, it needs:

- approval from the firm's designated examining authority;
- customer approvals;
- a signed disclosure;
- a dedicated account.

Portfolio-margin accounts under $5 million have carried an intraday-margin obligation since June 4, 2026. On the OCC side it needs:

- a DDS output form;
- an SFTP or IBM MQ link;
- OCC's nightly risk data (ten pre-computed P&L points per contract);
- class-group mapping and certification;
- ten days' notice before an account-type change.

"Nothing in that table comes to the Exchange."

**Enforcement is the firm's.** "Margin enforcement is yours, on published parameters." There is no insurance fund and no auto-deleveraging. OCC's default waterfall stands behind every contract.

> [!tension] The same $2,700 carries two labels: a portfolio-margin risk scan in the Robinhood Brief, and the futures-account result (when OCC's scan is at or below 15%) in the Connamara brief's task 08. The numbers agree; the labels could mislead a customer.

> [!tension] FINRA's 20% in securities accounts stands until FINRA amends it. The Exchange's request to cut it to 15% is an ask, not a result.

*Sources: Launch Partner Brief v2.4 pp16–18 (Sept 2026); UTS Annex C §C.5 (rev. Sept 30, 2026); Robinhood Brief p11 (Sept 2026); Connamara Integration Brief p20 (Sept 2026)*

## The Market Maker Program — the funding print as a borrow rate {#street-mm}

The pitch to market makers is a new market, not leverage: "two markets in one instrument: the delta, and the funding print — an exchange-published, per-name financing rate, new to U.S. equities." The brief is titled "A new tape in U.S. equities."

### Why the print is a borrow rate

Makers' quotes are two of the Mark's three inputs, sampled about 720 times an hour. So makers set both the reference price and the financing print. "Fair value has a second term": the premium settles at the name's net financing spread.

- **Easy-to-borrow names** trade near flat.
- **Hard-to-borrow names** trade at a discount with negative funding, so shorts pay and longs collect.

Today borrow is "a phone-call market" run through prime brokers: "bilateral, opaque, different for every account". Short interest is reported twice a month. On the perp, a short needs "no locate, no borrow desk, no recall".

A name's financing now prints in four places:

1. stock loan, bilateral;
2. the options surface, implied;
3. CME's dated strip, as term rates from July 27;
4. the funding rate, published hourly.

"Where prints diverge, a market exists."

> [!tension] The July 27 CME memo had the direction backwards for a hard-to-borrow name: it said the print "pays the short the scarcity price". The September 18 erratum corrects it: "at a discount the short pays and the long receives."

The flywheel is six steps:

1. Every flow arrives in one book.
2. Each arrival tightens it.
3. A tighter book gives a truer print.
4. A truer print pulls the next arrival.
5. Depth compounds.
6. The book "cannot be dislodged by a copy".

With no strike grid, no expiry strip and no roll, liquidity "cannot fragment".

> [!quote] "The venue that prints a name's financing owns the name's flow — and the firms that make the book set the print." — Market Maker Brief, Sept 2026

### Economics: forty cents a side

The maker fee is $0.40 a side, about 27% of the regular $1.50 and 40% of a $1.00 tick. Quoting costs about 0.12 bps a side at the realized notional of roughly $33,600 a contract, or 0.16 bps on a $250 name. Pass-throughs add about $0.07–$0.10 a side.

There are no rebates: "None, at launch, by design … not a taker-funded subsidy." "No ladders, no tokens, no requalification." Membership is a separate thing ("the Preferred Rate Program renamed on September 18, 2026") and does not earn the maker rate by itself.

> [!number] $0.40 — market-maker fee per side
> About 27% of the $1.50 regular fee; ≈0.12 bps of notional to quote; no rebates.

### The quoting standard

The recommended terms follow MIAX's own B500 program (certified June 16, 2026). The final terms are MIAX's to set.

| Window | Two-sided time | Size | Width |
|---|---|---|---|
| The stock's regular hours | ≥ 90% | ≥ 5 contracts a side | Greater of $0.20 or 1.5× the stock's spread |
| Rest of the session | ≥ 50% | ≥ 1 contract | Same |

Performance is measured monthly per name, with halted periods excluded. A maker that falls short two months running loses the rate and the designation in that name. The standard is published, because it doubles as the Security Futures Dealer holding-out standard, "the form the SEC approved for OneChicago's makers". Incentives can stay confidential. Approval attaches to the class and carries to successor names.

### Seat, build and risk

**The seat.** Rule 2.1.9, amended June 2026, lets MIAX run an incentive program "for any contract or product". A maker registers as a Security Futures Dealer in three steps:

1. Register as an SEC dealer or a CFTC floor trader.
2. File the Exchange's dealer form, with three undertakings.
3. Quote, and keep records.

The margin exclusion runs from SEC approval of Rule 3.3.2(e). Until then, a maker clearing through another firm posts the customer floor.

**The build.** "Order entry unchanged. One message to parse. One conformance test." The shortest path is "An options market maker at OCC today", and "no adjudication reopens a locked rate or a Daily Settlement Price".

**The risk.** "Funding is an uncapped pass-through, by design". That is "real, unbounded carry risk", though the hourly average dilutes any one sample to about 1/720th.

The cohort runs MIAX's own member makers first and offshore perp trading firms second. Four flows feed the book:

- Robinhood retail;
- carry desks (long stock, short perp);
- options desks needing a hedge that never rolls;
- portfolio-margin offsets.

The ask is the names a maker would make, a contact and the NDA. The brief closes: "The book is new. It is yours to make."

*Sources: Market Maker Brief (Sept 2026); Room Update (Sept 18, 2026) erratum; Room Update (Sept 28, 2026) p6; How to Win pp8, 12 (Sept 2026)*

## Robinhood: the perp, in the app {#street-robinhood}

Robinhood is the worked example because it is "the hardest ordinary case". It is a carrying and clearing broker with an introducing broker in front, a retail front end with its own design system, and portfolio margin across three products on one balance. "Every other firm is a subset of it." The pitch puts the perp in the customer's existing securities account, beside the stock and its options: "one balance for the three."

### Robinhood's own record

| Date | Who | What they said or did |
|---|---|---|
| Dec 2023 | 24 Hour Market | "the only US retail brokerage to offer 24/5 trading of single name stocks" |
| May 21, 2025 | Robinhood Derivatives letter to the CFTC | "We believe that 24/7 trading is and should be the future of our capital markets, including perpetual futures." |
| Jan 21, 2026 | JB Mackenzie, MIAXdx close | "exploring future partnership opportunities with a technology driven leader in the exchange industry" |
| Feb 10, 2026 | Vlad Tenev, Q4 call | Perps outside the U.S.: "we're getting really good feedback" |
| Apr 9 & Jul 1, 2026 | Robinhood Europe | Crypto perps under MiFID II, then gold, silver, crude, EUR/USD and ETFs, at up to 10× leverage |
| Apr 22, 2026 | Johann Kerbrat, to Reuters | Wants "a proper perpetual product that is able to compete" |
| Jul 29, 2026 | Vlad Tenev, Q2 call | CFTC talks "constructive" |
| Sep 8, 2026 | Robinhood | Stakes in Crypto.com and OG.com; event contracts routed to OG.com |
| Sep 29, 2026 | HOOD Summit '26 | Crypto perps "right inside the Robinhood app": eight assets, "Offered by Robinhood Derivatives through Bitstamp" |

### The parties

"MIAX's parent and Robinhood own an exchange together."

- **May 2023:** LedgerX, FTX's U.S. derivatives exchange, went to MIAX from the FTX estate and became MIAXdx.
- **January 2026:** Miami International Holdings sold 90% of it to a venture Robinhood leads with Susquehanna, and kept 10%. The venture is now Rothera, a CFTC-registered exchange and clearinghouse with a 24/7 order book.

Robinhood's stock trades clear at NSCC and its options at OCC. MIAX Futures became an OCC participant exchange on May 20, 2026.

### The seat: two notices, one door

Two Robinhood entities file Form 7-R with NFA, "each effective on filing":

- **Robinhood Securities, LLC**, the carrying broker and an OCC clearing member, notice-registers as an FCM.
- **Robinhood Financial LLC**, the introducing broker, notice-registers as an IB.

The rule then fixes the securities account, with SIPC and Rule 15c3-3 protection. The futures door through Robinhood Derivatives, LLC "stays open and is not the one used here, because it would split the customer's balance in two."

NFA's assessment does not apply in this setup. Large-trader reports reuse "the Part 17 reporting Robinhood Derivatives already runs." An earlier two-door, three-notice draft was superseded by September 28.

### The four screens

The brief shows four screens, all at 9:41, captioned "ILLUSTRATIVE VALUES. THE DESIGN SYSTEM IS ROBINHOOD'S." The placement: "On the stock's page, Trade opens one more pill — Trade Perps — beside Trade Options … and Home lists the position in its own row, as it lists held options."

**1 · The entry — NVDA stock page.**

- NVDA · NASDAQ, NVIDIA, 180.04, ▲ +2.24 (+1.26%) Today.
- Bid 180.03 – Ask 180.05.
- Your position: 12 shares, average cost $153.54.
- Buttons: **Trade Perps · Trade Options · Sell · Buy**.
- Buying power $6,214.20.

**2 · The order ticket.**

| Line | Value |
|---|---|
| Order | Market order · Buy NVDAP Perpetual · NVDAP 180.00 · $6,214.20 available · Securities account |
| Quantity | 1 contract |
| Margin requirement | Portfolio margin · illustrative unhedged risk-scan result — $2,700.00 |
| Estimated cost | $2,701.52 (Margin held $2,700.00 · Exchange fee $1.50 · Regulatory fees $0.02 · Commission $0.00) |
| Leverage | 6.7x |
| Funding / lock | −$0.76 |
| Next lock | 10:00 AM ET |

**3 · The NVDAP page.**

- NVDAP · Perpetual, NVIDIA Perpetual, 180.00, ▲ +2.20 (+1.24%) Today.
- Bid 179.99 – Ask 180.01 · Funding +0.000042/hr.
- Your position, Securities account · Robinhood Securities: 1 contract, Long.
- Market value $18,000.00. Price return +$150.00 (+0.84%). Unsettled funding · this cycle −$3.78.
- Margin requirement $2,700.00. Leverage 6.7x.
- Funding rate +0.000042 / hr. Next lock 10:00 AM ET · 19:12.

**4 · Home.**

- Investing $24,318.70, ▲ $296.22 (1.23%) Today.
- Stocks 2: NVDA 12 shares, AAPL 5 shares.
- Options 1: MU $1,075 Call 9/25.
- **Perpetuals 1: NVDAP 1 contract · Long +$146.22 +0.82% · funding +0.000042/hr.**

The arithmetic holds:

- 18,000 ÷ 2,700 = 6.67×
- 2,700 + 1.50 + 0.02 = 2,701.52
- 5 × $0.756 = $3.78
- 150.00 − 3.78 = 146.22

> [!number] −$0.76 — funding per lock on one long NVDAP contract
> 0.000042 × $180.00 × 1 × 100 = $0.756. A short sees +$0.76.

### Robinhood's part

Robinhood's screen has five things on it:

1. **The price**, which is the Mark.
2. **The rate**, ticking every 5 s and freezing at :00.
3. **The accrual**: equity = cash + unrealized P&L + unrealized funding.
4. **The cash line**: "Funding Adjustment", once a business day.
5. **The banners**: account, ex-date step-down, split, closing-only, terminal notice.

"Robinhood does not compute a rate or an index." On money: "Robinhood's commission rides on top of the exchange fee. The product is a new transaction line — margined, funding-bearing, commissionable — in accounts already held." The all-in cost on the NVDAP example is 1.15–1.72 bps a side.

Next comes "An NDA, two notices, a screen, a switch". After that, "every later name and every later class is a product-list election."

> [!quote] "Robinhood's part is the UI — five things a customer looks at — and the booking beneath it: four rules and one tie-out." — Robinhood Brief, Sept 2026

> [!tension] The brief is a proposal, and the room shows no sign that Robinhood agreed. Robinhood is building its own paths: crypto perps through its own FCM and Bitstamp (announced September 29), and a stake in OG.com, whose exchange filed perps on ten stocks on September 24.

*Sources: Robinhood Brief (Sept 2026 edition) pp1–14; Connamara Integration Brief Part 09 (Sept 2026); Room Update (Sept 28, 2026) pp16–17*

## The display standard: seventeen items, the same everywhere {#street-display}

"One screen" means fixed display semantics, not a shared app: "The design system is the firm's. The semantics are not: the same seventeen items, the same labels, the same arithmetic on every screen in the street, so that a customer who reads the public funding history can recompute every posting on every platform."

| # | Item | R/O | Rule |
|---|---|---|---|
| 1 | Mark Price | R | "never the last trade alone, never the Index" |
| 2 | Index | O | "Index (published midpoint)" |
| 3 | Current funding rate | R | Per hour, live or predicted |
| 4 | Previous settled rate and history | R | — |
| 5 | Annualized rate | O | Only if labeled: hourly × 23 × 252. "Never × 24 × 365"; never the headline |
| 6 | Countdown to next lock | O | Locks at :00, 22:00 through 20:00 |
| 7 | Unrealized funding, per position and in total | R | — |
| 8 | Account equation | R | equity = cash + unrealized P&L + unrealized funding |
| 9 | Daily cash line | R | "two lines, never one blended number" |
| 10 | Corporate-action display | R | Step-down, split, run-down banner |
| 11 | Closing-only banner | R | Blocks new positions |
| 12 | Terminal settlement notice | R | Final price, cash date, successor |
| 13 | Fees and pass-throughs | O | Never inside the funding line |
| 14 | Risk disclosure | R | — |
| 15 | Account type and change notice | R | — |
| 16 | Margin basis as one portfolio computation | R (PM firms) | Never a per-position percentage |
| 17 | Dedicated PM account identification | R (PM firms) | — |

One more rule completes it: "a partially halted hour still settles a full hour of funding, computed only from the samples taken while the underlying was live." On the annualization rule, the illustrative +0.000042 an hour × 23 × 252 comes to about 24.3% a year. That is derived arithmetic for this chapter; no document states it.

*Sources: UTS Annex C §C.6 (rev. Sept 30, 2026); Connamara Integration Brief pp8–10 (Sept 2026); Street Build memo (Sept 16, 2026)*

## Connamara and the Street Build option {#street-connamara}

The Street Build option would replace "thirty separate projects" with one outside engineering team. That team would carry one reference implementation from firm to firm, test it against one script pack and sign it off against one checklist. The decision is MIAX's, and "the launch waits on no outside team."

**How it arose.** Connamara Systems approached AP. In its own words, it is "co-authors and official maintainers of QuickFIX; custom software for capital markets since 1998", working fully remote. AP prepared a 25-page Integration Brief for Daniel Curry, Connamara's Chief Revenue Officer: "MIAX Futures has not engaged an integration partner; this is what the work would be if it does." It carries no deal terms and no rates. With one team, the build "stops being a project at each firm and becomes a fitting".

| Party | What it does | What it builds |
|---|---|---|
| MIAX Futures (Onyx) | Samples, locks, publishes, furnishes to OCC | Engine, message, file, instrument record, corporate-action lanes |
| OCC (Ovation) | Takes in rows, computes with a zero-sum check, prints the DDS line | Three new pieces, an agreement amendment, one rule filing |
| Clearing member / FCM | Books and carries | Annex C |
| Broker / wealth platform | Shows | Display set and statements |
| Market maker | Quotes | Feeds, risk configuration, close-only control |
| Vendor / OMS / ISV | Parses | Parser and booking module, once |

"The team's work sits in the last four rows."

**The engagement** is six steps per firm:

1. scope;
2. the pack, under NDA;
3. the fitting;
4. the test-bed run (MIAX's Firm Test Bed and OCC's scenario testing);
5. sign-off against the Annex C checklist;
6. the first cycle, with the first wire's tie-out held and filed. Then "The firm owns it".

Firms come in waves: vendors first ("most firms book through a back-office vendor and trade through an ISV"), then launch firms, then primes, then market makers. A clearing member gets the full kit, and "the first proves the build, the second proves the repeat." An introducing broker is the shortest fitting, a prime the largest.

**Thirteen tasks, in build order:**

1. Connect
2. Identify
3. Read the market
4. Take the lock
5. Pick up the file
6. Book ("sample cycle books to the cent")
7. Settle and tie out ("first three wires tie out with no unexplained residual")
8. Margin
9. Open the door
10. Show and state
11. Handle corporate actions
12. Test and certify
13. Go live, watching two numbers: row count per cycle and tie-out residual

**The kit** is built once and owned by each firm after go-live. It holds:

- parsers;
- file pickup;
- lock-time snapshot;
- booking module;
- tie-out job;
- display and statement templates;
- alert consumer;
- identity mapper;
- an optional portfolio-margin adapter;
- a script pack;
- an ops runbook.

Corrections carry forward to the next firm, "never back into a live firm without that firm's change control."

**Twelve switches** (open settings) remain.

- **Six are the Exchange's:** the message number and release; per-name price bounds; the SIP subscriber entity; the no-band value; the codes for GOOGL and BRK.B; the cancel-reason strings.
- **Six are OCC's:** the DDS layout and cut-off; identifiers through corporate actions; execution time through a give-up; sentinel acceptance; scan-class dates; portfolio-margin class-group mapping.

Not switches: "four rules, tie-out identity, sign convention, cycle definition, display semantics."

**The decision.** If MIAX says yes, member services introduces the team and the switches are answered once. If it says no, each firm builds from Annex C and the Runbooks' member chapter.

**The idea has a history.** In the GLX phase (May 2026), Saheb proposed buying Connamara outright as "GLX Tech", for roughly $40–60M of acqui-hire consideration in the MIAX transaction draft, with a 12-component "proliferation playbook" for taking any broker live. The licensor model cut Connamara to "a vendor doc, not a counterparty". In AP it is an option for MIAX to sponsor.

> [!quote] "The first firm is the one whose stack the team knows best; the second is the one that proves the repeat." — Connamara Integration Brief, Sept 2026

*Sources: Street Build memo (Sept 16, conformed Sept 28, 2026); Connamara Integration Brief (Sept 2026); Room Update (Sept 30, 2026) p6; GLX Connamara memo, Connamara.pdf, MIAX.pdf (May 2026)*

## The public site {#street-public-site}

The public face belongs to the Exchange. AP supplies the rules, and MIAX does the design.

**Naming.** Product name, branding, symbology and framing are at the Exchange's sole discretion (The Deal ¶6(d)). "The 'American Perpetual' name appears in a product's name only if the Exchange so elects." Product pages and principal materials carry the credit line "American Perpetual LLC — originator and licensor" and a verbatim disclaimer.

**Notices and data.** There are two notice rails:

- **Corporate Action Alerts**, in four pre-written kinds, plus a Listing Alert for "the inaugural 101 together";
- **numbered Regulatory Circulars**, carrying methodology, calendars and the filing record.

Each perp page charts Mark and Index, plus the hourly funding rate, predicted and settled. "No quotation fields from the SIP are redistributed anywhere on the surface — midpoint and status only."

The existing daily files gain perp rows with unchanged layouts. Maturity shows "PERP" or 9999-12-31, and the exercise and delivery columns are always zero. Funding history is free, and DoM feed fees are waived through December 31, 2027.

**Copy rules.**

- Funding is "a rate applied per hour during the live session," never annualized in a headline.
- Long or short is stated "with the matching loss in the same breath".
- Margin copy is "never an exchange leverage figure". The Robinhood screens' "Leverage 6.7x" is the firm's own number, not the Exchange's.
- Tax copy carries "no 60/40 claim — that is an index-products claim".
- The product is "new, never first or only".
- Explainers draw on the spec section "Versus the crypto perps — what this design deliberately doesn't carry": no insurance fund, no auto-deleveraging, no wallet collateral.

The Fact Sheet heads "EQUITY PERPETUAL FUTURES — A new perpetual future on a U.S. equity." Its stat strip reads: 100 shares · Hourly funding, history public · 23×5 while the tape is live · $0.01 tick, $1.00 per contract.

*Sources: UTS Annex D (rev. Sept 30, 2026); Fact Sheet (2026); How to Win Part 04 (Sept 2026)*

## CME's July 27 relaunch and AP's answer {#street-cme}

CME proved that U.S. single-stock futures have demand again. It did so with an expiring contract that runs on an exemption. AP's answer is that the architecture decides the category, not the launch date.

**What CME launched on July 27, 2026:**

- dated single-stock futures: 55 standard (100-share) and 22 Micro (10-share) contracts;
- 50+ mega-cap names, plus "a SpaceX headline listing";
- quarterly contracts, two expiries listed;
- about 23 hours on Globex;
- futures accounts only at CME Clearing, with no offsets beyond calendar spreads;
- no adjustment for ordinary dividends.

Federal rules point a cash-settled security future at the opening price. CME settles to the close by exemption, under an SEC conditional §36 order (Release 34-105882, July 15, 2026) and CFTC relief effective July 16. The conditions are a market cap of $100B+, $450M+ traded a day and a tenor of at most nine months. Hence "fifty mega-caps and two quarterlies", and a product that "cannot easily go down-cap".

> [!number] 55 + 22 — CME's standard and Micro dated contracts, July 27, 2026
> 50+ mega-caps, quarterly expiries, futures accounts only. AP's memo went to MIAX the same day.

AP's same-day memo to MIAX Products Leadership gave six answers:

1. OCC on its newest rails, with the full clearing-member network.
2. The options complex at the same clearinghouse, through portfolio margin.
3. The funding rate as a live borrow market, "the cleanest short in U.S. equities".
4. One ticker, so liquidity does not fractionate.
5. Dated contracts are the wrong architecture for cash settlement; OneChicago failed with them (2002–2020).
6. Dividends handled by rule: "the NoDivRisk construction, inherited and completed".

| Axis | Perpetual (MIAX · OCC) | Dated relaunch (CME) |
|---|---|---|
| Structure | No expiry; one book per name | Quarterly; four rolls a year |
| Financing | Printed hourly | Implied in the basis |
| Dividends | Ex-date factor, by rule | Ordinary dividends not adjusted |
| Clearing | OCC beside options; portfolio-margin path | CME Clearing; futures account only |
| Hours | SIP-anchored, Sun 9 p.m.–Fri 8 p.m. ET | Venue clock, Sun 6 p.m.–Fri 5 p.m. ET |
| For the maker | One book | A strip |

**Hours parity** arrives with the SIP's 23×5 production on December 6, 2026, announced July 7.

**The compounding plan** has four parts:

- wire the funding line into retail broker-dealers, primes and principal trading firms first;
- out-list CME at one Schedule entry per name;
- make §871(m) withholding turnkey (base = factor × 100 × contracts). Section 871(m) is the U.S. withholding on dividend-equivalent payments to non-U.S. holders;
- cite global demand. South Korea's July 2026 leverage unwind margin-called "over a million" retail accounts, per the memo. How to Win says 1.2 million, with more than 300,000 liquidated.

**The prize** is "the financing layer of U.S. equities". The memo places it in a line with NYSE for equities, CME for rates, Cboe for volatility and ICE for energy. "Products change; infrastructure compounds."

**A legal front is open.** How to Win records a pending CME suit asking a court to declare funding-rate perpetuals swaps, and says the CFTC moved to dismiss. AP's Harmonization Submission "cites the pending CME suit by its docket caption".

> [!quote] "On being second: their head start is denominated in an asset that expires." — Market Maker Brief, Sept 2026

> [!quote] "Their product exists by exemption; ours is drafted to the rule's own branches, with no relief sought." — CME Launch memo, July 27, 2026

*Sources: CME Launch memo (July 27, conformed Sept 30, 2026); Market Maker Brief p6 (Sept 2026); Room Update (Sept 18, 2026) erratum; How to Win pp4–7 (Sept 2026)*

## The field, dated {#street-field}

In the room's last fortnight, the field went from one dated competitor to five venues with filings. AP claims it alone clears where the industry already clears: "Every product a silo adds deepens the silo; every product this venue adds deepens the network."

| Date | Event |
|---|---|
| May 2023 | LedgerX goes to MIAX from the FTX estate (later MIAXdx, then Rothera) |
| May 21, 2025 | Robinhood Derivatives urges the CFTC to permit perps on regulated exchanges |
| May 2026 | Payward (Kraken's parent) buys Bitnomial and its clearinghouse |
| May 29, 2026 | CFTC perpetuals policy statement; KalshiEX order, "the first order permitting a U.S. exchange to list" a perpetual (bitcoin, on the CF Benchmarks BRTI) |
| June 2, 2026 | Market reaction to the first approval: Cboe −9% in a session, CME and ICE ≈−4% |
| July 1, 2026 | Robinhood Europe adds perps on gold, silver, crude, EUR/USD and ETFs |
| July 27, 2026 | CME relaunches dated single-stock futures |
| Sept 1–4, 2026 | Form 1-N wave: Coinbase, KalshiEX, Bitnomial (all acknowledged Sept 8) |
| Sept 10, 2026 | Kalshi's gold and silver perps go live (self-cleared, 24/7) |
| Sept 14, 2026 | Nadex notice-registers for security futures: ten dated one-share futures |
| Sept 17, 2026 | Kris Marszalek (Crypto.com): working with the SEC and CFTC on single-stock perps |
| Sept 18, 2026 | Kalshi, Coinbase and Bitnomial file perpetual security futures |
| Sept 23, 2026 | SEC approves OCC's extended-hours clearing (Order 34-106469) |
| Sept 24, 2026 | OG.com Markets (Nadex) files perps on the same ten names |
| Sept 29, 2026 | Robinhood announces U.S. crypto perps through Robinhood Derivatives |
| Nov 2, 2026 | Reported CFTC target date for Kalshi's filing |

| Venue | Funding | Dividends | Margin | Clearing | Names |
|---|---|---|---|---|---|
| AP (MIAX · OCC) | Hourly | Ex-date factor, by rule | 15% / 20% / PM | OCC, >100 clearing members | 101, then any eligible name |
| CME (dated) | None (expiry) | In the basis | 15% SPAN floor | CME Clearing | 50+ mega-caps |
| KalshiEX | Daily | Through the funding rate | 15.50% | Kalshi Klear | 58 |
| Coinbase Derivatives | Hourly | No adjustment | ≥15% | Nodal Clear | 1 (AAPL as model) |
| Bitnomial (Payward) | 3× a day | Cash adjustment on ex-date | 15.25% | Bitnomial Clearinghouse | 10 |
| OG.com / Nadex | 3× a day | No adjustment | ≥15.05% | Own clearinghouse | 10 |

**On fees:**

- CME: $0.60 a side.
- Kalshi: from 12.0 bps taker, or $30 a side on a $25,000 contract, down to 2.6 bps.
- Coinbase's nano perp-style futures: $0.10 a side.
- AP: $1.50 a side. AP's argument is that a year's CME position pays eight sides and three rolls, against two sides and no roll on the perp.

**The field reaches past equities.** Payward plans onchain U.S. perps "starting with allowlisted Hyperliquid markets". Robinhood's crypto perps run through its own FCM, and Kalshi's metals perps are live. Chapter VIII takes these up.

> [!tension] OG.com filed perps six days before the room's date, and Kalshi's reported CFTC target is November 2, 2026. AP's path starts only when MIAX signs; the room "carries no calendar — only the order."

*Sources: How to Win pp1–7, 18 (Sept 2026); Robinhood Brief pp3–4, 13–14 (Sept 2026); Room Updates (Sept 28, 30, 2026); The Deal p2 (Sept 30, 2026)*

## What the street layer adds up to {#street-close}

The street design does three things:

- **It makes the carrying firm's work small, fixed and identical:** four inputs, four rules, one screen, one line.
- **It gives each audience its own reason to join:** the borrow print for makers, a new commissionable line for brokers, an OCC-native book for clearing members.
- **It makes the build pay off beyond equities,** because "every later name and every later class is a product-list election."

What remains is sequencing, not design:

- MIAX has to sign, decide on the one-team option, set the Market Maker Program terms and send the briefs.
- OCC has to answer its six switches.
- Robinhood has to choose between the securities-account door AP drew and the paths it already owns.

Until then the street layer is a finished plan with no work started.

*Sources: Launch Partner Brief v2.4 (Sept 2026); Robinhood Brief (Sept 2026); Street Build memo (Sept 16, 2026); Room Update (Sept 30, 2026)*

<!-- END CHAPTER -->
