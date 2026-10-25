# X. The desk — trading intel, the terminal and the adjacent bets

The desk is where Saheb's ideas meet a price. It has three tools and a ring of adjacent bets.

The tools:

- **The Hyperbull Break List.** A market call with a date on it: 1,450 names priced to a top on 1 January 2029.
- **The terminal.** Being built in this project. It ranks perp setups by timeframe and sizes them to account rules.
- **The journal.** It measures every fill against the market's move since.

The bets trade the AI build-out from the supply side: Astrellis ("Trafigura for AI"), the S&P 500 cloud-spend screen, and zkTPU, which rolled into Cambrian, a fund that buys distressed data-center loans.

*Trader in Time* (9 October 2026) holds it together: Saheb trades time, not price. This chapter covers that frame, each tool and bet, the links to American Perpetual and Rei, and what is still missing.

## The short version {#desk-summary}

- **The frame.** "Most traders watch the price. Saheb watches how long." Every product either shortens the stretch of time nobody can check, or prices it and holds it.
- **The call.** Nasdaq-100 from about 29,600 to 65,000 by 1 January 2029: 2.2× in 26 months.
    - Each of 1,450 names is scored by what one event (its "break") would add, against what the company is worth.
    - For 1,324 names the best 8-month window is the last one: 1 May 2028 → 1 January 2029.
    - Crypto treasury companies carry a "token call": the token doubles. For bitcoin that is $86K → about $172K.
- **The terminal.** A password-gated Cloudflare Worker. Pick 1D, 3D or 1W.
    - It ranks Hyperliquid perps on a seven-part score and sizes each trade by the tightest of three limits.
    - It screens long/short pairs by order-book impact and keeps a fills journal.
- **Not yet wired.** The rules of the ChatGPT "zero-fee trenches" site and of the "Funded breakout coin leverage analysis" thread. Both sit in chats the research tools cannot reach. Until they come in, the terminal keeps the site's link parameters and runs on placeholder account rules.
- **The adjacent bets.**
    - **Astrellis** sized about $5.75B of AI-hardware value capturable in 2026: $0.58–1.15B of revenue at a 10–20% take.
    - **The cloud screen** ranks 56 companies by what a 30% cloud-bill cut would save against their value. Snap leads at about 4.8% a year.
    - **zkTPU** priced a receipt on every AI answer at about 20 bps and chose "no token". By 21 October it was the Cambrian brief, whose equity is a fund's "trading book".
- **The record.** "a $4,000 monthly salary traded to $300,000, then $150,000 of it into one project that returned $1.4 million."

> [!number] 1,450 — names on the Hyperbull Break List
> Scored to a 1 January 2029 top; 675 score 1× or more, meaning one break would at least double the company

> [!number] ~$172K — the bitcoin "token call"
> Bitcoin doubles from $86K; ether $2,745 → ~$5,490; solana $121.8 → ~$244

> [!number] $4,000 → $300,000 → $1.4M — Saheb's trading record
> Monthly salary traded to $300,000; $150,000 of it into one project that returned $1.4 million

*Sources: Trader in Time (2026-10-09); Hyperbull Break List (2026-10-19); Cambrian Brief (2026-10-21); terminal/README.md (2026-10); Astrellis session (2026-10-12); S&P 500 Cloud Spenders (2026-10-12); zkTPU verification report (2026-10-07)*

## The frame: a trader in time {#desk-frame}

*Trader in Time* is the closest thing Saheb has written to a statement of method. It is a short book in twelve chapters, dated 9 October 2026, and every pod in this treatise fits inside it. The desk is where the method becomes a P&L.

> [!quote] "Most traders watch the price. Saheb watches how long." — Trader in Time, 2026-10-09

The argument takes three sentences. "Every claim in finance has a stretch of time in which nobody can check it." "In his rooms that stretch is called risk. It has a price, and the price rises with two things: how long the stretch is, and how little can be seen inside it." "Saheb trades in that stretch. Where it can be shortened, he shortens it. Where it can't, he prices it and holds it."

The book sorts his work into four moves on time. The last column adds what each move looks like on the desk.

