# IX. Rei (零 · XR) — the prime coin

Rei is the coin the rest of the treatise points toward. Its supply is always a prime number of whole coins, 2 at launch and then 3, 5, 7, 11 and on, and each step mints only the gap to the next prime. At first each step was to be split by Riemann's R function, a smooth count of the primes ("prime rata"). The ticker is **XR**. The coin launches through one sale: sell orders climbing from 3 cents to 30 cents on MIAX's XR/USD book. American Perpetual's stock perps sit in the same account. Saheb set the design down in nine documents between 3 and 19 October 2026, after three claude.ai chats in May and June. This chapter covers the thesis, the math, every launch number, the market at MIAX, the conflict with AP, the two architectures the documents disagree on, and what is still open.

## The short version {#rei-summary}

Rei is a consumer coin for America that also works on Mars. You hold XR, an AI agent called Rei asks and pays for you, and everyone sits on one 3D map. The investor tag is "America's consumer internet crypto." The brand line is "Intercivilization money."

- **The coin.** Rei (零, Japanese for "zero", said "rey") is the whole coin. XR is a Rei's tenth decimal: 1 Rei = 10^10 XR. The first step is 2 Rei = 20 billion XR, minted only as the launch sale sells.
- **The supply law.** "mint = next prime − this prime." Each step waits for a milestone. The Foundation proposes the step, holders vote to accept it, and nothing ever burns.
- **The split.** The 14 October brief splits each step by R(balance), so small holders get a little more than pro rata, and the 16 October simulation keeps that rule. The MIAX brief, the World document and the deck (16–17 October) pay "in proportion" to savings and never mention R.
- **The launch.** One sale of 31% of the first step on MIAX's XR/USD spot book: a sell ladder from $0.03 to $0.30 over 6.2 billion XR. It raises $81M if it clears at 6¢ and $727M if it sells out. Proposed for 1 November 2027, for 30 days. The other 69% is minted alongside: 50% to the Foundation, 19% to the equity co (the operating company) and team.
- **The market.** MIAX lists XR spot and runs the US market for bitcoin and ether perps and options, margined in dollars around the clock. Every Rei Pay payment sells XR on that book. AP's stock perps sit in the same account.
- **The conflict.** AP's draft licence pays AP 60% of MIAX's fees on every perpetual MIAX lists, on any underlying, so a Rei perp at MIAX would pay AP. Saheb's own to-do says to carve Rei out before either deal is signed.
- **Status.** "Nothing is built yet." What exists is designs, a 30-day simulation on 120 seeds and a proof benchmark. Testnet and the developer cookbook are proposed for 31 March 2027.

> [!number] 2 Rei = 20,000,000,000 XR — the first step
> Minted only as the one sale sells; $600 million at the 3-cent floor.

> [!number] 50 / 19 / 31 — Foundation / equity co and team / the one sale
> For every 31 XR sold, 50 are minted to the Foundation and 19 to the equity co.

> [!number] $81M · $323M · $727M — the ladder clearing at 6¢, 15¢ and 30¢
> "The ladder's arithmetic, not forecasts."

> [!number] 1 November 2027 — mainnet and the one sale (proposed)
> 30 days, if the CFTC clears XR spot by 30 June 2027.

*Sources: Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Rei — The Deck (2026-10-17)*

## What Rei is, and why — in Saheb's words {#rei-thesis}

The thesis has three parts. Money should cost nothing to move. Supply should follow one public law that no company can bend. Value should come only from use.

**Money that costs nothing to move.** The first spec opens with tap-to-pay:

> [!quote] "Rei is a chain and a coin, like NEAR, made so every person in America can tap and pay with it." — Rei — Brief, 2026-10-14

Saheb's own notes, quoted in the data-room page *Prime ticks*, go further:

> [!quote] "There is no fee it's everyone's account. Like it just uses the 5g on the device." / "I think everyone carries the proof. No one gets paid. No special devices needed." — Product Notes, quoted in Prime ticks, 2026-10-16

The later documents call it "lossless money": "No fee to move. Nothing burns. XR goes around like money."

**One law for supply.** The deck calls the prime curve "One law". The name comes from the math. Rei means zero "after the zeta zeros that tie the unlock curve to the split." Riemann showed that the prime staircase equals his smooth R curve plus one wave for each zero of the zeta function:

> [!quote] "Rei unlocks on the steps and splits on the smooth curve, so the zeros are what separate the two." — Rei — Brief, 2026-10-14

**Value from use, not from a company.** The equity co earns fees. XR earns nothing from it:

> [!quote] "It gives XR no value except that XR is fun to use, which keeps XR money rather than a share." — Rei — The World a $100 Billion Coin Makes, 2026-10-16

This is also the legal design. Under the SEC and CFTC interpretation of 17 March 2026, a token whose promises are kept at launch, with no yield and no claim on a company, can be sold as a digital commodity. So Rei launches working, the company's value lives in a public stock, "and XR stays money."

**Money for more than one world.** "Intercivilization money" means one balance, one handle and one agent "from a ramen shop in SoHo to a dome on Mars." The deck's Mars slide ends with Saheb's line:

> [!quote] "This is alien money." — Rei — The Deck, Mars slide notes, 2026-10-17

*Trader in Time* (9 October) supplies the frame. "Most traders watch the price. Saheb watches how long." A perpetual prices the wait. A zk receipt shortens it. And of the XR language: "A language where every promise carries a day: he writes the wait down." Rei's ticks, its promises with check times and its proof of every tick come from that frame.

*Sources: Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei — The Deck (2026-10-17); Trader in Time (2026-10-09)*

## Where Rei comes from: the prime lineage, 2022 → 2026 {#rei-lineage}

Rei is where four years of main-coin ideas land. Three things carry over: prime-stepped supply, one coin that prices everything, and handles sold by rarity. Two things flip: dividends are gone, and the coin no longer has to "feel like a stock".

| Date | Document | What it held | What Rei keeps or changes |
|---|---|---|---|
| 2022-08-18 | Manifest plan ("World of Ohm") | OHM as the one denomination across forex (500x), options, clothing, NFTs, credit, debit card | One coin for everything: "one balance, one handle, one agent" |
| 2022-08-19 | fibonacci prime | Empire target 99,194,853,094,755,497 E, the Fibonacci prime F(83): "THIS IS WHAT I CHOOSE" | A prime as the goal number |
| 2022-10-04 | Year 1 / Master | Main token over app tokens; "⅓ foundation, ⅓ paid to apps, ⅓ dividends to users"; LIFE handles priced by length, $3 to $32,805; "C-Prime" contracts | Handles return as coins, "dearer at the short, rare tiers"; a foundation share returns as the 50% |
| 2023-04-01 | Stablecoin (Z) | RWA-backed soft-peg stable released in "prime stairsteps"; BTCZPERP | Prime steps become the whole supply law |
| 2023-08-11 | Sahebs rule of tokenomics | "the ecosystem's coins must be less than the main coin"; ~100m supply in the $10s | Handle and picture coins sit under the main coin; the supply rule flips |
| 2023-11-10 | Coin Denominated Reality | A public company holding a main coin whose treasury owns 100+ product coins paying USDC dividends; "Lend. Options. Perps." | A public equity co, perps in the same account; no dividends |
| 2024-02-13 | Saheb's 5 Year Plan | A market-making firm that becomes "the first legal crypto Prime bank in the world" | The equity co's desk on the XR/USD book |
| 2025-10-15 | XR | "Smart glasses + Controllers bundle … Android XR"; no coin | The letters XR, a year early |

The closest ancestor is the Z stablecoin:

> [!quote] "Z up protection, unlocks stair steps in the prime to release greater supply, because greater demand." — Stablecoin, 2023-04-01

The 2023 document never defines "prime stairsteps". Rei's "mint = next prime − this prime" is the first exact version. Whether it matches what Saheb meant in 2023 is open (see [Chapter II](#origins-stable)).

**What flipped.**

- **Dividends.** Year 1 (2022): "All Tokens Pay Dividend eventually starts as currency -> security." Rei (2026): "no yield, revenue share, buybacks or burn", because revenue paid to holders would make XR a security.
- **"Feel like a stock."** The 2023 rule: "The main token needs to feel like a stock, stocks aren't priced at 9 zeros." On the morning of 16 October Rei did just that: 1 XR was the whole coin at about $300 million, and the smallest amount was 0.0000000001 XR. The same day's later documents moved XR to the tenth decimal, so XR prices at 3¢ at launch and $5 at $100 billion.
- **Policy, not code.** The 2022 Blockchain note says "Decentralization is foolhardy and can only be achieved through policy." Rei keeps a Foundation "policy team". That team is exactly what the CLARITY Act's 20% test counts against Rei (see [The legal route](#rei-law)).

