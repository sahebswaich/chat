# Treatise sources

One chapter per file, `ch<NN>_<key>.md`, rendered in filename order by
`scripts/build_treatise.py`. Appendices (`ch90`+) are generated from the research notes by
`scripts/extract_appendices.py`.

Dialect:
- `# IV. Title` — one per file; the roman numeral becomes "Chapter IV" (`# Appendix A. Title` → "Appendix A").
- `## Section {#unique-id}` — sections; ids are the discussion anchors and link targets.
- GitHub tables; `**bold**`, `*italic*`, lists, links.
- Callouts are blockquotes:
  - `> [!number] $40M — signing payment` (optional second line of context)
  - `> [!quote] "verbatim words" — source, date`
  - `> [!tension] one-line contradiction or open question`
- `*Sources: …*` as the last paragraph of a section renders as a source line.

`pods/*.json` feed the home page's orbit and pod drawer (`_order.json` sets the order);
`vision.json` holds the hero thesis, stats and eras.