| Move | Product | In his words | On the desk |
|---|---|---|---|
| Price the wait | American Perpetual: a stock future with no expiry, held to the stock by hourly funding | "A contract with no end date: he prices the wait." | The terminal reads funding (the hourly payment between longs and shorts) as the price of waiting on one side |
| Shorten the wait | zkTPU / Cambrian: a receipt on every machine answer | "A receipt on every machine answer: he shortens the wait to nothing." | The journal checks each fill against the live mark |
| Sell the wait | The AP licence: a royalty on fees for years | "A license that pays over years: he sells the wait." | The fund: "money turned back into time" |
| Write the wait down | The XR language: every promise carries a check day | "A language where every promise carries a day: he writes the wait down." | The break list's dated path; Astrellis's BET, which "needs a check date, a stake and a claim" |

Four lines in the book read as desk rules.

1. **Opinions carry dates.** "'This deal loses money by March' is a bet that can be checked, and being right over time is how a person earns weight." The break list applies this at scale: every name has a value at seven dated milestones.
2. **Start tight; let the record loosen you.** "Better to be loosened by a record than tightened by a scare." The terminal's defaults sit on the same side: 5× on bitcoin and ether, 2× on the rest, and no more than 0.25% of a coin's open interest.
3. **Margin is a fee for not knowing.** "It is a fee for not knowing: the distance between the last thing you knew and the first thing you could do."
4. **Roll the name, keep the bet.** "He rolls names. The first venture was GLX. It is American Perpetual now… The names expire. The bets stay open."

The book also says what the trading is for. "He says he is no longer a founder. He is a licensor and a financier." His fund "gets him 'the life I want.' Paid professionals run it. That is the last step of the trade, money turned back into time."

One of the book's closing questions is "How does a hunch become a promise?". The desk already has a working answer. The Astrellis agent keeps a hunch board ("Never scored; the author can take one back") apart from the record. A hunch becomes a bet only once it has a check date, a stake and a claim.

> [!quote] "A trader in time is not a man with a lot of it. He is a man who can say what a stretch of it is worth." — Trader in Time, 2026-10-09

*Sources: Trader in Time (2026-10-09); Astrellis Agent (2026-10-05); terminal/src/market/signals.ts (2026-10)*

## Where the desk comes from {#desk-lineage}

The terminal is the fourth version of one tool. Each version moved closer to the funding-rate perpetual.

- **Chartpaint (13 November 2023).** "Pre-release prototype in-house proprietary trading software that we use to accumulate low cap spot altcoins." It linked eight small exchanges and showed what each would cost to move a price ("Gate: Total USD cost to bring price up by $0.03: $5,250"). It fired immediate-or-cancel orders at all of them at once.
- **Andromeda Terminal (2023–24).** "An all-in-one in house aggregator for options, perps, spot, margin, borrow/lend from one terminal frontend."
    - Its perp tools allowed "upnl rolling": adding to a position with its unrealized gains as cross margin.
    - It named Bybit and Hyperliquid as venues.
    - The March 2024 SOL letter gave the goal: "build 9 figure perpetual positions using multiple exchanges from one access point."
- **Funding Arb fund (10 November 2025).** Capital split across exchanges to collect funding-rate gaps, moved hub-and-spoke from one Arbitrum address.
- **The terminal (October 2026).** Back on Hyperliquid, but as a screen and a sizer rather than an execution engine.

Between the third and fourth versions, Saheb took the funding-rate perp itself to a regulated US exchange, first as GLX and then as American Perpetual. Chapter II-B tells the Andromeda story in full.

*Sources: chartpaint -> andromeda terminal (2023-11-13); "Sol Trade" Andromeda communiqué (2024-03-03); Funding Arb fund (2025-11-10); terminal/README.md (2026-10)*

## The Hyperbull Break List {#desk-hyperbull}

The break list is the desk's long view: a dated call on the market, and for each company, the one event that could re-rate it before the top. It was built in a Claude session the research tools cannot list. It was last updated 19 October 2026 and folds in Saheb's own screen of 77 names from 10 October.

### The call

The Nasdaq-100 goes from about 29,600 to 65,000, "Oct 19, 2026 → the Jan 1, 2029 top: 2.2× in 26 months (QQQ $719 → ~$1,580). 2027 +25%, 2028 +65%." The S&P 500 goes from about 7,700 to about 9,700 (1.26×), "if it lags the Nasdaq-100 the way it did in 1998–2000". The analog is that run: from the end of 1997 to the March 2000 peak, the Nasdaq-100 rose 4.75× and the S&P 1.57×. "This path is about 50% of that run, in doublings."

> [!quote] "Supply chains are ~7 years from secure. Years 3–4, 2029–30, are the hardest, so the top is Jan 1, 2029, and it's a strong bull again before 2034." — Hyperbull Break List, 2026-10-19

Every name is valued along the same market path:

