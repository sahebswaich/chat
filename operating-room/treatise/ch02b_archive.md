# II-B. The deeper archive — REAL, Operation 100b and the master plans

A sweep of Saheb's Drive found 539 files that the first readings missed. About 180 of them sat in one old "big ideas" folder. Most are short: a page of rules, a trade written as a parlay, a week-by-week plan. Read together, they change the picture in four places. A unifying coin called **REAL** runs from 2022 to 2025, before Rei. The first written line about **perpetuals on stocks** is dated March 2023, 32 months before Greyline. Two **master plans** from 2022 set the order in which everything else was meant to happen. And the **Greyline** name first belonged to a royalty idea, not an exchange. This chapter covers those finds, the fund and trading papers behind Andromeda, the on-chain build of Manifest, the airdrop operations, and the secrets that are still sitting in Drive.

## The short version {#archive-summary}

- **REAL is the missing coin.** "Real" is the endgame in the August 2022 Olympus plan; in June 2023 "Stable coin is algorithmic REAL"; in June 2025, with James Piazza, it becomes a zk Layer 1 with one $REAL token for every app, plus a Solana token paying 5–15% from real-world assets. Rei (Chapter IX) keeps REAL's "one login, one token" and reverses its economics.
- **Stock perps start in 2023.** *Operation 100b* (2023-03-23) ends: "Trading Strategy: Perpetuals on Stocks, Cheaper than Options on Stocks for the same amount of leverage."
- **The token rules are written down.** *Market* (2023-03-29): a $40 target price, a split above $500, and "The initial property sale is the token sale."
- **The plans set the order.** *Olympus plan* (2022-08-19) buys out Olympus DAO for $25m and ends in "Real". *Personal* (2022-10-04) puts a blockchain-and-OS company first, a capital-management firm alongside it, and $100B by 2031.
- **Andromeda has a paper trail.** A binary put-spread fund, a US-to-BVI structure, an AND fund token whose supply changes three times, a $20M offering memorandum, a trading terminal and tokens for single strategies (2023–2024).
- **Greyline began as royalty strips.** *Grayline* (2025-09-26) lists a dividend strip on an Argentine lithium stake and a royalty strip on Guyana's Stabroek oil block. The first MIAX approach was about index perps (Progress Document, 2025-12-02).
- **Secrets are exposed.** One farming spreadsheet holds 11 wallet seed phrases and private keys in plain text. Treat those wallets as compromised.

> [!number] 32 months — from "Perpetuals on Stocks" (23 Mar 2023) to the first Greyline plan (23 Nov 2025)

> [!number] $45M–$200M at $120M–$600M — the REAL raise target (June 2025)
> Tokenomics 30% investors / 50% company / 20% floated.

> [!number] 11 — wallet seed phrases and private keys stored in plain text in one sheet
> Move any remaining funds and retire the keys.

*Sources: notes 13 (gap sweep) and 16 (gap follow-up); Operation 100b (2023-03-23); Market (2023-03-29); Olympus plan (2022-08-19); Personal (2022-10-04); Real Deck (2025-06-23); Real Frontend Document (2025-06-06); Grayline (2025-09-26); Progress Document (2025-12-02); Airdrop Farming for Rainbow Wallet sheet (2023-12-16)*

## REAL: the unifying coin before Rei {#archive-real}

REAL is the strongest "one coin for everything" design written before October 2026. It appears in five forms over three years. The name stays; the chain, the backing and what the holder gets all change.

### Every version side by side

| Date | Document | What REAL is | Chain | What the holder gets |
|---|---|---|---|---|
| 2022-08-19 | Olympus plan | The endgame vehicle: "taking Flow to Real", "acquiring for Real" | Not stated | Not stated |
| 2023-06-15 | What can be done now? | "Stable coin is algorithmic REAL", inside a crypto/AI/MR device stack | Not stated | A stable unit of account |
| 2025-02-12 | Map of Apps | Chat-app gifts convert "to REAL currency" | Not stated | Spendable currency |
| 2025-06-06 | Real Yield Plan | SPL REAL staked for yield | Solana ("Layer 2 RWA Staking App") | 5–15% REAL yield; RWA income buys back REAL |
| 2025-06-23 | Real Deck / Real Spec | "A single zk-backed token that settles ownership, revenue, and identity across all apps" | Own zk Layer 1, no consensus | "Earns a share of revenue"; treasury-backed |

### 2022–2023: a name before a design

In the Olympus plan "Real" is a destination, not a token spec: "Le Real launch keep enough to force the vote and take over turning to a real app." Wholesome OnlyFans is to "Launch on Real", and Manifest News is to list "companies to acquire for Real".

The June 2023 note is headed "THIEL FELLOWSHIP". It asks "What can I build to sell now?" and lists AI apps, crypto apps, a smartphone with its own OS and "Ledger x Smartphone".

> [!quote] "Stable coin is algorithmic REAL" — What can be done now?, 2023-06-15

An algorithmic stablecoin holds its peg by rules for minting and burning rather than by reserves. The note gives no mechanism. It is the earliest place REAL is a currency.

Two identity notes fill the gap between 2023 and 2025. *Login system* (2023-08-25) wants one name per soulbound wallet: "A zero knowledge proof blockchain account is tied to a name which is tied to your one identity across the entire ecosystem, no more email." *Multiplayer web* (2024-04-06) has users "traverse the cryptoeconomy together" on one OS identity, "eventually expanding to experiences such as Rifts, content consumption, games, markets." Both prefigure REAL's handles.

### June 2025: the zk Layer 1 with James Piazza

James Piazza owns the deck, the spec and the Space spec. Saheb owns the practice spec, the 1Real page and the USDC roadmap; the Yield Plan sits in his iCloud-linked account. Piazza first appears in the Drive in May 2024. The deck opens with the problem:

> [!quote] "Thousands of computers shouldn't need to agree for me to send money." — Real Deck (with James Piazza), 2025-06-23

The design replaces consensus with a proof. A zero-knowledge proof (zk proof) lets anyone check that a computation was done correctly without redoing it.

- **Coordinator.** One central coordinator orders transactions, executes them and serves the data: sequencer, prover and data host in one.
- **Accounts.** Users log in with a username and password; handles map to public keys; transactions carry Ed25519 signatures.
- **Execution.** Contract logic runs in a RISC Zero zkVM (a virtual machine whose runs can be proved) over a sparse Merkle tree of balances.
- **Proof and sync.** Each batch yields a recursive zk proof and a new state root, anchored to an on-chain "Smart Chain Contract". A client downloads "a 50KB zk-proof" and verifies locally: "No nodes. No reorgs. No history sync."

The business model is two lines. REAL earns "Small fees on app transactions" and "Username/handle sales". The token: "One token: $REAL / Used across all apps / Earns a share of revenue / Backed by a protocol treasury … Revenue flows to $REAL".

> [!quote] "Every internet product will eventually issue a coin. Every coin will represent usage, revenue, and ownership. But fragmentation kills utility. Real is the chain that unifies them." — Real Deck (with James Piazza), 2025-06-23

The roadmap: v0.1 spec complete, then a devnet, a username marketplace app and a public zk explorer, with a launch target of Q1 2026. *practice real spec* (2025-06-17) gives the raise path: a pitch deck and seed in mid-June; a demo L1 and web-app OS in July–August; a Series A in September–October; "prop-tech apps, and crypto wechat in America" in November; a final round in December; "Jan-Feb launch the token + handle marketplace".

### The Real Yield Plan: SPL REAL

The Yield Plan is a different product with the same name: a "Solana Layer 2 RWA Staking App". SPL is Solana's token standard; RWA means real-world assets.