**The 2026 chats.** The 14 October brief cites four claude.ai chats: "PRIME protocol" (25 May 2026), "Prime token currency" (14 June), "Private money system" (15 June) and "Riemann and primes" (14 October). Two June facts survive in the brief. "A token raise was shelved in June as not worth the attention." And a June design put a secure chip in each phone that "works offline and off-world". None of the chats has been read (see [The chats Rei cites](#rei-chats)).

> [!tension] On 7 October the zkTPU report dropped its own "credit tokens and a central coin", because "token networks earn far less than they emit", and chose "one public company, no token". Rei, a week later, is token-first.

*Sources: Manifest plan (2022-08-18); fibonacci prime (2022-08-19); Year 1, Master, Blockchain (2022-10-04); Stablecoin (2023-04-01); Sahebs rule of tokenomics (2023-08-11 → 09-10); Coin Denominated Reality (2023-11-10); Saheb's 5 Year Plan (2024-02-13); XR (2025-10-15); Rei — Brief (2026-10-14); zkTPU verification report (2026-10-07)*

## Nine documents in seventeen days: how the spec moved {#rei-versions}

Rei was specified between 3 and 19 October, and most of it between 14 and 17 October. The documents disagree on the unit, the chain, fees, what triggers a step and how a step is split. Read in order, the disagreements are a run of decisions. The MIAX brief itself calls the simulation's rule "the earlier supply formula."

| Date | Document | Role |
|---|---|---|
| 2026-10-03 | XR Language — Brief (rev 41) | The organizing language; "zk tick compression"; later the house style |
| 2026-10-04 | XR Suggestion Bar | iMessage keyboard for XR sentences |
| 2026-10-14 | Rei — Brief (gallery title "Currency — Brief", rev 37) | First spec: prime staircase, prime rata, ticks; Ethereum vs the June chip |
| 2026-10-16 | Prime ticks | Data-room page on Protocol Spec v0.6 and the rei-core simulation; ticker XR; 5G phones |
| 2026-10-16 | Rei — The World a $100 Billion Coin Makes (rev 226) | Vision, economics, law, road |
| 2026-10-16 | Rei × MIAX — The Brief (gallery title "Rei — Stack") | The MIAX pitch; 28 filings; private to-dos |
| 2026-10-16 | Rei — The Cookbook | Developer recipes |
| 2026-10-17 | Rei — The Deck | 13 slides cut from a "64-page brief" |
| 2026-10-19 | Spaceyard | Live-stream map with an in-app currency, SPY |

Two design files sit beside these: "Rei coin variations" (16 October) and "Rei, redesigned" (17 October; not opened for this chapter).

| Question | 14 Oct (Rei — Brief) | 16 Oct, v0.6 (Prime ticks) | 16–17 Oct (World, MIAX, Cookbook, Deck) |
|---|---|---|---|
| Unit | "5 Rei", no sign; ticker REI is taken | XR = the whole coin (~$300M), ten decimals; prime marks retired | Rei = whole coin; XR = tenth decimal (3¢); marks return as "folds" |
| Chain | "a chain that isn't a chain"; Ethereum or the June chip? | "no Ethereum"; phones are 5G hops; no state root | Rei Chain, an Arbitrum Nitro rollup on Ethereum; "Phones aren't nodes" |
| Fee | "One price per tick. It rises when money moves fast." | "no fee and no burn" | Free to move; 1% on marketplace trades and sales; posted fee for instant bank sends |
| What fires a step | "a verified human directive set by AGI, such as building a specific mine" | a milestone list fixed before launch, its hash published | Foundation proposes, holders vote; Deck: "the civilization's objectives" |
| Who gets a step | prime rata on R(balance) | the KYC'd Token Depository, by R(locked amount) | savings: self-held or locked XR, "in proportion" |
| Raise | "No token raise for a couple million" | simulation has investors at 30% | one sale of $81M–$727M; bonds; no equity sold |

*Sources: XR Language — Brief (2026-10-03); XR Suggestion Bar (2026-10-04); Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Rei — The Deck (2026-10-17); Spaceyard (2026-10-19)*

## Units: Rei, XR and the folds {#rei-units}

Rei is the coin, and XR is how money shows: "balances, payments and prices, and the token every exchange, bridge and price site lists." The prime marks are "folds", lossless groupings that keep numbers readable. 1,000 XR folds into one ⁗ and unfolds any time. Each mark is a decimal place of a Rei.

| Unit | What it is | Count in the first step | Each at 3¢ per XR | Each at $5 per XR ($100B) |
|---|---|---|---|---|
| Rei | the whole coin | 2 | $300 million | $50 billion |
| ′ | savings; 2nd decimal | 200 | $3 million | $500 million |
| ″ | companies; 3rd decimal | 2,000 | $300,000 | $50 million |
| ‴ | homes; 5th decimal | 200,000 | $3,000 | $500,000 |
| ⁗ | marketplace; 7th decimal = 1,000 XR | 20 million | $30 | $5,000 |
| XR | ticker; 10th decimal | 20 billion | 3 cents | $5 |

The $100 billion column assumes the first step sold out and supply is still 2 Rei.

**The word XR changed meaning on 16 October.** In *Prime ticks*, XR was the whole coin: "2 XR, about $300 million each". It had ten decimals, so 0.0000000001 XR ≈ $0.03, and the app dimmed the leading zeros. Saheb's notes from that turn: "Could just be base 10 decimal point. Instead of like the prime mark." "Rei ticker XR." The economics stayed the same: two whole coins worth about $300 million each, with a smallest unit of about 3 cents. Only the name moved, from the whole coin to the smallest unit. *Prime ticks* also retires the marks that "counted Rei until 16 October". The demo café 4marks "keeps its name from the old four-stroke mark". The World, MIAX and Cookbook documents keep the marks as folds.

*Sources: Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16)*

## The supply schedule: the prime staircase {#rei-supply}

Supply sits exactly on a prime and only moves up. Between steps nothing is minted or burned. At a step the whole gap is minted at once:

**mint = next prime − this prime**

The gaps run 1, 2, 2, 4, 2, 4, 2, 4, 6, 2 and on. The logo carries the first four. The mark in *Prime ticks* is a circle cut by four bars 4.2, 8.4, 8.4 and 16.8 units tall, a 1 : 2 : 2 : 4 ratio. The deck: "The logo's four lines are the curve's first four gaps: 1, 2, 2, 4."

| Step | Supply (Rei) | Mint (Rei) | Supply in XR | Deck milestone | v0.6 simulation trigger |
|---|---|---|---|---|---|
| Launch | 2 | 2, as sold | 20 billion | Launch | day 0 |
| 3 | 3 | 1 | 30 billion | Everyday money | day 4: 1,000 people KYC'd in the Token Depository |
| 5 | 5 | 2 | 50 billion | The most human AI | day 8: 1,000 payments landed on Mars |
| 7 | 7 | 2 | 70 billion | Every city on the map | day 13: 10,000 orders on tabs at 4marks |
| 11 | 11 | 4 | 110 billion | Rei off Earth | day 16: $1 million wired in through the app |
| 13 | 13 | 2 | 130 billion | — | day 20: 100,000 sends carried by phones |
| 17 | 17 | 4 | 170 billion | — | day 24: 0.001 XR deposited into the market and withdrawn |
| 19 · 23 | 19 · 23 | 2 · 4 | 190 · 230 billion | — | — |

The XR column uses the 16 October unit and assumes the first step sold out. If part of it goes unminted, "every later total is lower by that much." The simulation's days show the mechanism, not a forecast. Supply stays small (the 100th prime is 541, the 1,000th is 7,919), so the coin divides into decimals.

**What fires a step** changed three times in four days:

1. **14 October:** "a verified human directive set by AGI, such as building a specific mine". The brief flags the weakness: "Ethereum checks the math, not the mine. Whoever confirms a directive controls the unlock."
2. **v0.6:** "The Foundation fixes the list of milestones before launch and publishes its hash."
3. **16–17 October:** the Foundation's policy team publishes each step's rules and milestone before launch, proposes the step when it is met, and shows that it is met. Holders accept by vote through their wallets and locked XR ("the lock's vote"). Step 3 waits until the one sale has closed. The deck names the milestones "the civilization's objectives".

**Where a step lands: savings.**

- XR in your own wallet, outside any circuit, gets its share "with nothing to do". (A circuit is a zero-knowledge program that holds money and proves what it does.)
- XR in a circuit (the app account, a store's till, an exchange, an escrow) grows only if it is locked. ′ is the savings fold. You can withdraw any time; what counts is where XR sits when the step fires.
- The Foundation's and the equity co's XR never share a step and never vote.
- Steps are paid on Rei Chain only, so XR on Ethereum does not share them.

**The documents' own warnings** (counsel to confirm):

- **Snapshot gaming.** XR can move in just before a step and out just after. The fix is an unannounced fire time, or shares weighted by time held.
- **It looks like yield.** Each step "has to read as the curve's issuance, never as interest", and it is never paid from revenue.
- **Steps are large.** "Step 3's 10 billion XR lands on about 1.87 billion if the sale clears at 6 cents." If all of that public XR sits in savings, it grows about 6.4×.
- **Whose work.** "Milestones tied to the company's work read as profit from its efforts. Network-use milestones read better."
- **Tax.** Each step is likely income when it lands (Rev. Rul. 2023-14).

**What the curve does to ownership (derived).** Neither company shares a step, so each step dilutes both. The table is arithmetic on the documents' rules and assumes all non-company XR sits in savings.

| After step | Both companies, sale sells out | Foundation alone | Both companies, sale clears at 6¢ | Foundation alone |
|---|---|---|---|---|
| Launch (2) | 69.0% | 50.0% | 69.0% | 50.0% |
| 3 | 46.0% | 33.3% | 25.9% | 18.8% |
| 5 | 27.6% | 20.0% | 11.5% | 8.4% |
| 7 | 19.7% | 14.3% | 7.4% | 5.4% |
| 11 | 12.5% | 9.1% | 4.3% | 3.1% |

The two companies drop under CLARITY's 20% line by step 7 on a sell-out, or by step 5 at a 6¢ clear. In the MIAX brief's words: "both shares fall as supply grows."

*Sources: Prime ticks (2026-10-16); Rei — Brief (2026-10-14); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Deck (2026-10-17); derived arithmetic as stated*

## Prime rata: splitting a step by Riemann's R {#rei-prime-rata}

Prime rata pays each holder in proportion to R(balance) rather than balance. Because R bends, small holders gain a little and large ones give a little up. The rule appeared on 14 October, hours after Saheb asked a Claude session one question.

**The question.** At 00:35 UTC on 14 October: "is riemann what generates prime number staircase." The answer was the explicit formula. The prime-counting function π(x), the number of primes up to x, equals Riemann's smooth curve minus one wave per zeta zero:

`π(x) = R(x) − Σ_ρ R(x^ρ) − 1/ln x + (1/π)·arctan(π/ln x)`

Each zero ρ = ½ + iγ adds a wave of about √x·cos(γ ln x). The session checked it: at x = 100.5 the true count is 25, R alone gives 25.762, and R with the first 100 zeros gives 25.232. R itself is

`R(x) = Σ_{k≥1} μ(k)/k · li(x^{1/k})`

where μ is the Möbius function (+1, −1 or 0 depending on a number's prime factors) and li is the logarithmic integral, the standard smooth estimate of the primes below x.

**The 14 October rule.**

`new_i = R(b_i) / Σ_j R(b_j) × (p_{n+1} − p_n)`

Here b_i is holder i's balance and p_n is the current prime. Equal balances still split evenly. The split runs "first across top-level accounts, then inside each rail." The brief's worked example is gate 3. The Foundation and "the ERC basket" each hold 1.00 Rei, so the 1.00 Rei unlock splits 0.50 and 0.50. The basket then splits its 0.50:

| Holder | Before (Rei) | R(balance) | Share (pro rata in brackets) | Receives (Rei) | After (Rei) |
|---|---|---|---|---|---|
| H1 | 0.50 | 0.6635 | 42.5% (50%) | 0.213 | 0.713 |
| H2 | 0.30 | 0.4975 | 31.9% (30%) | 0.159 | 0.459 |
| H3 | 0.20 | 0.3993 | 25.6% (20%) | 0.128 | 0.328 |

Every value was recomputed for this chapter and matches the brief. For balances below 1 the figures come from the Gram series, `R(x) = 1 + Σ_{k≥1} (ln x)^k / (k · k! · ζ(k+1))`.

**The v0.6 rule: "prime root".** The simulation feeds R a much larger number: the amount locked, counted in billionths of an XR. At that scale R tracks the real prime count. R(1,000) = 168.4 against 168 primes; R(1,000,000) = 78,527 against 78,498. "So a weight is roughly how many primes sit below a holding."

- A holder with 0.00005 XR locked weighs 5,133. The Foundation's 1 Rei is 20,000 times as much "but weighs only about 9,900 times as much" (recomputed: 9,905).
- Across 3,000 random holder sets, every unit was paid out, richer holders always got more, the smallest holder grew a median 3.2× faster than supply, and "inequality fell at every milestone."
- Weight is counted per KYC'd holder, "since splitting a holding across keys would otherwise gain up to 20 times."

**The unit fed to R sets how progressive it is.** This is our reading of the two examples. Near 1, R is far from a straight line, so 50/30/20 becomes 42.5/31.9/25.6. Near a billion, R(x) ≈ x / ln x bends slowly, and 20,000× the holding gets 9,905× the weight. The brief already lists "R needs a fixed precision and rounding rule" as open. The choice of unit belongs beside it.

**The Token Depository.** In v0.6 every mint goes into the KYC'd Depository. "Deposits unlock only at an expansion, and holders must relock to share in the next one." Rei on a phone, on a tab, in the market or "lent to the desk" gets nothing. The page calls it "the strategy that won Axelrod's tournaments: cooperate, reciprocate, forgive." In the run, the Depository held 80.1% of supply at launch and 96.1% by day 30. Investors rose from 30% to 34%, and people ended at 11%. "Saheb's 0.15, lent to the desk, at 0.9%": 0.15 of a 2-coin supply is 7.5%, diluted to 0.88% of 17 because lent coins share no step (derived).

> [!tension] The World, MIAX, Cookbook and Deck documents pay each step "in proportion" and never mention R, yet the name 零 rests on R ("the zeta zeros that tie the unlock curve to the split"). Is prime rata still the rule?

*Sources: Session "Riemann hypothesis and prime staircase" (2026-10-14); Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); recomputation for this chapter*

## Issuance: who holds the first step {#rei-split}

The first step splits 50 / 19 / 31 of whatever is actually minted. "For every 31 XR the sale sells, 50 XR are minted to the Foundation and 19 to the equity co." Unsold XR is never minted.

| Holder | Share | If the sale sells out | At 3¢ | At $100B | Terms |
|---|---|---|---|---|---|
| The Foundation | 50% | 10 billion XR (1 Rei) | $300M | $50B | Moves only by holders' vote (grants for work on Rei) or capped, published treasury sales; never by its board alone; never shares a step or votes |
| Equity co and team | 19% | 3.8 billion XR | $114M | $19B | Team pool locked a year, then unlocked monthly over three years; treasury pays XR for work, never sells on the book |
| Everyone who buys | 31% | 6.2 billion XR | $186M | $31B | Sold once, at launch; the ladder raises up to ~$720–730M |
| Later steps | all of each step | step 3 adds 1 Rei, step 5 adds 2 | — | — | Paid into savings once holders accept |

**Three bodies run Rei.**

- **The Foundation** keeps "the long arc": the curve, each milestone, savings, and governance of XR and of Rei's model "on its way to AGI". It has an independent board and earns nothing. It sells its own XR over time on the same book, up to $50 million per 12 months (§202 of the House CLARITY text, inflation-adjusted). The sales follow a published schedule, go through a registered broker-dealer and allow no buyer above 10% of supply. The first is proposed for 2028. The decision log dates the choice: "At 21:24: the Foundation funds its treasury by selling its own XR over time, up to CLARITY's cap."
- **The equity co** ("Rei") employs everyone, sells XR once, and runs the app, the map, the marketplace circuit, Rei Pay and, after the sale, the market-making desk. Everything it, its people and its desk hold "stays under 20%": the 19% plus a desk capped at half a point.
- **The model company** trains Rei's model every two weeks on what people share. Who owns it and how it is paid is "to decide".

The option pool is set now, while the company is private: "around 10–15%, at a low 409A price" (409A is the IRS valuation rule for private-company options).

*Sources: Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Rei — The Deck (2026-10-17)*

## The launch: one sale up a ladder on MIAX's book {#rei-one-sale}

Rei raises money once: at launch, from anyone who passes KYC, at the same prices, on a public exchange book. There is no seed round, no private sale and no equity. Bonds carry the build until then.

> [!quote] "Selling nothing while Rei is being built is what keeps the sale clean." — Rei — The World a $100 Billion Coin Makes, 2026-10-16

**The mechanics.**

- **Single-sided.** The equity co posts sell orders only, never bids. The orders run from $0.03 to $0.30 over 6.2 billion XR, "in steps an equal percentage apart". They sit on MIAX's XR/USD spot book, reached through the FCM (futures commission merchant, the broker that holds customer money), with Rei's site as the door.
- **Who.** Every buyer signs in with Rei, passes KYC and is 18 or over. "Funds and people buy the same way, from the same book, at the same prices." Staff don't buy. Each buyer is capped at 60 million XR, counted with affiliates.
- **When.** Testnet runs first with test XR. Mainnet opens with the sale, proposed for 1 November 2027, for 30 days, if the CFTC clears XR spot by 30 June 2027. "XR doesn't exist before the first fill": the first fill mints the first XR, and Rei Pay and bank sends start with it. Trading starts at once. Unfilled orders are cancelled at the close and never minted, "and the equity co never sells again."
- **After.** 5% of the dollars fund two-sided market making under published rules, "never a floor". The desk starts only after the close, so the equity co never bids in its own sale. "MIAX takes no stake."

**The arithmetic.** Equal-percentage steps mean the price rises by the same factor for each equal slice sold. The ladder spans a tenfold rise, so each doubling of price sells 6.2 billion × log10 2 ≈ 1.87 billion XR. The documents' formulas: XR sold = 6.2 billion × log10(P / 0.03); dollars = 6.2 billion ÷ ln 10 × (P − 0.03); what exists = sold ÷ 0.31.

| Ladder clears at | XR sold | Dollars raised | XR that exists | 5% to market making (derived) | 60M cap as share of supply (derived) |
|---|---|---|---|---|---|
| $0.06 | ~1.87 billion | ~$81 million | ~6.0 billion | ~$4 million | 1.0% |
| $0.15 | ~4.33 billion | ~$323 million | ~14.0 billion | ~$16 million | 0.43% |
| $0.30 (sell-out) | 6.2 billion | ~$727 million | 20 billion | ~$36 million | 0.30% |

The deck prints $727M; the World and MIAX documents say "about $720–730 million". The formula gives $727.0M.

**Why 60 million.** If the CLARITY Act returns, anyone who gets 1% or more of supply from the issuer counts as an insider. 60 million XR stays under 1% once the sale sells at least 1.86 billion XR, "the 6-cent mark."

> [!number] 60,000,000 XR — the most any one verified buyer can take
> Under 1% of supply once the ladder passes 6¢.

**The legal route for the sale.** The target, "if counsel confirms", is a sale of a digital commodity under the 17 March 2026 interpretation, "with no registration and no cap". That needs Rei Chain, the circuit and Rei Pay working from the first fill. MIAX must also show the contract "is not readily susceptible to manipulation". The MIAX brief adds exemptive relief for the sale on MIAX's book (Exchange Act §36; CEA §4(c)). If counsel does not confirm, the fallback is a fixed-price securities sale through a broker-dealer, off MIAX's book: a registered offering; Regulation A Tier 2, up to $75 million a year (2.5 billion XR at 3¢); or, if adopted, Regulation Crypto Assets ($20 million or $75 million a year).

**What changed.** On 14 October the decision was "No token raise for a couple million." Two days later the plan is a public sale of $81M–$727M. The deck ends: "Investors are asked to hold the date, not to buy."

*Sources: Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Rei — The Deck (2026-10-17); Rei — Brief (2026-10-14); ladder arithmetic recomputed*

## Rei × MIAX: one book, one account {#rei-miax}

Rei needs one exchange to do three jobs: host the launch, carry every payment and run the derivatives market.

> [!quote] "The ask is one agreement: the market, dollar clearing and the fees." — Rei × MIAX — The Brief, 2026-10-16

| Product | What it is | Margin | Filing |
|---|---|---|---|
| Bitcoin and ether perpetuals | one perp each, funding hourly | dollars | 40.3 approval, as with Kalshi's bitcoin perp of 29 May 2026 |
| Dated options on the perps | calls and puts with set expiries | as the perps | 40.3, with the perps |
| XR/USD spot | XR delivered on chain to the clearinghouse | fully paid in dollars | rules under 17 CFR 40.6 that treat spot as futures, as Bitnomial's do |
| XR perpetual and options | the same, on XR | dollars | 40.3, once XR spot is deep |

40.3 is CFTC approval of a contract; 40.6 is self-certification of rules. A perpetual is a future with no expiry, held to its underlying by a funding rate, a periodic payment between longs and shorts. The CFTC approved Kalshi's bitcoin perp because bitcoin has "a deep, broadly distributed spot market." XR has none, so its spot trades first.

**Every payment is a trade on the book.** Rei Pay is not a card. When you pay, the app sells exactly enough of your XR on MIAX's book "as your own order", and the equity co fronts the store's dollars from a float "weekends included". Payouts work the same way, with dollars sent over RTP or FedNow (the US instant-payment rails). "Payments are never internalized: every payment is a public trade." So "payment volume is spot volume." KYC'd accounts' XR sits with Dorman Trading, the FCM that MIAX's parent bought (announced October 2022).

**Dollar clearing, around the clock.** MIAX Futures' own clearinghouse would margin and settle in dollars 24/7. Variation margin is booked hourly, cash moves when the wires run, and a liquidity line covers nights and weekends (Part 39: 39.11, 39.14, 39.15, 39.18). OCC, which clears MIAX's financial futures, "holds no crypto". USDC stays on Ethereum. On leverage: "Clearing margin covers 99% of one-day moves; Cboe asked for 44% when bitcoin futures launched in 2017. A new coin starts well under 10x." Perp indexes leave out the equity co's own trades.

**Groundwork.** "The American Perpetual work, about 7,400 documents, already covers a perpetual's funding engine, product chapter, clearing at MIAX, 40.3 package, member build and surveillance." What is new: dollar margin around the clock, an XR spot rulebook, and rules for a halt or a frozen address. MIAX will ask for the legal opinion; a Core Principle 3 showing for a token "with no trading history, sold only by its issuer"; the clearing and 40.3 packages; step integrity; agent logs; where the dollars go; and the full AP disclosure. On fees: "MIAX keeps its exchange and clearing fees; any split is the first term to agree."

### American Perpetual inside the same account

Rei's app would be a consumer door to AP's single-stock perps, so "stocks, crypto, XR and collectibles are in one account." Each contract is "a no-expiry, cash-settled future on 100 shares of one US stock, held to its stock by an hourly funding rate". The perps list on MIAX Futures' Onyx and clear at OCC. Margin has a 15% federal floor (leverage near 6.7×). There are 35 names, "SPY through SpaceX", trading 4 a.m. to 8 p.m. ET (see [Chapter IV](#ap-contract)).

- **The door.** The equity co registers as an introducing broker with the CFTC and NFA (an IB takes orders but holds no customer money) and files Form BD-N as a notice broker-dealer for security futures. Dorman carries the accounts.
- **The agent.** "Say 'hedge half my XR with the perp,' then approve what it drafts." It never picks trades, because that would make it a commodity trading advisor.
- **Apple.** Guidelines 3.1.5(iv) and 3.2.1(viii) keep stock perps in the web app.
- **The race.** Coinbase, Kalshi, Bitnomial, Nadex and ICE Futures filed Form 1-N notices in September 2026; "MIAX was not among them." CME sued the CFTC on 18 June 2026, arguing that perps are swaps.
- **The bigger shape.** "The May 2026 note to Dorman … buy MIAX's DCM and DCO, Dorman and Connamara, with a first listing targeted for Q1 2027." (A DCM is a CFTC-licensed futures exchange; a DCO is a clearinghouse.)

*Sources: Rei × MIAX — The Brief (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei — The Cookbook (2026-10-16)*

## The coordination problem: AP's 60% reaches Rei's perps {#rei-ap-carveout}

Rei and American Perpetual want the same MIAX perps, and Saheb owns both sides. AP's draft licence is written to capture every perpetual MIAX lists. Unless Rei is carved out before the AP papers are signed, every Rei perp at MIAX pays AP first.

> [!quote] "Carve Rei out of the American Perpetual deal and its IP assignment before either is signed. As drafted, a Rei perp at MIAX owes AP 60% of its fees and falls under AP's exclusivity." — Rei × MIAX — The Brief, "For Saheb, not for MIAX", 2026-10-16

**Why the licence reaches Rei.** The Master Perpetual Products License Agreement (MPPLA v2.8, final text of 30 September 2026) is drafted for the whole category (see [Chapter VI](#deal-mppla)):

- **¶1, the definition.** A Perpetual Product is "any exchange-traded derivative listed on the Exchange or on any venue of the Exchange or an Affiliate, in any asset class, on any underlying". It counts if it has no scheduled expiry, a periodic funding payment, or a "perpetual" label. Options with a perpetual leg count too. Rei's bitcoin, ether and XR perps and their options all fit.
- **¶5(a), the rate.** "Sixty percent (60%) of Covered Fees … one rate, flat, for every Perpetual Product; no computation reduces it and it is never amended downward." Covered Fees are fees actually collected, net only of Section 31.
- **¶4(b).** "The Royalty follows the products, not the design." A Rei perp pays even with none of AP's design in it.
- **¶3(a), exclusivity.** One exclusivity over every Perpetual Product on US DCMs and national securities exchanges, "held by paying". It releases if nothing lists within 18 months, or if no royalty accrues for 12 straight quarters.
- **The IP Assignment (28 September form)** sweeps all of Saheb's pre-formation perpetual-product work into AP: "retained IP none". The June form had kept back an FCM/BD, a trading app, a DCM/DCO company and trading strategies.

> [!number] 60% — AP's share of MIAX's fees on any perpetual, any underlying
> As drafted, that includes the bitcoin, ether and XR perps Rei plans at MIAX.

**Why it is a real conflict.**

1. **AP's own case counts crypto.** AP's Class Expansion memo makes crypto majors (BTC · ETH · SOL · XRP, about 91% of listable spot flow) its second class, "READY TO BUILD". The Investor Master prices a "crypto-like" path. These are the same perps Rei wants to bring first.
2. **AP is about to gain a co-owner.** The plan is one sale of 10% of AP (10,000,000 of 100,000,000 units) to one buyer, with Saheb keeping 90%. Once a buyer has paid for a royalty on "every perpetual product", a carve-out would likely need that buyer's consent.
3. **One fee pool, three claims.** At 60% to AP, MIAX keeps 40% of the fees on Rei's perps, and Rei's to-do still lists "any split of MIAX's fees".
4. **Routing.** Rei's agent and its introducing broker would steer users to products that pay Saheb's LLC. The documents call it "the routing conflict". The disclosure covers four things: Saheb's interest in American Perpetual LLC and Greyline, Inc.; the royalty on all of the product's volume; approval by independent directors; and the routing conflict.
5. **Gemini.** Rei's public-home plan buys Gemini, a DCM that "plans futures, options and perps". The documents do not say whether AP's US exclusivity would reach a Rei-owned Gemini.

**Where it stands.** The AP signing set was final on 30 September, with the record's last word "Nothing sent". There is no evidence of a signature (see [Chapter VI](#deal-status)). The Rei documents propose that "Rei's bitcoin, ether and XR perps are carved out of it first". Neither the MPPLA nor the IP Assignment text in the record contains a carve-out. One question for counsel that the documents do not raise: if the XR/USD spot contract, listed under rules "that treat spot as futures", has no scheduled expiry, could ¶1 reach it too?

> [!tension] The same bitcoin and ether perps are AP's planned second class and Rei's planned first products at MIAX. AP's draft takes 60% of the fees on both, "never amended downward", with Saheb on both sides. The carve-out has to be written into the MPPLA and the IP Assignment before AP signs and before the 10% sale; after that, MIAX and the buyer must agree.

*Sources: Rei × MIAX — The Brief (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); MPPLA v2.8 execution form (2026-09-30); IP Assignment execution form (2026-09-28); AP Class Expansion memo (2026-09-14); AP Investor Master; notes 01, 02 and 10*

## The stack: two architectures, one day apart {#rei-stack}

The documents describe two machines for the same coin. *Prime ticks* (v0.6) passes self-proving money objects phone to phone over 5G, with no Ethereum. The World, MIAX, Cookbook and Deck documents put Rei on a standard Ethereum rollup and say phones are not nodes. The rollup is the later design and the one the deck pitches. The phone design is the one that has been benchmarked.

**Before both (14 October).** The first brief's chain has "no blocks and no clock, only proofs". Each tick "carries every earlier tick inside it, so it never grows." Ticks follow Lamport's 1978 logical clocks, so "Earth and Mars can tick separately and fold together later." "Money streams," settled as one net change per account per tick. The alternative was "a June design": a secure chip in each phone that "refuses to sign the same state twice" and "works offline and off-world". The brief also lists what settling on Ethereum would not secure: the gate, the upgrade key, off-chain data, circuit bugs, quantum safety (Ethereum's switch is targeted around 2029) and the Mars clock.

| Question | v0.6 — Prime ticks (16 Oct) | Rei Chain — World, MIAX, Cookbook, Deck (16–17 Oct) |
|---|---|---|
| Ledger | "money as objects, not a chain"; "no state root and nothing to sync" | Arbitrum Nitro rollup, deployed and run by Caldera, settled on Ethereum |
| Phones | "every iPhone with the app that is on is a hop" over its own 5G eSIM | "Phones aren't nodes"; each is "a proof node" holding a Privy wallet |
| Network | carrier 5G; relays for carrier-grade NAT (>90% of cellular networks); a VPN-style tunnel; own MVNO later; 5G sidelink ~2027 | "There is no 5G network, no towers and no device to build." Caldera's sequencer, 99.99% uptime |
| Offline | needs a signal (the June chip worked offline) | "Rei has no offline payments." |
| Ethereum | "no Ethereum" (since 15 October) | canonical ERC-20; XR is the gas, paid by the equity co; forced inclusion via Ethereum |
| Proofs | rei-stark: a validity proof of balances, not yet hiding | Noir circuits; Barretenberg (UltraHonk) now; World's ProveKit (WHIR) for post-quantum |
| Other worlds | one zone per planet; Mars payments land 13 one-minute ticks later | a "Dome" circuit settles locally and "reaches Rei Chain on the next link" |

**What has been measured.** The v0.6 bench ran on 2 CPU cores at a conjectured 128-bit security level, proving balance arithmetic only:

| Accounts in the tick | Time to prove | Proof size | Time to check |
|---|---|---|---|
| 1,024 | 0.34 s | 76 KB | 7.1 ms |
| 4,096 | 0.54 s | 109 KB | 6.2 ms |
| 16,384 | 2.0 s | 147 KB | 18.6 ms |
| 65,536 | 8.0 s | 195 KB | 10.8 ms |

"Sixty-four times more accounts made the proof only 2.5 times bigger, while proving took 23 times longer." The proof checks three things: after = before + in − out; no negative balance or overflow (30-bit amounts for now); and each tick sums to zero, or to exactly what crossed to another planet. A forged tick was rejected. State hashing ran at about 58 account updates a second, "one reason there is no state root." Not yet built: signature checks, links between moves, recursion, hiding, the market circuit. The simulation ran 43,200 ticks on 120 seeds and moved 3,620 payments to Mars and 1,563 to the Moon, with every unit accounted for.

For the rollup the documents cite outside figures only. Groth16 proofs take 0.14–0.75 s on an iPhone 16 Pro (mopro). ProveKit takes "a few seconds on a standard phone, with proofs of about 1 MB." Memory is the limit: an app gets about 3 GB, and phones with under 3–4 GB of RAM fail. Fallbacks are an attested server prover for old phones and Circom/Groth16 for one hot path. The rest is off the shelf: Privy wallets (key shares in trusted execution environments), Solidity or Rust on Stylus "at a tenth of the gas", and blocks "as fast as 250 milliseconds". The MIAX brief maps Rei onto Visa's five-layer stablecoin stack: "Rei fills each one, and is the layer zero under them." That echoes the XR language's "Layer 0 is the base trust layer."

> [!tension] Documents of the same day say both "no Ethereum … Payments go iPhone to iPhone" and "settled on Ethereum … There is no 5G network". Only the first has a benchmark; only the second has vendors, a cookbook and a deck. No document records the choice as a decision.

*Sources: Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Rei — The Deck (2026-10-17); XR Language — Brief (2026-10-03)*

## The world a $100 billion coin makes {#rei-world}

At $100 billion, with the first step sold and supply still 2 Rei, one XR is $5. The document's test is daily use: "If XR is only traded, none of it happens."

> [!number] $5 — one XR at a $100 billion coin
> A Rei is $50 billion; a ⁗ (1,000 XR) is $5,000.

**A day in it.** At 7:40, Rei Pay sells 1 XR and pays Slate Coffee $5. At 8:15, your agent and Kiko's settle a road bike at $380 (76 XR) "before either of you types a word." At 12:30, a review of Kumo's ramen counts "because you paid." At 15:00, you buy into Ade's picture coin for 2 XR and share a PnL (profit-and-loss) card. At 18:00, Rei drafts an offer on a two-bedroom on Lantern Row inside a data room. At 21:30, "send him $200 of rei" sends 40 XR to your brother in the Mars dome, and it lands 14 minutes later.

| Item | Value | Basis |
|---|---|---|
| Cap at the 3-cent floor | $600 million | 20 billion XR × $0.03 |
| Holders, if the 31% sat at $1,000 each | 31 million | $31 billion ÷ $1,000 |
| Circuit fee | 1% of marketplace trades and sales | payments and sends are free |
| If $1 billion a day settles in the circuit | $10 million a day | 1% |
| What the equity co keeps | $1.8–3.7 billion a year | depends on the share that is coins, where half goes to the maker |

**Who earns what.** Moving XR is free. When XR touches Rei Chain, the equity co pays the gas. The equity co earns "what Rei, the agent, earns":

- 1% of marketplace trades and sales, half to the maker on coins;
- service fees;
- the market-making spread;
- Astra, the default AI model, sold by the token "at a fixed rate 20 to 30% above what serving it costs";
- the one sale's dollars after market making;
- later, a share of Rei Visa interchange and a posted fee on instant bank sends, charged "on purpose".

**Accounts and money.**

- **Three tiers.** A Wallet (self-custody, XR only, a passkey, no KYC). An Account (handle, portal and posts; email or phone; 13+). Account + KYC (18+), which adds custody, Rei Pay, agent spending, payouts, the Visa and tax forms. No accounts under 13, "which keeps Rei outside COPPA's consent rules."
- **Money in and out.** You wire dollars in once; balances live in the app's database, and "the circuit proves it adds up, so no stablecoin is needed." Payouts reach any bank or card in seconds over RTP or FedNow, and abroad over SEPA Instant, PIX or UPI. "XRP asks banks to hold a token … Rei turns that around: it prefunds dollars."
- **Later.** A Rei Visa (2028, proposed). A Rei Dollar stablecoin (2028, proposed), once the rules under the GENIUS Act (signed 18 July 2025) are final.
- **Tax.** Every XR payment is a sale, reported on Form 1099-DA.

**DeFi, licensed.** Every piece runs under its own licence, on one page: savings; a non-custodial swap for collectibles only; XR spot, perps and options at MIAX through an FCM; dollars under money-transmitter licences, paying no interest; borrowing under a state lending licence; coin launches with no roadmap and no yield; and deals from data rooms through escrow and brokers.

**The most human AI.** "The payment is the label." Agent chats are synthetic, but each ends in a real choice (connect, buy, pay, review), so every conversation is labelled by what a person did. A model company trains a new checkpoint every two weeks on what people choose to share; identity checks are never shared. Astra is the default model. An uncensored model on GLM-5.2's open weights (Z.ai, MIT licence, June 2026) runs self-hosted, on the web only, for verified adults. The document flags that Z.ai has been on the Entity List since January 2025.

**The handoff.** The equity co publishes what it can never do: mint outside the curve; move, freeze or redirect anyone's XR; buy XR to prop its price; or let its own XR share a step or vote. Anyone can force a transaction through Ethereum, and upgrades wait behind a timelock longer than the seven-day exit window. Within three years of launch the keys go to the Foundation, "and it holds only if the Foundation's board is independent of the equity co."

*Sources: Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Deck (2026-10-17)*

## The Cookbook: building a Rei site {#rei-cookbook}

The Cookbook turns Rei into a platform. Any site, "a café, a contractor or an exchange", can take Rei money under its own licences. "Nothing is built yet." The API ships with the testnet (proposed 31 March 2027), and every code line is illustrative.

**Five steps.**

1. Add Sign in with Rei; "signing in moves nothing".
2. Take deposits into your own circuit, as custodian, under your own licences.
3. Add recipes.
4. Take Rei Pay: customers pay in XR, and you are paid in dollars.
5. Give Rei a skill over MCP, so people's agents can order, book and pay.

The sample store is one line: `circuit.store({ handle: '@kumo', menu, reviewBudget: { xrPerReview: 50 } })`.

**Rules every circuit keeps.** Bearer XR: whoever holds the key holds the money. A send is final. The site is the custodian. Each tick carries forward the check on every earlier one. No company key can move, freeze or redirect XR. Money needs a licence. Review rewards never depend on sentiment (the FTC rule). In the App Store app, no crypto for completing tasks.

| Group | Recipes | Key rules |
|---|---|---|
| Money | Wallet and Sign in with Rei · Send · Fold · Savings · Account · Rei Pay · Bank send · Card · Stream · Escrow · Bridge | Sends free and final; Rei Pay is money transmission and files 1099-DA; instant bank sends carry a posted fee; withdrawals to Ethereum take seven days |
| Market | The one sale · Foundation treasury sale · Handle coin · Token and picture coin · Swap market · Collectibles and pets · Posts and passes | Handle coin = 1 million units; a picture coin's "billion units sell in its handle's coin, each sale putting the handle coin back as buy orders"; swap 1%, half to the maker |
| Place | Store and review budget · Services · Listings · Delivery · Portal · Room · Dome | Room = shared drive + group chat + escrow; Dome is "delay-tolerant: offers are promises with check times" |
| Agent | Agent account · Agent skill · Quant API | Approvals "always, over $20 or never"; "one on-chain order book and one API; XR spot, perps, stock perps and options at MIAX through Dorman" |

Before the beta, Noir must pass a benchmark on real iPhones. If it misses, "the hot path moves to Groth16." Open: unannounced snapshot or time-weighting, and "Which recipes do developers need first?"

*Sources: Rei — The Cookbook (2026-10-16)*

## The Deck: thirteen slides {#rei-deck}

The deck (created 17 October, 07:10 UTC) is "the 64-page brief cut to its core". It runs in six sections: picture, experience, money, intelligence and network, raise, and where it goes. It adds the four named milestones and the ask to investors: "hold the date, not to buy."

| # | Slide | Headline | What it carries |
|---|---|---|---|
| 1 | Cover | Rei — Intercivilization money. America's consumer internet crypto. | "Rei (零, said 'rey') is the whole coin. XR is its ticker and the money you see." |
| 2 | World | The world a $100 billion coin makes. | XR at $5; coffee 1 XR; bike 76 XR; $200 to Mars; "Illustrations of scale, not forecasts." |
| 3 | Less phone | Rei makes life less phone. | Agents agree first; limits like "over $20, ask me"; "Rei speaks XR" |
| 4 | Map | Everyone, on one map. | Avatars, pets in portals, stores with Rei Pay; "A delivery is a line of light." |
| 5 | Handles | Every handle is a coin. | 1 million units each, ranked; "@rei pay ade half" in iMessage |
| 6 | Lossless | Lossless money. | No fee to move, nothing burns; the company "confers nothing on XR but fun" |
| 7 | Curve | One law: the prime curve. | 2 → 23; milestones at 3, 5, 7, 11; the logo's gaps 1, 2, 2, 4 |
| 8 | AI | The most human AI. | You and your Rei → agents talk first → a real choice → a new model every two weeks |
| 9 | Phones | No hardware. Just phones. | Noir, Barretenberg, ProveKit; Rei Chain on Nitro and Caldera; anyone can make a Rei site |
| 10 | Sale | One sale, for everyone. | 50/19/31; $81M / $323M / $727M; 60M XR per buyer |
| 11 | Bodies | The long arc. Today's work. | The Foundation holds half; the equity co runs everything today; keys to the Foundation within three years |
| 12 | Mars | The same money on Mars. | "Step 11 of the curve: the first payments settled on another world"; "This is alien money." |
| 13 | Close | Hold the date. 1 November 2027 (proposed) | Bonds open to lenders now; testnet and cookbook by 31 March 2027; "MIAX is asked to make the book and file the products." |

The close carries the disclaimer: "A vision and planning document, not an offer to sell or a solicitation of an offer to buy XR, bonds or any security."

*Sources: Rei — The Deck (2026-10-17), deck.json and all 13 slides with speaker notes*

## XR: from a language to a ticker {#rei-xr-language}

XR began on 3 October as a language for organizing people. Thirteen days later it was the coin's ticker, and every Rei document was to be written in it.

> [!quote] "XR is a language for organizing people, built on mixed reality. The goal is the greatest organization in the world." — XR Language — Brief, 2026-10-03

**The language.** XR "never talks in terms of where". Its rules: no where, no distance ("there's no Far"), no leaving ("XR is on all the time"), plans are fine, and plain words only. It has two kinds of sentence: what is settled, and what is promised with a time it can be checked. "A lie is a broken promise." Kept promises are your standing, "the way a credit history is." Opinions become bets: "This deal loses money by March." The only question is "Will you?", answered "Yes, by Friday" or not at all. Mistakes are settled, not erased, "the way a clearinghouse folds yesterday's number into today's."

**Three levels.** Plain XR. XR + ZKP, which proves things without showing them (a zero-knowledge proof shows a statement is true without revealing the data). And zk tick compression: "Each tick, the new proof swallows the old one plus whatever just happened." The proof stays the same size while the information behind it grows, and "Post-quantum is necessary." The brief's "open edge" is compliance: a firm "could hand regulators a running proof that it stays within its limits every second, without showing a single position."

**The XR Suggestion Bar** (4 October) put the language into an iMessage keyboard with Classical and Quantum modes. Its cards: "Ask. Needs a check time." · "Promise. You are on the hook." · "Promise with a condition." ("legal clears Wednesday") · "Settled. The record shows it."

**How it reached Rei.**

- The tick is the language's idea. On 14 October it is "one step of the chain". In v0.6 it is how often a phone checks in.
- On 14 October the ticker REI was "already taken by REI Network". On 16 October Saheb's note reads "Rei ticker XR." No document says why XR was chosen. The only earlier XR in his work is the language and the October 2025 glasses note.
- Decided on 16 October: "all text, from the brief to the app, is in the XR language." The deck: "Rei speaks XR: plain, settled sentences, and offers that are promises with check times." On Mars: "Agents suit the delay, because an offer is a promise with a check time."
- The first word on the language's list is **Spaceyard**, which became a design on 19 October.

*Sources: XR Language — Brief (2026-10-03); XR Suggestion Bar (2026-10-04); Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Deck (2026-10-17); XR (2025-10-15)*

## Consumer surfaces: the map, Spaceyard and iMessage {#rei-surfaces}

Rei is built to be used as a social app first and a coin second. Three surfaces carry it: a one-page app with a 3D map, an iMessage pop-up, and Spaceyard.

**The one page.** "Rei, your agent, on the left; the map on the right." The map is "friendly and 3D, like Snap's map". Avatars stand on the corners. Pets sit in portals: Reiki (free), Neko, Usagi and Ryu the Mars dragon. Stores take Rei Pay and are reviewed only by payers. A portal "opens a gray window": a business page, a social page or a thread. Agents talk first, and people swap numbers only when both agree.

**Handles and picture coins.** "Every @handle is a coin of its own, a million units sold on the book like any launch," ranked by market value, "so a handle's price is its standing." Picture coins are priced in their handle's coin, "so buying it buys the handle too." They stay collectibles: "A handle that promises its holders a cut makes its coin's sale an investment contract."

**Rei inside iMessage.** "The whole of Rei opens as a pop-up in the conversation," through a native iOS app with a Messages extension, "Apple's official route". (Apple shut out Beeper Mini's unofficial iMessage in December 2023.) "The extension only sends the bubble": the proof is made in the app, because extensions get little memory. Coin launches and crypto futures stay in the web app (Apple 3.1.5). The working prototype is **Nimbus**, built in a Claude Code session from 21:18 UTC on 15 October to 00:15 UTC on 16 October. It is an iOS app with a Messages extension that streams AI answers into a thread, served by an invite-only Cloudflare Worker capped at 200 answers per person per day. Its 91 iOS tests and 84 server tests pass. Saheb's brief: "imessage is important." Nimbus itself has no crypto.

**Spaceyard and SPY** (19 October). Spaceyard is a live-stream social map ("SoHo · 214 live") with an agent that "Learns you. Finds your people." Its in-app currency is **SPY**: a balance of 12,480 SPY; "Stream 30 min, earn SPY. Real streams only. Spend it on your look"; tips ("lena tipped 100 SPY"); and avatar drops priced in SPY (Halo 4,000, Field cap 1,500, Studio cans 2,200). Kiko, Ade, Mia and the store Kumo also appear in the Rei documents, so Spaceyard reads as a sibling of Rei's map. How SPY relates to XR is not stated. SPY is also the ticker of the S&P 500 ETF at the head of AP's 35 names.

**The mark.** On 14 October the mark was eight nested blossoms, white to deep red: "every tick holds the one before it". By 16 October it was "the barred sun in slate, gray, blue and white", with "red and orange … for Mars". It comes in 11 colourways (Anodized, Ash, Blued, Copper, Edge, Ember, Inverse, RedOrange, Slate, SlateOrange, Vermilion). The app's voice "stays fun money."

*Sources: Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Deck (2026-10-17); session "AI popup with message bubble" (2026-10-15/16); Spaceyard (2026-10-19); Rei coin variations (2026-10-16); Rei — Brief (2026-10-14)*

## The legal route {#rei-law}

Everything rests on one test: XR must "stand alone" as a digital commodity by launch. Every other piece is a licence the equity co holds or rents. "Nothing waits on Congress."

**The status test.** The 17 March 2026 interpretation treats a crypto asset as a digital commodity when its value comes from a working system and it carries no rights "such as generating a passive yield." So XR launches as Rei Chain's gas and as money in the app, "with no yield, revenue share, buybacks or burn." Handle and picture coins rely on the same interpretation's treatment of meme coins as collectibles.

**The CLARITY line.** The House text (H.R. 3633) sets the line at under 20% held by the issuer with its affiliated persons (anyone who got 5% or more from it) and related persons (anyone who got 1% or more). A decentralized governance system counts on neither side, but only without "centralized management". The documents' own reading is that the policy team "reads as centralized management", so "the Foundation's 50% likely counts on the insiders' side, and the House line is not met." Meeting it "would take holders voting the milestones and the model's governance too." Then: "This is Saheb's call." CLARITY is not law. Senate cloture failed 49–50 on 15 September 2026, and the bill "dies on January 3, 2027."

> [!tension] Saheb's 2022 rule was "Decentralization … can only be achieved through policy." CLARITY's test reads Rei's policy team as the centralized management that keeps the Foundation's 50% on the insiders' side.

**Twenty-eight filings in four steps.** The licences are to be held by 30 June 2027 (proposed). The only fixed date was 20 October 2026, when comments on Regulation Crypto Assets closed. The record does not show whether Saheb's comment letter went in.

| Step | Count | Filings and licences |
|---|---|---|
| 1 | 13 | Legal opinion on XR · Reg Crypto Assets comment · custody (state money-transmitter licences, NY BitLicense or trust charter, or Gemini's) · bonds · a public home · FinCEN MSB and Rei Pay · payouts · introducing broker + NFA, CTA or exemption · Gemini partnership · biometric consent · handle and picture coins · a non-custodial circuit (FIN-2019-G001) · data-sharing consent |
| 2 | 8 | Foundation charter and board · iOS app (Apple 3.1.5) · age checks · XR/USD spot (40.6; Core Principle 3) · 24/7 dollar clearing (Part 39) · exemptive relief for the sale (§36; §4(c)) · BTC and ETH perps and options (40.3) · Form BD-N |
| 3 | 2 | Fallback securities sale · lending licence |
| 4 | 3 | XR perp and options (40.3) · Rei Visa · Rei Dollar issuer (GENIUS Act) |
| Ongoing | 2 | AML, OFAC and the Travel Rule · Forms 1099-DA and 1099-K |

Also planned around: the FTC's review rule (since 21 October 2024), California's treatment of precise location as sensitive data, and tax. The Digital Asset Tax Certainty Act, which cleared Ways and Means 38–5 on 16 September, would exempt only network fees up to $10.

### A public home: bonds, AMBR, Gemini

No equity is sold. The equity co borrows by Rule 144A bonds, secured before revenue by shares or a backer; convertibles need a conversion premium of at least 10%. After the sale it reverse-merges into AMBR, which then buys Gemini for stock, so "the company's value would live in a public stock, and XR stays money."

| | Gemini (Nasdaq: GEMI) | AMBR (Nasdaq: AMBR) |
|---|---|---|
| Value | ~$570M ($4.40 on 9 Oct 2026 × 129.65M shares) | ~$150M (~94M ADSs at ~$1.61) |
| Finances | ~$500M debt, $189M cash; revenue $207M, net loss $517M (12 months) | ~$30M cash (30 June 2026); H1 2026 revenue $23.9M, net loss $2.2M |
| Licences | DCM via Gemini Titan (Dec 2025); DCO (30 Apr 2026); GUSD | subsidiaries in Singapore, Hong Kong, Dubai |
| Control | Winklevoss twins ~93% of votes | Michael Wu and Amber Fort ~77.8% (13D/A, June 2026) |

- **Ownership example.** Rei at $1.35 billion, AMBR at $150 million and Gemini at $800 million gives Rei's side about 59%, Gemini's holders about 35% and AMBR's about 6.5%.
- **The alternative.** Taking Gemini private first would cost about $340 million (if the twins roll) up to about $1.3 billion.
- **What it needs.** Wu's consent, a fairness opinion, Nasdaq Rule 5110(a), change-of-control approvals (including New York's for Gemini Trust), HSR filings and CFIUS.
- **The dates.** A letter of intent by 31 December 2026; the merger closed by 31 March 2028.
- **The carve-out the documents admit.** "In a reverse merger, the listed company's holders keep a stake," and convertible bonds "are equity by another name."

The 19 October Hyperbull screen lists both targets: AMBR at a $180M cap and GEMI at $463M, priced on later dates.

*Sources: Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Hyperbull Break List (2026-10-19); Blockchain (2022-10-04)*

## The chats Rei cites, not yet harvested {#rei-chats}

The 14 October brief lists four of Saheb's claude.ai chats as sources. None has been read; the tools used here could not reach claude.ai chats.

| Chat | Date | Link | What may come from it (inferred from dates) |
|---|---|---|---|
| PRIME protocol | 2026-05-25 | https://claude.ai/chat/afa31dbd-5598-4c87-ad71-6352b6b2eff3 | The first prime-supply design |
| Prime token currency | 2026-06-14 | https://claude.ai/chat/7a286d81-d5b0-4963-9acb-98fdd294b432 | The token raise "shelved in June" |
| Private money system | 2026-06-15 | https://claude.ai/chat/d1c764dc-8de1-45e0-9fc4-ef8ee67f855d | "The June design": a secure chip per phone |
| Riemann and primes | 2026-10-14 | https://claude.ai/chat/059b77ce-07f8-46e2-9ae5-27549cecf897 | Prime rata and "Resonance" |

The brief does not tie any single fact to any single chat. The Claude Code Riemann session of the same morning is in hand (see [Prime rata](#rei-prime-rata)). Also cited but not located: the Rei data room (`REI_DATA_ROOM/`: Protocol Spec v0.6, `Product_Notes.md`, the run logs), the code (`rei-proto/crates/rei-core`, `rei-stark`), `_RESEARCH/2026-10-16`, and the "64-page brief" `01_MASTERS/Rei_The_Brief_October_2026.pdf`.

*Sources: Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei × MIAX — The Brief (2026-10-16); notes 14*

## Rei timeline {#rei-timeline}

| Date | Event | Source |
|---|---|---|
| 2022-08-18 | "World of Ohm": one coin across forex, options, clothing, credit | Manifest plan |
| 2022-08-19 | fibonacci prime: empire target F(83) | fibonacci prime |
| 2022-10-04 | Main token over app tokens; LIFE handles priced by length; "C-Prime" | Year 1; Master |
| 2023-04-01 | Stablecoin Z released in "prime stairsteps"; BTCZPERP | Stablecoin |
| 2023-08-11 | Rule of tokenomics: "stocks aren't priced at 9 zeros" | Sahebs rule of tokenomics |
| 2023-11-10 | Coin Denominated Reality | CDR |
| 2025-10-15 | "XR" smart-glasses note | XR |
| 2026-05 | Note to Dorman: buy MIAX's DCM/DCO, Dorman, Connamara; first listing Q1 2027 | Rei World doc |
| 2026-05-25 | claude.ai chat "PRIME protocol" | Rei — Brief |
| 2026-05-29 | CFTC approves Kalshi's bitcoin perp under 40.3 | Rei × MIAX |
| 2026-06 | Token raise shelved; June secure-chip design | Rei — Brief |
| 2026-06-14 / 06-15 | Chats "Prime token currency", "Private money system" | Rei — Brief |
| 2026-06-18 | CME sues the CFTC over perps | Rei × MIAX |
| 2026-09-15 | CLARITY cloture fails 49–50 | Rei World doc |
| 2026-09-30 | AP's MPPLA v2.8 final: 60% on every perpetual; "Nothing sent" | AP instruments; notes 10 |
| 2026-10-03 | XR Language — Brief | doc |
| 2026-10-04 | XR Suggestion Bar | artifact |
| 2026-10-07 | zkTPU report drops "credit tokens and a central coin" | zkTPU |
| 2026-10-09 | Trader in Time | doc |
| 2026-10-14 | Riemann session (00:35 UTC); "Riemann and primes" chat; Rei — Brief | session; doc |
| 2026-10-15 | "No fee and no burn, no Ethereum…"; Nimbus build begins 21:18 UTC | Prime ticks; session |
| 2026-10-16 | Ticker XR; Prime ticks (v0.6); World doc; Rei × MIAX brief; Cookbook; coin variations; 21:24 Foundation treasury decision | docs |
| 2026-10-17 | Rei — The Deck (07:10 UTC); "Rei, redesigned" | deck; gallery |
| 2026-10-19 | Spaceyard (SPY) | design |
| 2026-10-20 | Comments close on Regulation Crypto Assets | Rei × MIAX |
| 2026-12-31 | LOI for a public home, AMBR or Gemini (proposed) | Rei docs |
| 2027-01-03 | CLARITY dies unless reintroduced | Rei × MIAX |
| 2027-01-18 | Latest date the GENIUS Act takes effect | Rei World doc |
| 2027-03-31 | Bonds priced; testnet, circuit library and cookbook public (proposed) | Rei docs |
| 2027-05-31 | Accounts and KYC tiers in beta on testnet (proposed) | Rei docs |
| 2027-06-30 | Licences held; CFTC clears XR spot (proposed condition) | Rei docs |
| 2027-11-01 | Mainnet and the one sale, 30 days (proposed) | Rei docs |
| After the sale | Market-making desk starts | Rei docs |
| 2028 | Foundation's first treasury sale; Rei Visa; Rei Dollar (proposed) | Rei docs |
| 2028-03-31 | AMBR reverse merger closed (proposed) | Rei docs |
| Launch + 3 years | Upgrade keys pass to the Foundation | Rei docs |

*Sources: as listed in each row; notes 11 and 14*

## Open questions {#rei-open}

1. **Which architecture?** 5G phone hops with no Ethereum (v0.6, benchmarked), or a Nitro rollup on Ethereum (World, MIAX, Cookbook, Deck)? Is the June offline chip design dead?
2. **Prime rata or pro rata?** If R stays: in what unit (Rei, or billionths of XR), at what precision, and per KYC'd holder or per wallet?
3. **Who fires a step?** An AGI-set directive, a hashed pre-launch list, or Foundation proposals voted by holders? Which milestones measure network use rather than company work?
4. **The CLARITY call.** Will holders vote the milestones and the model's governance, so that the Foundation's 50% can count as decentralized? "This is Saheb's call."
5. **The AP carve-out.** Will the MPPLA and the IP Assignment exclude Rei's bitcoin, ether and XR perps (and possibly XR spot) before AP signs and before the 10% sale? What does MIAX ask in return?
6. **The fee split** between MIAX, AP and Rei. Today MIAX "keeps its exchange and clearing fees".
7. **Gemini and AP exclusivity.** Can a Rei-owned Gemini list perps without colliding with AP's US exclusivity?
8. **Counsel.** The sale, custody, money transmission, IB and BD-N, and the uncensored model all wait on counsel. Was the Regulation Crypto Assets comment filed by 20 October 2026?
9. **Snapshot gaming.** An unannounced fire time, or time-weighted shares?
10. **Prime marks.** Retired (Prime ticks) or kept as folds (World, MIAX, Cookbook)?
11. **"Prime stairsteps".** What did the term mean in 2023, and is Rei the same idea?
12. **The model company.** Who owns it, how is it paid, and what are the AI token rate's cost base and review date?
13. **Handle coins.** What do holders get beyond the coin, and do coins need KYC?
14. **SPY and XR.** Is SPY a points layer on XR, a separate token or a placeholder? It shares its ticker with the S&P 500 ETF.
15. **The brief's own loose ends.** "Is the Oct 9 'biggest algo stable' part of Rei?" "In the FX marketplace idea, does Rei sit in the middle of trades or own the FX business's profits?" "Is Rei the coin built into the Cambrian browser?"
16. **Token-first after "no token".** How does Rei square with the zkTPU verdict of 7 October that "token networks earn far less than they emit"?
17. **Unread sources.** The three May–June chats, the Rei data room, the code and the 64-page brief would settle questions 1, 2 and 11.
18. **Device recovery.** Privy's recovery, an iCloud Keychain passkey or a sealed backup?

*Sources: Rei — Brief (2026-10-14); Prime ticks (2026-10-16); Rei — The World a $100 Billion Coin Makes (2026-10-16); Rei × MIAX — The Brief (2026-10-16); Rei — The Cookbook (2026-10-16); Spaceyard (2026-10-19); zkTPU verification report (2026-10-07); notes 11 and 14*

<!-- END CHAPTER -->