| Milestone | Market multiple from 19 Oct 2026 |
|---|---|
| End 2026 | 1.07× |
| Mid 2027 | 1.19× |
| End 2027 | 1.34× |
| 1 May 2028 | 1.51× |
| Mid 2028 | 1.66× |
| End Sep 2028 | 1.89× |
| 1 Jan 2029 (top) | 2.20× |

Two days later the Cambrian brief makes the same call from the credit side: "2028 peak year, top Jan 1, 2029, 2029–30 hard years."

### How a name is scored

Each company gets one **break**: a specific, checkable event that would re-rate it. Two examples: "Kati 2 signs an AI tenant, filling the 350 MW Metrobloks JV." "Bitcoin doubles to ~$172K on its 4,467 BTC treasury." The **prize** is what the break adds in dollars.

> [!quote] "score: prize at max ÷ (market cap + stock it must sell), log scale · 1×: the break would double the company · under 1×: too small to matter" — Hyperbull Break List, 2026-10-19

The stock a company must sell is sold along the path at the path's own prices, so "a rising stock dilutes less". Each record carries:

- the break's sizing and a "Paper and risks" line (debt, converts, short interest)
- the next dated event
- a value at each milestone and the whole company's multiple to the top
- the best 8-month trade
- QQQ beta and a "hyperbull beta"

The page filters by region (720 US names), QQQ beta, score bucket (1×, 3×, 10×, 30×, 100×) and "Deep-checked only" (121 names).

The spread is wide. 675 names score 1× or more and 775 fall under. 38 score 10× or more. Two pass 100×, and both are muscle-and-fat-loss biotechs: VERU at 779× on a $42M cap, and IBIO at 128×. The largest groups are China AI, AI hardware, data centers, power and grid, and memory. The crypto group has 21 names.

### The best 8-month trade

This field answers a narrower question: if you could hold a name for only eight months, which eight? The page slides a start date month by month from 19 October 2026. Each window ends eight months later and never past the top. It keeps the window with the largest modeled gain per share.

The answer is nearly always the same. For **1,324 of the 1,450 names** it is **1 May 2028 → 1 January 2029**, the run into the top. For 121 it is **now → 19 June 2027**; five land elsewhere in 2028. The median best-8-month multiple is 1.93×. The median whole-company multiple to the top is 3.93×.

The 121 early windows are the list's near-term trades. Crypto-linked names among them:

- GEMI: 3.33× to June 2027, on "CFTC-cleared prediction markets scale through Apex's broker network"
- SLNH: 2.48×
- MARA: 2.15×
- BMNR: 2.08×
- ABTC: 1.72×

> [!tension] The break list puts most of the gain in the eight months before 1 January 2029; the terminal trades one-day to one-week setups. Nothing yet links the long call to the short trades.

### The crypto rows and the token call

Most of the 21 crypto names hold tokens in their treasuries. For these, the break is a **token call**: the token doubles from its mid-October 2026 price, and the prize is the treasury's gain. The sizing leaves out any NAV discount closing and holds debt fixed. NAKA's line reads: "Gain at 2×: 4,467 BTC × $86K = $0.38B."

| Name | Cap | Score | Break | Best 8 months |
|---|---|---|---|---|
| NAKA | $181M | 2.1× | 4,467 BTC; bitcoin $86K → ~$172K | May 2028 → top, 2.23× |
| XXI | $1.9B | 1.9× | ~43.6K BTC; same call | May 2028 → top, 2.07× |
| BMNR | $13B | 1.3× | 5.98M ETH; ether $2,745 → ~$5,490 | now → Jun 2027, 2.08× |
| SBET | $1.6B | 1.5× | 888,938 staked ETH | May 2028 → top, 2.15× |
| PURR | $1.8B | 1.6× | ~29.4M HYPE; doubles from its ~$97 high | May 2028 → top, 2.25× |
| DFDV | $179M | 1.7× | ~2.54M SOL; $121.8 → ~$244 | May 2028 → top, 1.92× |
| BNC | $217M | 1.8× | 515,544 BNB; $778.5 → ~$1,557 | May 2028 → top, 2.03× |
| GEMI | $463M | 9.0× | CFTC-cleared prediction markets via Apex | now → Jun 2027, 3.33× |
| SECZ | $1.7B | 11× | SEC tokenized-stock exemption; Cantor's on-chain IPOs | May 2028 → top, 2.78× |
| AMBR | $180M | 1.6× | AI-agent pivot re-rates a crypto-wealth broker | May 2028 → top, 2.05× |