- **Product.** "Stake SPL REAL → earn 5–15% REAL yield", with a fixed 7.9% option. The interface is black and white, "modeled after Squads". A separate page names the site realsolana.app.
- **Assets.** "Buy high-yield, state-backed securities (e.g. Kazatomprom, FNMA)".
- **Mechanism.** "Yield from RWAs buys back REAL on market / MM contracts support token price / Maintain supply control for sustainable APY". MM contracts are agreements with market makers.
- **Raise.** "$45M–$200M at $120M–$600M valuation", run by "Competence" and "structured like Circle Ltd.", with the note "Circle IPO, Galaxy preparing to go public — timing favorable".
- **Tokenomics (provisional).** 30% initial investors, 50% retained by the company, 20% "Floated via DLMM" (a dynamic liquidity pool on Solana). Two advisers, named by social handle, are to finalize it.
- **Goal.** "Top 5 RWA token on Solana".

### The payments front end: 1Real, Space and USDC Pay

Three specs from June–October 2025 put a dollar account in front of REAL.

- **1Real** (2025-06-24): "1Real is your USDC spending layer — a mobile passport that holds your balance and plugs directly into apps like Uber." Apps pull payments through 1Real; the backend is the Real zkL1. The go-to-market is "Do Things That Don't Scale": one-by-one app integrations, then an open-source SDK.
- **Space** (2025-06-26): "Space - Spend USDC Globally". An internal USDC ledger, a dollar float at Column Bank, and merchant payouts by RTP (the US instant-payment network) through Column's API.
- **USDC App** (2025-07-28; a near-copy on 2025-10-29): KYC and a virtual Visa through Bridge; a USDC checking balance and a savings balance earning yield on Morpho Blue through Fireblocks; BTC turned into cbBTC and posted on Aave to borrow USDC; swaps through Odos; tax forms through Taxbit. **Fees: 0.15%** on moves from savings to checking and on the amount borrowed. The pitch angle is "CeDeFi" and "becoming a easy acquisition". The roadmap (2025-07-23) ends at Series B with "marketing to be acquired".
- **Outreach** (2025-07-07): seed emails for "USDC Pay" ("RTP to settle USD to merchants in under two minutes") to seven named partners at Lightspeed, Menlo, Greylock, Opus, DFJ Growth, IVP and Race. Every line is marked "[Messaged: ❌]".