The rest of the group:

- **Miners becoming AI hosts:** KEEL, BTBT, CANG and SLNH, valued at "Hut 8 15×" net operating income.
- **More token calls:** TONX, SUIG and CYPH, on TON, SUI and ZEC.

Market structure shows up just outside the group:

- **BULL (6.5×):** "Re-rated as a Robinhood-style super-app on crypto, futures and AI-agent connectors"
- **CRCL (2.8×):** USDC from $73B to about $300B
- **BLSH (1.2×):** tokenized US equities on Bullish and Equiniti

Two rows are also Rei targets. GEMI (Gemini) and AMBR are the public homes the Rei documents propose to buy or merge into (Chapter IX). The break list rates both on their own businesses. GEMI's risk line says "the twins hold 97% of votes"; the Rei documents put it at about 93%.

*Sources: Hyperbull Break List (2026-10-19; page text, crypto rows and the 1,450 embedded records); Cambrian Brief (2026-10-21); Rei — The World a $100 Billion Coin Makes (2026-10-16); notes 14–15*

## The terminal {#desk-terminal}

The terminal is the desk's short view, and it is being built in this project. It lives in `terminal/`, in the same repository as Nimbus and as the Operating Room that renders this treatise. What follows is what it does as built, from its README and source.

> [!quote] "A password-gated trading terminal on one Cloudflare Worker + D1. Pick a timeframe (1D · 3D · 1W) and it ranks perpetual-futures setups, sizes them to your account rules, and shows the intel behind each." — terminal/README.md, 2026-10

### What it shows

| Panel | Data (public APIs, cached at the edge) | What it shows |
|---|---|---|
| Setups | Hyperliquid candles, funding, open interest, max leverage; CoinGecko; Upbit and Bithumb; hourly snapshots in D1 | Long or short score by component; the breakout (when, level, move since, holding or failed); stop, 2R target, size, leverage, and which limit set the size |
| Korea flow | Upbit + Bithumb 24-hour KRW turnover; CoinGecko global volume | TokenPost-style table: Korea share, global share, Korea ÷ global, interest score |
| Leverage map | CoinGecko derivatives across venues; Hyperliquid | Perp open interest per coin, OI ÷ market cap, OI-weighted funding, volume ÷ OI |
| Zero-fee trenches · pair impact | Hyperliquid order books; Kraken Futures (optional) | Buy and sell impact in bps at your size; round trip with and without fees; every pair inside your limit |
| Journal (owner only) | Fills typed or pasted as CSV; Hyperliquid marks | Move since each fill, P&L, how long ago |

### The score

Each setup scores from −100 to +100. Seven components each score −1 to +1. Each is multiplied by its weight, the results are summed, and the total is scaled to ±100. Both sides are scored, and the better side is shown.

| Component | Weight | Input | How it scores |
|---|---|---|---|
| Breakout | 3 | A fresh close through the prior N-bar high or low (N = 20 on 1D, 10 on 3D, 8 on 1W) | Full credit if fresh and holding, fading over 8 bars; a failed break counts against. Shows "since when" and the move since |
| Momentum | 1.5 | Return over 5, 3 or 2 bars, against the ATR (average true range: the typical bar) | Smooth score in the trade's direction |
| Volume | 1 | Last bar against the median of the prior N | Confirms the breakout's direction |
| Funding | 1 | Hyperliquid's hourly rate × 24 × 365 = APR | Paying to be long counts against longs (crowding) and for shorts |
| Leverage | 1 | Perp OI across venues ÷ market cap (CoinGecko) | Under 0.5%: −0.3. 0.5–10%: +0.5 (fuel). 10–20%: 0. Above 20%: −0.6 (liquidation risk) |
| OI flow | 1 | Hourly OI snapshots over 24, 72 or 168 hours | Price up with OI up = new longs (+0.8); falling OI = covering or liquidation (−0.3) |
| Korea flow | 0.75 | Upbit + Bithumb share of KRW turnover ÷ the coin's share of global volume | Korean over-trading helps early; once the break is more than 5 bars old it becomes a fade signal at half weight |

Breakout carries 3 of the 9.25 points of weight. The terminal is a breakout screen first; the other six parts confirm or warn. In its own panel, the Korea interest score weights how over-traded a coin is in Korea against the world (50%), its share of Korean turnover (30%) and its move there (20%). Coins under ₩1 billion of turnover are dropped.

> [!number] 3 of 9.25 — breakout's share of the score's weight
> A fresh close through the prior 20 / 10 / 8-bar high or low on 1D / 3D / 1W

### Sizing

The size is the **smallest of three limits**, and the plan names which one set it:

1. **Risk ÷ stop distance.** The stop is 1.5 ATR by default, and never tighter than 0.5%.
2. **Equity × leverage cap.** Bitcoin and ether get one cap, everything else another. The README says to "set them to your funded-account rules": the funded (Breakout) account. Each cap also stays under the venue's maximum leverage.
3. **A share of total perp open interest,** 0.25% by default, so no position becomes a large part of its own market.

The target is twice the stop (2R). The defaults are placeholders: $100,000 of equity, $1,000 of risk per trade, 5× on majors and 2× on alts.

> [!number] 0.25% — the most of a coin's total perp open interest one position may take
> The third limit, beside risk ÷ stop and equity × leverage cap

### Zero-fee trenches: the pair-impact screen

This panel keeps the name and link parameters of a site Saheb built in ChatGPT, so a link reproduces the same view: `tf=1d|3d|1w`, `excluded=KAITO,PENGU`, `universe=30`, `pairImpact=1`, `pairImpactBps=20`, `pairSize=25000`, `kraken=0|1`.

It walks Hyperliquid's order books to price a $25,000 buy and a $25,000 sell in bps for each coin, showing the round trip with and without Hyperliquid's 4.5 bps taker fee per side. It then lists every long-one / short-another pair whose combined impact fits under 20 bps (the default). Coins in `excluded` are skipped. With `kraken=1` it adds each coin's Kraken Futures spread.

### The journal, limits and sharing

- **The journal** takes fills by hand or as pasted CSV (time, coin, side, price, size, leverage, account, note). It prices each against Hyperliquid's live mark: move since the fill, unrealized P&L, how long ago. *Trader in Time* has the line for it: "A receipt is a gap closed."
- **Limits.** The free Workers plan allows 50 outbound calls per request, which caps the board at 36 coins. The $5-a-month plan lifts that. Binance is not a direct source, because its futures API refuses US-hosted requests; its open interest and funding arrive through CoinGecko.
- **History.** OI flow scores only once hourly snapshots exist: a day for 1D, three days for 3D, a week for 1W.
- **Sharing.** A share link opens the market panels read-only, never the journal, and can be turned off.

### What is not yet wired

Two sources the terminal was meant to follow are still outside it.

1. **The original zero-fee-trenches site** was built in ChatGPT. The terminal reproduces its link parameters, not its rules: what counts as a tradable pair, which coins it excluded and why, and how it used Kraken.
2. **The "Funded breakout coin leverage analysis" thread** is a claude.ai chat, like the PRIME chats Rei's brief cites, and the session tools cannot reach it. The research sweep found nothing in reach on funded accounts, breakout coins, fills or leverage on specific coin trades. So the funded account's real limits are not in the terminal.

> [!tension] The README says to set the leverage caps "to your funded-account rules", but those rules live in a chat outside the record; until they are imported, every size the terminal prints rests on placeholders.

*Sources: terminal/README.md (2026-10); terminal/src/market/signals.ts, api.ts, journal.ts (2026-10); Trader in Time (2026-10-09); notes 14 ("Funded breakout / leverage trades": nothing found)*

## The adjacent bets {#desk-adjacent}

Four bets sit around the desk. None of them is a trade on a screen. Each prices a gap in the AI build-out:

- hardware in the wrong place (Astrellis)
- cloud bills that are too big (the cloud screen)
- answers nobody can check (zkTPU)
- data centers stopped half-built (Cambrian)

Two app builds and some kept research sit beside them.

### Astrellis: "Trafigura for AI"

Astrellis ran from 4 to 12 October 2026 as a "logistics terminal for AI supply chain". It produced two artifacts and an arbitrage study.

- **The Bottleneck Radar (5 October)** rates 13 AI-hardware segments and lists 153 sourced suppliers.
    - Critical: HBM, optical transceivers, ABF substrates, server DRAM and enterprise SSDs.
    - Tight: seven more, from accelerators to power. Liquid cooling is on watch.
    - The header counts differently ("4 critical · 3 tight · 2 watch · 1 flowing"), so the page disagrees with itself.
    - Its suppliers "are leads, not counterparties: the Astrellis agent trades only with sellers that run their own agent on Astrellis."