Chapter II asks whether *StableStation* (August 2025) descends from these files (see [Chapter II](#origins-stable)). The archive supports it: Space and the USDC App come one to two months earlier and use the same RTP rail and a similar under-two-minutes promise.

### REAL against Rei

Rei (October 2026) is covered in [Chapter IX](#rei-summary). The comparison shows what Saheb kept and what he reversed.

| Question | REAL zk L1 (Jun 2025) | SPL REAL (Jun 2025) | Rei / XR (Oct 2026) |
|---|---|---|---|
| What unifies | "one login, one token, one global state" | Not a unifier; a yield token | "one balance, one handle, one agent" |
| Chain | Own zk L1; one coordinator; 50KB proof | Solana SPL | First "a chain that isn't a chain"; then an Arbitrum Nitro rollup |
| Value to holder | "Earns a share of revenue"; treasury-backed | 5–15% yield; RWA income buys back REAL | "no yield, revenue share, buybacks or burn" |
| Handles | Handle sales are revenue | — | "Every handle is a coin" |
| Supply and split | Not stated | 30 investors / 50 company / 20 float | Prime steps; 31 sale / 50 Foundation / 19 equity co |
| Raise | Seed → Series A → token in Jan–Feb 2026 | $45M–$200M | One sale, $81M–$727M |
| Launch target | Q1 2026 | Not dated | 1 November 2027 (proposed) |

Three things carry over: one token across every app, handles as a product, and a zk proof as the source of trust. One thing is reversed: REAL pays its holders and Rei forbids it. Chapter IX gives the reason: the March 2026 SEC/CFTC interpretation treats a token as a digital commodity only if it carries no rights "such as generating a passive yield." The 50% block also changes owner, from "Retained by Company" in REAL to the Foundation in Rei.

> [!tension] REAL is described as a stablecoin (2023), a revenue-sharing L1 token (2025) and a yield-bearing Solana token (2025) — three legal categories under one name. Rei's ban on yield and buybacks reads as the answer to the 2025 design.

> [!tension] No REAL document from 2025 mentions the 2022 Olympus plan or the 2023 note. The thread is visible only when the files are read together; whether Saheb meant it as one coin is unconfirmed.

*Sources: Olympus plan (2022-08-19); What can be done now? (2023-06-15); Login system (2023-08-25); Untitled "Multiplayer web" (2024-04-06); Map of Apps (2025-02-12); Real Frontend Document / Real Yield Plan (2025-06-06); Real frontapp page (2025-06-14); practice real spec (2025-06-17); Real Deck (2025-06-23); Real Spec (2025-06-24); 1Real Frontend App (2025-06-24); Space Spec (2025-06-26); VC Emails (2025-07-07); USDC App Roadmap (2025-07-23); USDC App (2025-07-28); USDC App Spec (2025-10-29); Rei chapter (Oct 2026)*

## The token rules: "Market" and "Ideas" (2023) {#archive-market}

*Market* (2023-03-29) is the most direct statement of how Saheb wanted tokens to behave. It was written the same day as his real-estate empire study (see [Chapter II](#origins-empire)) and turns that study into a sale model.

**Scale first.** "#1 spot on the leaderboard requires $220b. If you must win, you must win by a landslide. Everyone must compete for THE SECOND SPOT." The note sizes the field at "5t is the operating space. 25t is the global tech space … 30000 b is total."

**How a token should look.**

> [!quote] "I prefer tokens with low circulation, short vesting, and targeting a price point of $40 so they seem like respectable investments." — Market, 2023-03-29

Stocks, it notes, "float 25-45% the rest are held by insiders." Tokens should act like shares: "Tokens can reverse split, and split. Tokens can issue bonds. Everytime the chart exceeds $500 it should split." The one exception is "a special investment stock like BRKA".

**Real estate as the token sale.** "Example: buy real estate, get airdropped tokens alongside with the purchase."

> [!quote] "The initial property sale is the token sale." — Market, 2023-03-29

Two valuation rules follow:

| Rule | Example in the note |
|---|---|
| "Investing 60m into a project (real estate) nets 300m minimum token valuation." | $60m of property → $300m token valuation (5×) |
| "Raising money increases the valuation x3 the amount that you raise." | Raise $350m: "60m -> 300m + 350m * 3 -> almost 2b" |

"All projects should conduct peak hype raises." The note ends on a fund: "it's a tokenized crypto venture capital / capital management firm for the long term, it appreciates only. WABAM ANOTHER COMPANY".

**How it fits the other rules.** The $40 target matches the August 2023 rule of thumb in Chapter II ("100m tokens at 40 … go to 400"). The split above $500 is the "feel like a stock" idea that Rei later abandons (see [Chapter IX](#rei-lineage)). *2028* (2023-06-13) runs the same loop on equity: "Sell the houses to the company at the premium price of real estate for profit. Sell the stock to large institutional buyers … until you are actually short your own company."

**Crypto as equity.** *Ideas* (2023-09-08) states the general case:

> [!quote] "the new internet companies will go public on the internet. Crypto will serve as the primary equity source for the new internet brands and companies and organizations." — Ideas, 2023-09-08

"1 Liquidity event isn't good enough, but a 100 in quick succession during a bull will take you there. As long as you own a huge undisputable chunk."

**The 2025 version.** *Map of Apps* (2025-02-12, Piazza) applies the rule to "whale apps" that own their assets. Homer is "Airbnb but if airbnb owned all the properties and instead of individual hosts, people just buy the token for revenue". Cartel is Turo owning its cars and paying revenue as an "airdrop" ("rebranded term of dividend") the moment a payment lands. The same sheet lists "Andromeda — US derivatives exchange for crypto, one main options market crypto native, high lev futures in us."

> [!tension] *Market* calls a tokenized fund one that "appreciates only". The fund Saheb drafted three weeks later was "a binary fund designed to make a return of 20:1 or lose all of the invested capital".

*Sources: Market (2023-03-29); How to build a real estate crypto empire in the world. (2023-03-29); 2028 (2023-06-13); Ideas (2023-09-08); Map of Apps (2025-02-12); Tentative Investor Agreement.pdf (2023-04-20)*

## Operation 100b and the trading books (2022 → 2024) {#archive-operation-100b}

Before any exchange design, Saheb wrote trades as parlays: a chain of option bets, each paying a multiple that funds the next. Two later ideas start here: leverage should be cheap, and a contract should be easy to transfer and safe from a failing counterparty.

### The books

A put debit spread buys one put and sells a lower one. It pays at most the gap between the strikes, so it is a cheap, capped bet on a fall. A call spread is the same bet on a rise.

| Date | Book | Size | Structure | Stated payoff |
|---|---|---|---|---|
| 2022-10-29 | ETH Trade ("Master Capital") | $500k → $2.5m → $12.5m | ETH put spreads on Deribit (1450/1350, 1400/1300, then 1100/1000), then a 13× ETH perp short | "$62.5m end", 125× |
| 2023-03-23 | Operation 100b | "$10,000,000 in a Gnosis" | 25,000 ETH 1200/600 put spreads; BTC call spreads 60/70k, 90/100k, 120/130k | "3750x capital"; notional "well over 100b" |
| 2023-08-18 | The "Impossible" Task | Small, then $10m | Option parlays on Bybit × Greeks.Live and BIT.COM; Kraken as broker past $10m | A $100M net worth "in a few short months" |
| 2024-03-20 | ETH Trade 7200 | "200-300m worth" in the last leg | Three ETH call spreads: 3700/3800, 4800/4900, 5600/6000 | 5× per leg; "netting a return in the billions" |
| 2024-02-27 | Trade Idea 2.27 | ~$50k | Snipe a GPU-cloud coin launch (~$450k liquidity) | 3–5×; returns split 50/50 |

**Master Capital (October 2022).** The doc is "Binary Payout 0 or 1": a 20:1 payout with "30% odds it works". Saheb executes for 50% of profits. "Impossible to get liquidity on crypto options above 10m", so the third leg moves to a perp. "3 5:1 payout trades, is an 125x of initial capital at 62.5m … a sports bet parlay." It needs an LLC and institutional Deribit and Paradigm accounts. The doc is signed "Under Promised, Over Delivered. Master Capital".

**Operation 100b (March 2023).** The leverage arithmetic comes first: "getting 1 contract of 1 eth for $5 means you get 300x leverage if eth is $1500." The ETH short targets a fall from a $212B to an $84B market cap, 1200 to 600: "25,000 1200/600 Sep 24's for $20 means you get $375,000,000 worth for $5,000,000", or "$1,250,000" at $5 a contract (30× and 120× on the 600 maximum payout). Counterparties: Kraken, Gemini, Coinbase, QCP. "The Great Long, BTC" ladders call spreads to 150k. The rest goes to an "ETH perp 8888" and on-chain alts, ETH and NFTs. Three terms are required of the counterparty:

1. **Transferability**: "ability to transfer the option contracts to a third party at whatever price I desire … buy for $5, and sell for $20."
2. **Counterparty solvency**: "Pay as you go payment plan in the event they cannot pay me due to solvency issues, shares of Kraken etc."
3. **Instant settle**: negotiate an early close-out with Kraken if it may not pay in full.

Brand lines: "XToInfinity.com" and "Andromeda". Fees: "3% paid monthly over the fund existence … & 30% (profits)". The doc quotes a line about ISDA agreements (the master contract for over-the-counter derivatives), "Trying to be a high stakes trader without an ISDA agreement is like trying to win the Indy 500 riding a llama", and answers: "They haven't heard about decentralized perp exchanges hue hue hue". Then the last line:

> [!quote] "Trading Strategy: Perpetuals on Stocks, Cheaper than Options on Stocks for the same amount of leverage." — Operation 100b, 2023-03-23

This is the earliest dated mention of stock perpetuals in the Drive. Read with what came later, the three counterparty terms are what an exchange-listed, centrally cleared contract provides by default. A cleared perp can be sold to anyone, and the clearinghouse stands behind the payout. AP's design rests on both (see [Chapter IV](#ap-occ)).

**The "Impossible" Task (August 2023)** asks: "Can someone with limited connections reach a 100,000,000m net worth in a few short months?" Its answer is a "Crypto Options Parlay", then Kraken as broker once the account reaches $10m. **ETH Trade 7200 (March 2024)** derives its last leg from BTC at 82,000–105,000 times ETH/BTC at 0.067 (ETH 5,500–7,000): "This is a once in a decade type of trade … this is a mission."

### The smaller sheets

- **April 1st Trade Ideas** (2024-04-01): $MOG perps on OX.Fun with MOG as collateral; Photon sniping; and an expected-value formula for Blast vaults, EV = (W% × $W) − (L% × $L), which ranks Pudgy (+0.0791386) over Kanpai (−0.0015417).
- **OX ARB** (2024-04-18): OXv1 → OXv2 for an expected 25% on up to $10,000; marked "Won't Work" because bought OX locks for 60 days.
- **Option tools** (2021–2023): an EV table per option (a MELI $1,340 call at +535.28; a BTC "touch $53,000" bet at +940.04) and a "real time ideal vertical spread selector" that buys the strike before an implied-volatility jump.
- **Short books** (2023–2024): "CLOUD IS DEAD / DON'T TOUCH AI. DON'T TOUCH SEMICONDUCTOR." (May 2023), then altcoin tiers by drawdown and holder concentration (May–July 2024). A copy was reopened on 2026-10-18/19. "PRIME" there is the Echelon Prime game token, "not enough" to short.

> [!tension] The books describe nine-figure notionals ("$375,000,000 worth", "well over 100b", "200-300m"). The September 2024 fund book shows about $23,400 liquid (see [Chapter II](#origins-funds)). No document records any of these trades as filled.

*Sources: ETH Trade doc and sheet (2022-10-29/31); Operation 100b (2023-03-23); STOCKS TO SHORT (2023-05-27); Options>Vertical Spread>IVDifference (2023-07-24); The "Impossible" Task (2023-08-18); Trade Idea 2.27 (2024-02-27); ETH Trade 7200 (2024-03-20); April 1st Trade Ideas (2024-04-01); OX ARB (2024-04-18); Stock Option EV (2021/2023); May 2024 Altcoin Shorts and copies (2024-06 → 2026-10); Summer List of Coins to Short (2024-07-01)*

## The master plans: Olympus, Personal and the mission (2022 → 2024) {#archive-master-plans}

Two plans from 2022 give the order Saheb meant to work in. The first is a takeover plan for one DAO. The second is a ladder for a life.

### The Olympus plan (August 2022)

Chapter II covers the *Manifest plan* of 18 August: "Olympus acquires Manifest for 33m and me", and the OHM-priced super-app (see [Chapter II](#origins-manifest)). The *Olympus plan*, written the next day, is the operating version. Saheb signs as "Rhino", who "Exits his role of Supreme Dictator sometime in 2023".

| Weeks | Work |
|---|---|
| 1 | Route all DAO contributor payments through Utopia Labs; one-to-ones with every contributor; "Finalize 25m Olympus buyout for Me & Manifest -> Rebrand to 'Flow', Install CMill as Flow Commander" |
| 2–5 | Finish the "Forex" product with Lazer Dev Shop (referral links, leaderboard); launch Oddessy with sudoswap-style ERC721/ERC20 pools, "effectively creating StockX type markets for real world clothing to be purchased in OHM"; queue the Flow F/W 22 drop |
| 5–8 | Forex dev time; finish Odyssey; deliver the F/W 22 drop |
| 9–16 | Spec the Option Trading Product; Flow as "manifest as a service" for ecosystem clients, paying quarterly dividends largely back to Olympus; "Scout for Market Making Team, Gemini to make the spreads on the Option Trading" |
| New year | Deliver the options product and S/S 23 drop; form the market-making team; the Olympus Super App goes live "sometime in late 2023" |

The $25m sits in two Gnosis Safes, one run by CMill and one held jointly: "my personal piggy bank but will be used to fund all Flow related operational projects." The super-app bundles a debit card (buy out Mover; the card is an NFT "you physically claim … through Flow"), a credit score (buy ArcX "if it's cheap enough"), borrowing, forex, options, clothing, market making and a TikTok-like creator app.

**The targets.** Olympus should own "more than 25m of Flow tokens" and collect "abt 500k per quarter" in dividends. The plan values Olympus SuperApp at 10B (13–25B peak), Wholesome OnlyFans at 1B and Flow at "3B (peak, 500-700m actual)", with a market-making firm, a property arm and a Chicago trading firm staffed from "gemini trading team". "Manifest Tech owns Assets Under Management from Flow, WholeSome Onlyfans, OHM holdings, Trading Earnings, and funds the Market Making Firm." A new Flow cap table would be "something like 3% former owners of manifest, 16-17% olympus, 30% something cmill, 50 me, the rest lbp/lp". (Personal paycheck allocations in the plan are not summarized here.)

**The Fibonacci primes.** Three numbers stand alone in the text:

| Number in the plan | What it is | Label |
|---|---|---|
| 433,494,437 | F(43), a Fibonacci prime | None |
| 2,971,215,073 | F(47), a Fibonacci prime | "BEFORE 22" |
| 99,194,853,094,755,497 | F(83), a Fibonacci prime | "Life Time Earnings"; then "Units of E:" |

F(83) is also the empire target in *fibonacci prime*, the energy-unit note of the same day (see [Chapter II](#origins-empire)). Here the primes are a ladder of wealth targets, four years before the prime supply ladder of Rei.

### Personal (October 2022)

*Personal* (2022-10-04) is a ladder of companies with a time trial:

| Level | Company | Clear by |
|---|---|---|
| 1 | Tech/lifestyle company (blockchain + OS) | 2025 ("1B by 23") |
| 2 | Hardware company (devices + telecom on the same blockchain and OS) | 2028 ("10B by 26") |
| 3 | Semiconductor company | 2031 ("100B by 29") |
| Concurrent | Capital management firm — "raises alongside Level 1" | — |
| Final | Miltech company | 40s |

A biotech company is the bonus. "Semiconductor gives tech to Hardware & Miltech." The plan closes "2222 End".

This is the earliest frame that pairs **a blockchain consumer company** with **a capital-management firm**. Every later pod fits it. Manifest, REAL and Rei are Level 1. Andromeda, ACM and 3S Capital are the concurrent firm. In the archive the exchange line first appears in the firm's trading papers (Operation 100b, the Andromeda Terminal), not in the consumer company's.

> [!number] 1B → 10B → 100B — Level 1, 2 and 3 targets "by 23", "by 26" and "by 29" (Personal, Oct 2022)

### The mission notes (2022 → 2024)

- *Corporate Structure* (2022-12-14): "Will we ever go public on the US Stock Market? We will."
- *SAHEB* (2023-07-14): for the public, "A single unified OS with its own ecosystem favored towards cryptocurrency"; for VCs, "A military company".
- *Mission Statement* (2023-08-30): "The Mission: Become the richest individual to live." The road: options and financial markets "(400x)", tech companies, then private equity, venture and miltech after 30.
- Plan note (2024-04-29):

> [!quote] "Just focus on the plan. Trade. Fund. Tech. Miltech." — Untitled note, 2024-04-29

Two state-building notes sit beside these [unsure-fit]: *Andromeda* (2023-04-01), a world "Andromeda government" of national "sectors" whose "Databases are in space. Unstoppable.", and *Operation Kalista* (2023-06-09), a nation in Punjab. Neither has token mechanics.

*Sources: Manifest plan (2022-08-18); Olympus plan (2022-08-19); fibonacci prime (2022-08-19); Personal (2022-10-04); Corporate Structure (2022-12-14); Andromeda (2023-04-01); Operation Kalista (2023-06-09); SAHEB (2023-07-14); Mission Statement (2023-08-30); Untitled plan note (2024-04-29)*

## Manifest on-chain: the OHM fork in numbers (2021 → 2023) {#archive-manifest-onchain}

Chapter II tells Manifest's story (see [Chapter II](#origins-manifest)). The archive adds how it was built and what it cost. Manifest was a fork of Olympus: the same contracts, a different token and a clothing business on top.

### The contracts

*MNFST Contract Info* (2021-11-10, by Manifest's developer Lando) lists the Ethereum mainnet set: ManifestERC20Token, sManifestERC20Token (the staked, rebasing version), ManifestStaking with a helper and warmup, ManifestTreasury, a Distributor, a ManifestGenesisERC1155 mint contract switched on through a Gnosis multisig, and bond depositories for sOHM, WETH and MNFST-OHM LP with a bonding calculator. The bond file Saheb kept, *manifestbond.js*, holds the stock OlympusBondDepository contract and is the same size as his copy of *olympusbond.js* (38,553 bytes).

A bond sells the protocol's token at a discount for assets (here OHM, WETH or LP tokens) that go into the treasury. The **risk-free value (RFV)** is the treasury backing per token.

### The policy sheet (February 2022)

*Manifest Policy* (2022-02-12) runs the numbers.

- **Supply and price.** MNFST supply 177,733; OHM at $69.69, WETH at $2,444. "1 OHM = 1000 MNFST" for bond pricing.
- **Bond prices.** The sOHM bond (control variable 500, target debt ratio 66%) prices MNFST at **$23.07**; the WETH bond (CV 333, target 50%) at **$40.94**. Bond size is capped at 0.9–1% of supply.
- **APY tiers.** Rewards fall as supply grows, in "333" steps: under 333,333 tokens, an APY of 33,333–66,666%; at 333m–3.33B, 3–33%.
- **Genesis split.** Vortex (the founding team) 9% = 90 NFTs and 2,970 tokens; Treasury 24% = 243 NFTs and 8,019 tokens; Community 67% = 666 NFTs and 21,978 tokens. That is 999 NFTs and 32,967 tokens, exactly 33 MNFST per NFT (the auto-stake Chapter II records), and it matches the Season 0 plan of "3 x 333" hoodies with "666 for mint". "COST FOR YEAR 1 TO MAINTAIN LP $416,030.41."

### The policy debate

Two community members wrote the theory. "Dunnsy" (2022-01-27/28) wants bonding tied to the premium of price over backing: "Suggest 1% supply increase for every 10% above RFV", "1% supply decrease for every 10% discount" by inverse bonds, instant bond redemptions, and about 5% of each bond above backing to the DAO. Staking APY "is a pvp stock split"; its only job is a price of "2 M per hoodie". His simulations run from a bad month (claim per gM +8%) to "Full Bulltard" (price $725, treasury 42×, claim 25.8×). "Krill" (2022-02-07) prices backing in OHM, not dollars, and argues for shorter bond vesting: "You win the Ohm game when your cost basis is below RFV."

### The launch and its cost

The *Calendar* sets the launch. The Discord opened on 1 November 2021 at 11:11 EST, followed by "33 spots available for whitelist", contracts by 9 November and an "NFT/Token/Staking Launch at 11:11AM EST / 3:33 PM EST / or 11:11 PM EST" on 11 November, then CoinGecko and CoinMarketCap listings and "NFTX-Style pools" of MNFST against the NFTs. The Discord article sorts members into Visionaries (governance), Creators (culture) and Builders (construction), and thanks Olympus: "it changed our lives."

> [!number] $95,887 — ManifestDAO's expense report for the launch (Oct–Nov 2021)
> 50 OHM of liquidity ($46,000), three contract deployments (4.777, 1.333 and 1.5 ETH: $35,153), the manifest.gg domain ($6,000), developer pay ($8,000).

The *MANIFEST + KLIMA* brief (2021-12-09) explains the backing: "MNFST tokens are backed by the compounding power of staked OHM." Manifest would be "the first protocol to include staked Klima in our treasury" and carbon neutral or negative.

### The NFT market and the goods

- *Buy/Sell* (2022-06-29): "What is the objective? Guarantee place to buy/sell." A curve over 100 NFTs and 1,000 MNFST (10 MNFST = 1 NFT) with a 1% spread, filled from staked MNFST in the treasury. It is Manifest's NFT market maker and the seed of the Olympus plan's sudoswap pools.
- *Manufactering* (2021-12-08): swap an NFT for a "claimed Version", "take the tx hash and convert it to the QR code". MNFST_QR shows the numbered tags ("M 01/XXX"); design decks cover sneakers, a golden-ratio tee and "Utopia" jackets (2022).
- *Homepage Spec* (2022-06-12): a WebGL site that "definitely deserves a 50mil Series A raise", and a service letting "anyone … create their own physically claimable nft storefront using backend integration with shopify".

### The companies

| Date | Entity | What the file shows |
|---|---|---|
| 2022-02-08 | Manifest Collective LLC (Delaware) | Certificate of formation, signed by Saheb |
| 2022-04-26 | Manifest Inc. (drafts) | 14,000,000 common + 1,000,000 preferred authorized; Saheb 60%, Milan Schouten 40%; SAFEs up to $500,000 |
| 2022-05-25 | Manifest Tech Inc. | Milan Schouten ("milark") receives 3.6M common + 0.4M founders preferred, 4-year vesting |
| 2023-02-28 | TAX sheet | "Angellist Stack — PAY & DISSOLVE"; "Angellist Stack TAX $950 — For Manifest" |

> [!tension] An August 2025 deck calls Saheb a "22-year-old serial entrepreneur with 7-figure exit from previous crypto venture." The archive shows Manifest's raise ($1.3M in 8 hours, per Chapter II), a $95,887 launch bill, and its banking entity being paid out and dissolved in February 2023. No document records a sale. A sibling deck from the same week describes the founder as an "Industry veteran with aerospace and transportation expertise" instead.

*Sources: MNFST Contract Info (2021-11-10); Calendar (2021-11-05); Medium #1: Manifest Discord (2021-11-03); Expense report, ManifestDAO (Oct–Nov 2021); Manufactering (2021-12-08); MANIFEST + KLIMA (2021-12-09); manifestbond.js / olympusbond.js (2021-11-29); MNFST Token Thesis drafts 1–2 (2022-01-27/28); Policy – Dunnsy (2022-01-27); Krill's Policy Thesis (2022-02-07); Manifest Policy (2022-02-12); Manifest Collective LLC filing (2022-02-08); Manifest Inc. Draft Docs (2022-04-26); Stock Purchase Agreement – Milan Schouten (2022-05-25); Homepage Spec (2022-06-12); Buy/Sell (2022-06-29); TAX (2023-02-28); Swaich: From Starbase to the World (2025-08-14); Swaich — The Starbase Shuttle (2025-08-17)*

## Andromeda on paper: the fund documents (2023 → 2024) {#archive-andromeda-fund}

Chapter II covers Andromeda's plans, trade letters and books (see [Chapter II](#origins-funds)). The archive adds the legal papers. They show a fund that changes its thesis, its structure and its token every few months, and never records an outside investor.

### Eight documents in sixteen months

| Date | Document | Vehicle | Size | Terms | Strategy |
|---|---|---|---|---|---|
| 2023-02-23 | Cypher Trade Deal | Andromeda (to be co-founded) | "I need 35 m" | Asks Harrison to co-found and "size me 10m" | Cypher (Solana perps) to raise $75m, Saheb to "get in at 10m" and merge it with Marginfi |
| 2023-04-20 | Andromeda Gnosis.pdf; Tentative Investor Agreement.pdf | Andromeda Capital, Delaware LLC | $20M | 3% mgmt + 30% performance; **AND 10,000,000**, 3,000,000 to Saheb | "a binary fund designed to make a return of 20:1 or lose all": ETH put spreads on Kraken |
| 2023-10-29 | Andromeda Fund Structure | US Andromeda Digital Assets owns BVI Andromeda Trading | — | Referral "bucket account" | Institutional KYC on ~20 exchanges |
| 2023-12-05 | Tentative Investor Agreement | Andromeda Digital Asset | $20M | 3% on fund size; 30% performance to 3×, 50% above; **AND 20,000,000**, 6,000,000 to Saheb; half the investor's tokens to the manager after 3× | 50% one long ETH options bet (1600 → 2200, 3800, 7200); 50% venture, uPNL roll ≤5×, operations |
| 2023-12-19 | Andromeda Pod Ideas | Pods inside the fund | — | — | Spot-fundamental, option market making, MEV, venture, airdrop farming |
| 2024-02-11 | Andromeda Term Sheet (Chapter II) | Delaware partnership LLC on a multisig | $20M | **AND 10,000,000**; $5m max per investor | $10m to Kraken Pro options |
| 2024-02-12 | Offering Memorandum | Andromeda Digital Asset LLC | $20M = $10M options + $10M pods | USDC into a Gnosis multisig; K-1s; "private offering under the Safe Harbor Act" | Options "potential 300:1 returns"; airdrop and venture pods |
| 2024-06-27 | Business Plan ACM | Strategy vaults | — | One taxable event | Tokens for single strategies (below) |

**The counterparty clause.** The April 2023 papers repeat Operation 100b's solvency terms: pay-as-you-go with Kraken, a close-out at a discount, or "Accepting Kraken Shares". The other named counterparty is Cumberland.

**The structure.** The October 2023 plan puts a BVI trading company under a US parent. The trading company would open institutional accounts on BitGet, Ascendex, Gate, MEXC, LAToken, Digifinex, BitMart, XT.com, Bibox, FameEX, Phemex, Bybit, BingX, CoinEx, KuCoin, LBank, CoinW, OKX, OPNX and HTX. The same list feeds the trading terminal.

**The token.** AND is a "mirror token": a token that records a share of the fund. Saheb's Drive holds a cap-table simulator for "Otonomos Mirror Tokens" (OMT, last edited August 2023) at $1.00 each, with 10–20% bonuses for early tranches from 31 May 2023. Otonomos is also the firm whose $200 legal consultation the 2021 Manifest expense report calls "waste of money". The term probably came from there [unsure-fit].

> [!number] 10M → 20M → 10M — AND token supply in April 2023, December 2023 and February 2024
> Saheb's share: 3M (30%), then 6M (30%) plus half the investor's tokens after 3×, then 30% rising to 50%.

**Strategy-vault tokens.** *Business Plan ACM* (2024-06-27) tokenizes single strategies:

> [!quote] "We'll create tokens representing individual strategies that we conduct, then on the balance sheet when redeeming we'll sell the tokens so it's one taxable event." — Business Plan ACM, 2024-06-27

The example: an investor puts $10m into the fund's Safe. The manager moves $250k into a "rainbow airdrop strategy" vault, which issues 25 tokens at $10,000. The vault farms across thousands of wallets. When it returns $5m, the 25 tokens are "sold" to claim it, each rising from $10,000 to $200,000. Audits: "it's all on chain, we'll print out the transactions". The 3S Capital brochure later calls these "trade vaults" (see [Chapter II](#origins-funds)).

**The people.** The March 2023 website spec uses the domains Andromeda.vc and Ethshort.com, with contact cards for **Nick** and Saheb ("Collectively built projects with more than 20m mcap") and portraits of Saheb and **Monk**. In December 2023 Saheb "approached Monk with the seriousness of needing to begin starting the fundraising process right now." *Outreach for Later On* (2024-04-12) lists 41 billionaire founders beside the 42 crypto LP targets in Chapter II.

> [!tension] The fund flips from a bet on ETH falling (April 2023 put spreads) to a bet on ETH rising (December 2023 call strikes to 7200), then back to falling (the April 2024 "ETH DOWNTURN" letter), within twelve months.

*Sources: Cypher Trade Deal (2023-02-23); Saheb's eth trade (2023-03-09); Andromeda Gnosis.pdf and Tentative Investor Agreement.pdf (2023-04-20); Captable simulator, Otonomos (2023-08-23); Andromeda Fund Structure (2023-10-29); Tentative Investor Agreement (2023-12-05); Working on (2023-12-06); Andromeda Pod Ideas (2023-12-19); Offering Memorandum (2024-02-12); Outreach for Later On (2024-04-12); Business Plan ACM (2024-06-27); Expense report, ManifestDAO (2021)*

## Andromeda's tools: the terminal, the scanner and the vault platforms (2023 → 2025) {#archive-tools}

Two of these tools, the multi-exchange terminal and the funding-rate fund, are the clearest bridges from crypto perps to the equity-perp exchange.

### Chartpaint → Andromeda Terminal (November 2023)

> [!quote] "Chartpaint is the pre-release prototype in-house proprietary trading software that we use to accumulate low cap spot altcoins" — chartpaint -> andromeda terminal, 2023-11-13

"Andromeda Terminal is the final evolution of chartpaint, an all-in-one in house aggregator for options, perps, spot, margin, borrow/lend from one terminal frontend". The spec has four stages.

1. **Chartpaint V1 (command line).** Connect eight smaller exchanges, print what each would cost to move a price ("Gate: Total USD cost to bring price up by $0.03: $5,250"), and fire simultaneous immediate-or-cancel orders.
2. **Chartpaint V2.** Thirteen more exchanges, plus DEX swaps through li.fi, Jupiter and Osmosis.
3. **Terminal V1 (web).** Depth per venue, a best-path router, and every position benchmarked against "SOL 20x".
4. **Terminal V2 (perps).** Venues where **uPNL rolling** works: "use your cross margin upnl to snowball without closing the position", so unrealized profit on a cross-margined perp becomes margin for a larger one. Yes on Bybit and Hyperliquid; not MEXC.

The *Andromeda Dashboard* (2024-03-14) states the Terminal's purpose: "build 9 figure perp positions, accumulate coins across exchanges in one order", getting around per-venue limits ("10m for binance, 10m for bybit"). It also plans an investor page, a mobile PnL app and a "Cloudy airdrop farming suite". The andromeda.xyz domain was quoted at $150,000.

The Terminal's cross-margin logic is the "20x cross margin that we're used to in crypto" that a November 2025 note promises to bring to US equities (see [Grayline and the road to MIAX](#archive-grayline)).

### MispricedFinder (May 2024)

A console app compares Andromeda's realized volatility with the implied volatility of Thales Market, an on-chain options AMM, across 10 markets on Optimism, Arbitrum and Base. Below a ratio of 1 the option is cheap, e.g. "5/10/2024 DTE: 2 LB: 2 — ARB 0.63, OP 0.8, SOL 1.01, BTC 1.25". The June 2024 book counts the "Thalesmarket Mispriced Options Bot" as income of $3–10k a month.

### Blur for Memecoins (May 2024)

> [!quote] "What blur did for nfts on ethereum, I want to do for memecoins on solana." — Blur for Memecoins, 2024-05-17

Users deposit SOL into traders' vaults. The platform takes 2.5% of profits and deposits plus a 2 SOL opening fee. The front end copies Photon and adds discovery (DexScreener takeovers, Twitter sentiment, "most bought by other vaults") and a vault leaderboard. The token drops "via no points program, random surprise during market lull period". "Revenue generated gets used for buyback on the token. Vested for VCs only."

### Funding Arb fund (November 2025)

A fund that splits capital across exchanges to capture funding-rate arbitrage, sizes each trade, "dynamically creates a TP/SL monitoring ADL to farm within a range", and pulls capital back. Capital moves hub-and-spoke: the hub is an Ethereum address on Arbitrum, the spokes are exchanges. Funding rate is the periodic payment between longs and shorts that ties a perp to its index; ADL is auto-deleveraging. The note is dated 2025-11-10, two weeks before the first Greyline plan.

### Smaller tools

*Upnl roll* (2023-12-02) sizes uPNL-rolling trades by category, "min 3x-8x in a week". *ids & bids* (2023-10-25) arbitrages NFT trait bids between Blur and OpenSea Pro. *Offer Exchanges by Listing.Help* (2023-12-18) prices exchange listings (Gate from 100k USDT plus 100k tokens; MEXC 30–40k USDT) for a token it does not name [unsure-fit].

*Sources: chartpaint -> andromeda terminal (2023-11-13); Upnl roll (2023-12-02); ids & bids (2023-10-25); Offer Exchanges by Listing.Help (2023-12-18); Andromeda Dashboard (2024-03-14); Andromeda>MispricedFinder>ThalesMarket doc and sheet (2024-05); Blur for Memecoins (2024-05-17); Fund Summary June (2024-07-13); Funding Arb fund (2025-11-10)*

## Airdrop farming operations (2023 → 2024) {#archive-farming}

Airdrop farming earns a new token's free distribution by using the protocol before launch. It was the Andromeda pod with the most activity on record, and the most legal risk.

**The estimates.**

- **Rainbow** (2023-12-14): the wallet raised a $20m Series A; Saheb estimates an opening market cap near $500m and a 15% airdrop worth **$75m**, at about $0.05 a point. The June 2024 book says "Could make 1m+ off this".
- **Blast** (April 2024): 794,840 users; total points on airdrop day 3,035,152,664,292; 30,000,000 Gold; 101,172 points per Gold; implied airdrop $934,827,020; **Gold ≈ $15.58**. A table of about 60 Blast apps by Gold received, and bot ideas for several of them.
- **Bladeswap** (2024-08-10): automate swaps and daily crate claims. About $485 per wallet; 100–200 wallets → **$35,000–$90,000**; an estimated investment under $1,000 for an "Expected return 40x+".
- **The book** (June and September 2024): $21,919 sunk for a $162,500 low-end estimate (7.4×), then $24,275 for $149,000 (6.14×) (see [Chapter II](#origins-funds)).

**The operations.** The *Airdrop Farming* sheet (2024-06-04) runs 15 wallets across Hook.xyz, Dopex, Hyperliquid, Rysk, Synquote, Jumper and Rabby, with per-wallet notes ("$700 to 4500", "$600 to 0"). The *Mobile App Sign Ups* SOP (2024-04-20) has staff create many accounts on one consumer app. Shared files show the wider circuit: Blast's public Gold distributions, Namada testnet task scores, a Karate Combat airdrop guide.

**The compliance risk.** The farm files describe practices meant to make one operator look like many unrelated users (a "sybil" in airdrop terms): wallet funding routed through mixers and instant-swap services, and app accounts opened behind VPNs and purchased phone numbers. These usually breach the protocols' and apps' terms. Funding wallets through mixers raises anti-money-laundering questions. And the plan to farm with investor money inside a fund makes them fund-level disclosure issues. Any partner reading the treatise should treat this pod as closed history, not as a strategy for AP or Rei. The treatise does not reproduce the steps.

> [!tension] The Offering Memorandum (February 2024) markets a $10M "Investment Pods" sleeve that includes airdrop farming, while the farm files describe sybil and mixer practices; the notes record no disclosure of them.

*Sources: Airdrop Farming for Rainbow Wallet doc (2023-12-14) and sheet (2023-12-16); Blast Gold Meta Strategies (2024-04-15); Blast Valuation Model (2024-04-20); Airdrop Farming Strategy – Mobile App Sign Ups (2024-04-20); Airdrop Farming sheet (2024-06-04); Bladeswap Automation (2024-08-10); Fund Summary June/Sep (2024); Offering Memorandum (2024-02-12); Gold Distribution 1–2 (2024-03/04, public); Evaluated S-Class Submissions (shared 2024-05-17)*

## Grayline, the Progress Document and the road to MIAX (2025) {#archive-grayline}

The archive fills in the months before the first Greyline exchange plan of 23 November 2025 (see [Chapter III](#glx-pathway)).

**Grayline (26 September 2025).** The first file with the name is two headings:

| Country | Asset | Instrument |
|---|---|---|
| Argentina | JEMSE (Jujuy's provincial energy and mining company) — its stake in the Cauchari-Olaroz lithium project | "50% dividend strip" |
| Guyana | Stabroek Block (offshore oil) | "royalty strip" |

A strip separates a stream of payments (dividends or royalties) from the asset and sells it on its own. The idea is a claim on a flow, not on a company. A year later, AP is a single-purpose LLC whose only asset is a royalty on MIAX's fees (see [Chapter VI](#deal-one-page)). The spelling changes to "Greyline" by November.

**SPV Reach (13 October 2025).** A target list for a "$25M SPV": Dominari Holdings ("Deck Sent", $2–5M), Affinity Partners ("Warm Intro", $10M+), 1789 Capital, Cantor Fitzgerald as adviser, PIF ("Too institutional for $25M SPV"), Sanabil, Kingdom Holding, Dar Global ("Real estate angle") and several family offices and individual investors. The SPV's purpose is not stated. Its timing, two weeks after *Grayline*, suggests the strips [unsure-fit].

**The perps notes (November 2025).** The Funding Arb fund (10 November) comes first. A Perps-folder note (25 November) states the product plainly: "I'm going to talk about how to build a regulated perpetual exchange for US equities, the full deal, the 20x cross margin that we're used to in crypto. The first place to start is the life cycle of a trade."

**The Progress Document (2 December 2025).** Attached to the pitch, it records the first MIAX contact:

> [!quote] "I started this idea Nov 2025, finished the pitch document after pivoting the idea from the original reason I reached out to MIAX (discussing an easier wedge listing index perpetuals on their exchange)" — Progress Document, 2025-12-02

Saheb is "speaking to their general counsel about ways to work together regarding leveraging their licenses/half-rebuilding their tech". MIAX "Expressed commentary about an investment, which I followed up with, Polymarket got one from ICE, now's the time." The plan in the deck, "perfecting this DCO/DCM/FCM build to demonstrate to the SEC to legalize equity perps", has to be reworked. "As of Dec, MIAX seems intrigued by the full scope of the vision."

**The spec checklist (4 January 2026).** A one-page list of what the contract must define: funding rate, liquidation, insurance fund and ADL, mark and index price, initial and maintenance margin, cross and isolated margin, corporate actions and order types. These are the headings of the GLX and AP specifications that followed.

> [!tension] "I started this idea Nov 2025" understates the history. Stock perps appear in Operation 100b (March 2023), "high lev futures in us" in Map of Apps (February 2025), and a "Minneapolis trip $2,000" in the September 2024 fund book (MIAX Futures is the former Minneapolis Grain Exchange; whether the trip is related is unknown).

*Sources: Operation 100b (2023-03-23); Fund Summary Sep (2024-09-27); Map of Apps (2025-02-12); Grayline (2025-09-26); SPV Reach (2025-10-13); Funding Arb fund (2025-11-10); Untitled document, Perps folder (2025-11-25); Progress Document (2025-12-02); Untitled checklist (2026-01-04)*

## The AP back office found in the sweep (2026) {#archive-ap-files}

The sweep also found American Perpetual working files outside the data room. They add detail, not direction; Chapters IV–VI cover the substance.

- **The listing desk** (*07_Listing_Desk_Workbook*, data date 2026-08-26) tracks each name through nine runbook steps and ten §41.23(a) items, with a 654-row task board. **SPYP**, the SPY perpetual, is marked "Listed" on Supplement No. 1, with an accountability level of 25,000 contracts and reporting at 1,000. The screener ranks the **483** most-active US names by 40-session notional; Micron leads at $1.38T.
- **The matched pair** (*Example_41.23_SEC19B-7_Filing_Onechicago*, 2026-06-14) sets OneChicago's two filings side by side: a CFTC §41.23 letter per name, "repeated thousands of times", and one SEC Rule 19b-7 filing of listing standards (2003), with margin on a separate Form 19b-4. It is the template for AP's filing set (see [Chapter V](#apreg-listing)).
- **The 30 September closing set** rests the Silver Lake form on the Master Perpetual Products License Agreement, recapitalizes AP to 100,000,000 units and makes government approvals a **closing condition**. The executed MIAX agreement and the Commission order for the 101 names are still "added at execution" (see [Chapter VI](#deal-status)).
- **The delivery acknowledgment** asks MIAX to confirm receipt of 99 files of "Originator Work". "Licensor's later work, on any underlying, is not delivered under the Master Agreement and is not owed."

> [!tension] The listing desk marks SPYP "Listed" with every runbook step done on 26 August 2026, but the 30 September binder still waits for the Commission order. "Listed" is an internal stage, not live trading.

*Sources: 07_Listing_Desk_Workbook (2026-09-03); Example_41.23_SEC19B-7_Filing_Onechicago (2026-06-14); 01_MIPA_Form, 02_AR_Operating_Agreement, 0B_Corporate_Binder_Checklist, 00_Binder_Contents (2026-09-30); AP_Delivery_Acknowledgment_FORM (2026-09-30)*

## Outside the crypto line: other ventures {#archive-other-ventures}

The archive holds business ideas that are not markets or coins. They are listed for completeness, one line each.

- **Swaich eVTOL shuttle** (August 2025): electric air taxis between Brownsville Airport and SpaceX Starbase, 8–9 minutes against a 45–60 minute drive, two leased aircraft, a $5M seed. The SpaceX contract is $3.5–4M a year in one deck, $6.5M in the executive summary and $7M in another deck and the vertiport plan. [unsure-fit]
- **Memtastic** (2025-09-20): a plug-in CXL memory card for AI servers. [unsure-fit]
- **Slay the Dragon** (2025-10-09): "Defeat Apple by launching a streaming phone with SpaceX." [unsure-fit]
- **Project Walkman** (2026-08-02): "a phone that only exists while you're using it." [unsure-fit]
- **Device Company** (2022-10-04): a repairable phone whose parts and insurance are sold as claimable NFTs. [unsure-fit]
- **Operation No Scope** (2023-03-23): an alcoholic gaming drink pitched to FaZe Clan. [unsure-fit]
- **Manifest The Human Company** (2023-06-04): a personal-care product list. [unsure-fit]
- **China-AI dossier** (2026-08-04, "Compiled with Claude"): a public-equity thesis that "The IPO calendar is the whole game", with notes on index access for US persons. [unsure-fit]
- **AI stock notes** (2023–2024): "AI is the NEXT EV, NEXT INTERNET, NEXT CRYPTO"; SoftBank and Japanese listings. [unsure-fit]

*Sources: Swaich Executive Summary (2025-08-19); Swaich: From Starbase to the World (2025-08-14); Swaich — The Starbase Shuttle (2025-08-17); Brownsville Airport Vertiport Requirements (2025-08-14); Memtastic (2025-09-20); Slay the Dragon (2025-10-09); 00 Start Here.md (2026-08-02); Device Company (2022-10-04); Operation No Scope (2023-03-23); Manifest The Human Company (2023-06-04); China AI Dossier (2026-08-04); AI Investment Strategy (2023-05-26)*

## Security: secrets sitting in Drive {#archive-security}

The sweep found live secrets stored as ordinary documents. None is reproduced in this treatise or in its notes.

**The Rainbow farming sheet.** *Airdrop Farming for Rainbow Wallet* (the spreadsheet, 2023-12-16) holds **11 wallet seed phrases and private keys** and a password in plain text. A seed phrase is the master key to a wallet: anyone who reads it controls the funds. Treat all 11 wallets as exposed:

1. Move any remaining tokens, NFTs and claimable airdrops to new wallets made on a clean device.
2. Revoke token approvals granted from the old wallets.
3. Stop using the old addresses, including for future claims.
4. Change the password in the sheet wherever it was used.
5. Delete the sheet and empty Drive's trash; check who it was ever shared with.

**Other sensitive files found by title** (not opened unless noted):

| File | Risk |
|---|---|
| FIREFOXphantomseedphrase.png (2022) | Likely an image of a Phantom wallet seed phrase |
| 1Password Emergency Kit (teammanifest).pdf (2022) | Holds a password-manager secret key |
| "Password" (2021) and "userpass" (2023) documents | Credentials in plain text |
| cloud_backup_….encrypted.txt (2021) | Encrypted backup; safe only if its key is not also in Drive |
| Untitled0.ipynb (2026, see Chapter II) | A plaintext Polygon/Massive API key; rotate it |
| W-9, citizenship certificate, EIN letters, Form 1095-A | Identity and tax documents |
| Milan Schouten stock purchase agreement (PDF) | A personal taxpayer number and home addresses |
| Manifest Tech AngelList Stack deposit instructions | Bank details (not opened) |
| LUCKBRC whitelist responses | Third parties' personal data |

**What to do.** Move credentials into a password manager and identity documents into an unshared folder, rotate every key and password above, and check sharing on these files before any partner gets Drive or data-room access.

*Sources: notes 13 (gap sweep, Excluded and Open-questions sections); notes 16 (gap follow-up); Untitled0.ipynb (2026-03-24, Chapter II)*

## Contradictions and open questions {#archive-tensions}

The sections above carry their own tension notes: REAL's three legal categories and its yield against Rei's ban ([REAL](#archive-real)); *Market*'s "appreciates only" against a binary fund ([Market](#archive-market)); nine-figure books against a five-figure account ([Operation 100b](#archive-operation-100b)); the "7-figure exit" ([Manifest](#archive-manifest-onchain)); the AND supply and the fund's flips ([Andromeda](#archive-andromeda-fund)); undisclosed farming practices ([farming](#archive-farming)); "I started this idea Nov 2025" ([Grayline](#archive-grayline)); and SPYP "Listed" ([AP files](#archive-ap-files)). Three more:

> [!tension] **The KLIMA drop size.** The November 2021 collaboration plan mints 333 MNFST × KLIMA tee NFTs; the December announcement is a "shock drop" of 1,332 NFTs (444 of each of 3 designs) at 2 MNFST each.

> [!tension] **"Flow" means two things**: a genesis hoodie archetype (November 2021) and the new name for Manifest after an Olympus buyout (August 2022).

> [!tension] **The eVTOL contract value** is $3.5–4M, $6.5M or $7M a year depending on the document, and the flight 8 or 9 minutes.

Open questions:

1. Did any Andromeda investor sign or fund? No signed agreement, wire or LP name appears.
2. Was the Olympus buyout ever proposed to Olympus DAO? The archive records only the plan.
3. What became of REAL after October 2025? The last file is the USDC App Spec copy (2025-10-29), and James Piazza is not named in the GLX or AP notes.
4. What was the $25M SPV for: Grayline strips, REAL or something else?
5. Which token was the December 2023 exchange-listing price sheet for?
6. What is on the "Andromeda digital asset" Google Site (July 2023)? Sites cannot be read through the Drive tools.

*Sources: as cited in each section above; notes 13 and 16*

## Archive timeline {#archive-timeline}

| Date | Event | Pod | Source |
|---|---|---|---|
| 2020-11 | Altcoin "Snowball" leverage plan (BTC $15,560, ETH $457), the earliest trading artifact | trading | Copy of Weekly Trading Plan |
| 2021-11-01 | Manifest Discord opens at 11:11 EST | Manifest on-chain | Medium #1; Calendar |
| 2021-11 | OHM-fork contracts deployed; launch bill $95,887 | Manifest on-chain | MNFST Contract Info; Expense report |
| 2021-12-17 | Manifest × KLIMA Genesis drop, 1,332 NFTs | Manifest on-chain | Manifest Genesis |
| 2022-02 | Premium-responsive bonding theses; Manifest Policy sheet; Manifest Collective LLC formed | Manifest on-chain | Token Thesis drafts; Krill; Manifest Policy; DE filing |
| 2022-04-26 → 05-25 | Manifest Inc. drafts (60/40, SAFEs ≤ $500k); Milan Schouten SPA | Manifest on-chain | Draft Docs; SPA |
| 2022-08-19 | Olympus plan: $25m buyout, Flow, Odyssey, Super App, "Real", F(43)/F(47)/F(83) | master plans; REAL | Olympus plan |
| 2022-10-04 | Personal: blockchain + OS → hardware → semis, capital firm concurrent | master plans | Personal |
| 2022-10-29 | Master Capital ETH put-spread parlay, $500k → $62.5m | trading | ETH Trade |
| 2023-02-23 | Cypher Trade deal; Harrison asked to co-found Andromeda | Andromeda fund | Cypher Trade Deal |
| 2023-02-28 | Manifest's AngelList Stack entity to "PAY & DISSOLVE" | Manifest on-chain | TAX |
| 2023-03-23 | Operation 100b: "Perpetuals on Stocks, Cheaper than Options on Stocks" | trading | Operation 100b |
| 2023-03-29 | Market: $40 price point, split above $500, property sale = token sale | token rules | Market |
| 2023-04-20 | Andromeda Capital binary fund; AND 10M | Andromeda fund | Andromeda Gnosis.pdf; Tentative Investor Agreement.pdf |
| 2023-06-15 | "Stable coin is algorithmic REAL" | REAL | What can be done now? |
| 2023-09-08 | "Crypto will serve as the primary equity source" | token rules | Ideas |
| 2023-10-29 | US parent, BVI trading company; KYC on ~20 exchanges | Andromeda fund | Andromeda Fund Structure |
| 2023-11-13 | Chartpaint → Andromeda Terminal, uPNL rolling | tools | chartpaint doc |
| 2023-12-05 | Andromeda Digital Asset agreement; AND 20M | Andromeda fund | Tentative Investor Agreement |
| 2023-12-16 | Rainbow farm sheet with 11 plaintext seed phrases | farming; security | Rainbow sheet |
| 2024-02-12 | $20M Offering Memorandum ($10M options + $10M pods) | Andromeda fund | Offering Memorandum |
| 2024-04-20 | Blast Gold valued at $15.58; mobile sign-up SOP | farming | Blast Valuation; SOP |
| 2024-05-17 | Blur for Memecoins | tools | Blur for Memecoins |
| 2024-06-27 | Strategy-vault tokens, "one taxable event" | Andromeda fund | Business Plan ACM |
| 2025-02-12 | Map of Apps: Homer, Cartel, "Andromeda — US derivatives exchange", "REAL currency" | token rules; REAL | Map of Apps |
| 2025-06-06 → 26 | REAL Yield Plan, practice spec, Real Deck and Spec, 1Real, Space | REAL | REAL documents |
| 2025-07 | USDC Pay emails, roadmap and app spec | REAL | VC Emails; USDC App |
| 2025-08-14 / 17 | eVTOL decks ("7-figure exit"; $3.5–4M vs $7M contract) | other | Swaich decks |
| 2025-09-26 | Grayline: JEMSE dividend strip, Stabroek royalty strip | Grayline | Grayline |
| 2025-10-13 | $25M SPV target list | Grayline | SPV Reach |
| 2025-11-10 / 25 | Funding Arb fund; "regulated perpetual exchange for US equities … 20x cross margin" | tools; Grayline | Funding Arb fund; Perps note |
| 2025-12-02 | Progress Document: MIAX general counsel; first approach was index perps | Grayline | Progress Document |
| 2026-06-14 | OneChicago matched-pair study | AP files | Example_41.23 filing |
| 2026-08-26 | Listing desk data date; SPYP marked "Listed" internally | AP files | 07_Listing_Desk_Workbook |
| 2026-09-30 | Closing set on the MPPLA; 99-file delivery acknowledgment | AP files | CLOSING_DOCUMENTS |

*Sources: notes 13 (gap sweep) and 16 (gap follow-up), dated documents as listed*

<!-- END CHAPTER -->