- **The Astrellis Agent (5 October)** is a buyer's agent on a marketplace of agents. "Astrellis sizes up the bottleneck, scouts suppliers, negotiates with seller agents and asks you before any deal."
    - Its deal machinery: sealed quotes, escrow funded at approval, export-class screening with a look-through to each buyer's parent, and seller standing scores.
    - It flags trouble ("Pearl Delta's price is too clean for this market"), and a person approves every deal.
    - Its record is in XR: "what is settled and what is promised, oldest first", with BET, SETTLE ("Mistakes are settled, never erased") and a hunch board.
    - Demo prices are illustrative, e.g. a 12-high HBM3E stack at $655–738.
- **The arbitrage study (12 October)** started from Saheb's question: "if the ai infra build market was perfectly efficient… every buyer/seller perfectly matched and a 20% take for doing it. right now only." Then: "dont say reachable revenue, how much is capturable this year alone."

> [!quote] "so trafigura for ai" — Saheb, Astrellis session, 2026-10-12

| 2026 only | Base | Range |
|---|---|---|
| Lawful price gap | $4.25B | $0.9–14B |
| Speed: stock on hand matched to waiting sites | ~$1.5B | $0.5–3B |
| **Value open to capture** | **~$5.75B** | $1.4–17B |
| Revenue at a 10–20% take | $0.58–1.15B | $0.14–3.4B |

At a 20% take the business makes:

- $1.15B of revenue at a 60% gross margin
- $0.42B of EBITDA (37%)
- $0.32B of net income, which is 1.2% of the money moved: "about Trafigura's level"

Break-even is a take of about 13%; at 10% it loses money.

The study checked 525 claims. Of 118 key ones re-checked live, 51 were confirmed, 20 corrected, 47 not findable and none wrong. The report (`docs/ARBITRAGE.md`) was committed but never pushed, because the repository was public.

Its shape is an exchange's: a take on matched volume, like American Perpetual's share of MIAX's fees.

> [!number] ~$5.75B — AI-hardware value capturable in 2026 by perfect matching
> $0.58–1.15B of revenue at a 10–20% take; break-even near a 13% take

### The S&P 500 cloud-spend screen

On 12 October Saheb asked for "the stocks by the biggest cloud spend, and the latest news on how much cloud spend can be reduced with frontier ai". Then: "estimate the 30% reduction in cloud costs how much that saves" and "now add a savings/mcap". "Aragon" was his word for Google's new model. The page reports it as Gemini 4 Argon, announced 30 September, scoring 77.9% on DeepSWE against 74.2% for Claude Opus 5.5 and 74.1% for GPT-6 Astra.

The artifact ranks 56 companies by the cloud spend in their own SEC filings. Together they spend about $54B a year, so a 30% cut saves about $16B. What moves a stock is the saving against its value:

- **Snap:** about $1.7B a year, so $510M saved, about **4.8% of its ~$11B value, every year**.
- **Elastic, Appian, Lyft and UiPath:** 0.7–0.9% each.
- **Meta:** $30.6B of spend, but about 0.5% of $1.9T.

The page doubts its own premise. Flexera puts wasted cloud spend at 29%, "so ~30% is close to the ceiling, not a typical result", and savings arrive only as contracts renew. The session ended with a note to rerun it "with sec.gov allowed".

### zkTPU → Cambrian: compute as a priced asset

*Trader in Time* records the idea: "On a Wednesday this month he wrote down the idea: a check built into the chip itself, so that every token it produces comes with a receipt." Then: "A clearinghouse for answers."

The zkTPU report (Wednesday 7 October) turns it into a decision paper. Its design:

- a sealed pool shared by several labs
- a 348-byte receipt on every request
- an hourly "tick" proof that folds the hour's receipts into one

The name Cambrian is already on its first line: "Cambrian (working name) is a chip, and the software around it, that proves what a model did."

The fee is built like a clearinghouse's: "Three meters, and the proof is the meter."

| Meter | Price | Why |
|---|---|---|
| Verifier and receipts | $25 per inference GPU per month | About 1% of a GPU's rent; a per-token fee would shrink as token prices fall about 10× a year |
| Real proofs | $5 per proof | About three times GPU cost today |
| Warrant opening | $5,000 flat | "so no one earns more by opening more" |
| Standard dues | $25,000 a year per member | Wi-Fi Alliance and USB-IF levels |

> [!number] ~20 bps — zkTPU's fee said as a tax on tokens
> Against the regulator's 0.65 bps: $200M a year on $100B of covered revenue, not $6.5M

For the desk, the key page treats compute as a commodity:

- **Index prices.** On 6 October Silicon Data's H100 index was $2.82 per GPU-hour and Ornn's B200 index was $7.56.
- **Futures.** CME planned futures on those indices for 5 October, "subject to regulatory review", and the report found no sign they launched. Kalshi's compute futures had $4.4M of notional by 27 July.

"A credit denominated in GPU-hours therefore needs a named reference index." That is a market forming.

The report also dropped its token: "one public company, no token". Its reason: "token networks earn far less than they emit". In Q1 2026 Akash leased 84 of 334 GPUs.

*Trader in Time*, two days after the report, records the roll: "By Thursday it was a computer, by Thursday night a company, and by Friday a fund." The 21 October Cambrian brief has three parts: Sites, Compute (its own C1 computer), and "Cambrian (the fund) — Its trading book and the loans it buys". Its "Best stack" tab sets out the trade:

- **Enter through the debt.** "Buy the site's debt, keep the building, build the computer, sell the tokens." Targets include:
    - CoreWeave's 2032 notes near 78 cents
    - Project Jupiter's $18B loan at 89–91 cents
    - Poolin's Texas mining sites, in Chapter 11 with a $52M opening bid
- **The equity is the trading book.** The equity line is "Cambrian's trading book, plus a chip vendor's credit guarantee for site one."
- **Time is the profit.** Per MW:
    - buying the building 20–40% off is worth $3–6M, once
    - going live a year sooner is worth $14–18M of operating profit, every year
    - owning the computer instead of buying Nvidia's is worth about $25M each time machines are bought

"So buy sites for their power and permits, which is time, and make the margin on the box." That is *Trader in Time* applied to steel and power. The FEL-8 chip and Black Cube computer (22 September) were earlier drafts of the box, with the licensor's rule written on them: "Design everything, build nothing."

### Surfaces, and research kept on file

Two app builds use the terminal's pattern: a small Cloudflare Worker behind an invite or a password.

- **Unsaid (4 October)** was a two-person iMessage AI beta. Its backend put "XR in the model prompt".
- **Nimbus (15–16 October)** is the working app: iOS with a Messages extension, a Worker with invite codes, and 200 answers per person per day. It is the prototype of "Rei inside iMessage" (Chapter IX), and it shares this repository with the terminal.

Saheb also kept a copy of a public "Chip Chokepoint Breakers" map (14 October). It lists eleven chipmaking steps controlled "by one company, a handful of firms or one region", among them Ajinomoto's build-up film, used in more than 95% of CPU and GPU substrates, with a 30% price rise from Q3 2026. The break list's HBM-packaging and chip-tool themes (63 and 50 names) cover the same ground.

*Sources: Astrellis Bottleneck Radar (2026-10-05); Astrellis Agent (2026-10-05); Astrellis session (2026-10-04 → 10-12); S&P 500 Cloud Spenders and session (2026-10-12); zkTPU verification report (2026-10-07); Cambrian Brief, tabs Brief and Best stack (2026-10-21); FEL-8 Chip and Black Cube Computer (2026-09-22); Unsaid Build Dashboard (2026-10-04); Nimbus session (2026-10-15/16); Chip Chokepoint Breakers (Copy) (2026-10-15); Trader in Time (2026-10-09)*

## How the desk ties into the other pods {#desk-links}

The desk trades the mechanism American Perpetual lists. It is written into Rei's launch, and it is the equity under Cambrian.

**American Perpetual.** The terminal's funding input is the mechanism AP takes to regulated US stocks: an hourly payment that ties the perp to the stock. AP's Final Check shows how a thin market bends that payment.

> [!quote] "At 2 a.m., with the contract quoted 178.00–182.00 and the stock's midpoint at 180.00, one 1-lot at 181.90 holds the Mark at 181.90 … a 1.06% premium and … a rate of about 0.044% for the hour, ten times the room's worked example, paid on all open interest." — AP Data Room Final Check, 2026-09-25

The fix it proposes is quality gates on both funding inputs. The venues also overlap: Payward, Kraken's parent, filed for stock perps through Bitnomial on 18 September, and Kraken Futures is the terminal's optional second book.

**The IP line.** The June version of the AP IP assignment kept a trading app and trading strategies outside it. The September execution form sweeps in all pre-formation perpetual work (counsel flag F-41). The terminal and the desk's strategies sit on that line.

**Rei.** The Rei documents give the equity co (the operating company) a market-making desk on the XR/USD book:

- 5% of the one sale's dollars fund it
- it starts only after the sale closes
- its XR is capped at 0.5% of supply

The 30-day simulation ends with "Saheb's 0.15, lent to the desk, at 0.9%." The Cookbook's quant API offers "one on-chain order book and one API; XR spot, perps, stock perps and options at MIAX through Dorman". The agent can "hedge half my XR with the perp" but does not pick trades, because picking them would make the company a commodity trading adviser.

**Cambrian.** The fund's trading book is the equity of the data-center plan, and the brief shares the break list's date for the top.

> [!tension] Three books are each called the desk: Saheb's funded account, Cambrian's trading book and Rei's market-making desk after the sale. Who owns which strategy, and under which IP, is not written down.

*Sources: AP Data Room — Final Check (2026-09-25); AP IP Assignment, June version and execution form (2026-09-28); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei — The Cookbook (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Cambrian Brief (2026-10-21)*

## Open questions {#desk-open}

1. **What are the zero-fee trenches rules?** What did "zero-fee" mean on that site, at which venue and fee tier, and why were coins excluded?
2. **What are the funded account's rules?** Leverage by asset class, risk per trade, and any loss or drawdown limits. Until they are imported, every size is a placeholder.
3. **Should the long call steer the short trades?** The break list puts most of the gain in May 2028 → January 2029. The terminal could lean long or cut leverage as that window nears, or ignore it.
4. **Which book trades?** The personal funded account, Cambrian's fund or Rei's equity-co desk. Each has its own owners, its own rules, and its own side of the AP IP line.
5. **Are the token calls levels to trade or only a way to size treasury companies?** They double mid-October prices: bitcoin $86K, ether $2,745, solana $121.8.
6. **Is compute, or the Astrellis gap, a desk trade or a company?** GPU-hour indices and planned futures exist. The Astrellis gap is sized at ~$5.75B with a 13% break-even take. Neither has a book yet.

*Sources: terminal/README.md (2026-10); Hyperbull Break List (2026-10-19); zkTPU verification report (2026-10-07); Astrellis session (2026-10-12); notes 14–15*

## What the desk needs next {#desk-next}

- [ ] **Bring in the zero-fee trenches site.** Save the ChatGPT page (rules, excluded list, venue and fee assumptions) to Drive, then match the pair-impact panel to it, keeping the link parameters.
- [ ] **Bring in the "Funded breakout coin leverage analysis" thread.** Export it to Drive with the harvest prompt, then write its limits into the terminal's Rules: equity, risk per trade, the caps for majors and for alts, and any loss or drawdown limits.
- [ ] **Retire the placeholder account rules.** The defaults ($100,000; $1,000 of risk; 5× / 2×; 0.25% of OI) should not size a real order.
- [ ] **Deploy and let history build.** Apply the D1 migrations and add the CoinGecko demo key. OI flow needs 24, 72 or 168 hours of snapshots before it scores.
- [ ] **Choose the plan tier.** Free Workers caps the board at 36 coins; the $5-a-month plan lifts that.
- [x] **Fix the breakout score's over-extension haircut.** The check ran on a value already clamped to ±1, so it never fired. Fixed: a breakout more than 3 ATRs past its level now keeps 70% of its weight (with a test).
- [ ] **Load past fills into the journal** as CSV, so the desk starts from a measured record.
- [ ] **Decide how the break list feeds the terminal.** Either as a regime input (the dated market path) or not at all, with the reason written down.
- [ ] **Refresh the break list's prices** before acting on any row. They date from mid-October, and some are marked stale.
- [ ] **Name the book.** Write down which strategies belong to Saheb, to Cambrian's fund and to Rei's equity co. Check each against the AP IP assignment (flag F-41) before AP signs.
- [ ] **Finish the Astrellis report.** Make the Rhino repository private, then push `docs/ARBITRAGE.md` (pending since 12 October), or drop it.
- [ ] **Rerun the cloud screen with sec.gov allowed,** and replace derived and estimated rows with filed numbers.
- [ ] **Keep the Cambrian dates:**
    - name clearance by 11 November 2026 ("Cambrian is close to Cambricon")
    - three labs sign intent by 6 January 2027
    - the 35% chip-plant credit covers only construction started by 31 December 2026

*Sources: terminal/README.md and source (2026-10); Hyperbull Break List (2026-10-19); Astrellis session (2026-10-12); Cloud-spend session (2026-10-12); zkTPU verification report (2026-10-07); Cambrian Brief, Best stack (2026-10-21); notes 10, 14–15*

<!-- END CHAPTER -->
