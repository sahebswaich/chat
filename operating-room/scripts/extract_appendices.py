#!/usr/bin/env python3
"""Merge the research notes' Timeline, People and Coverage tables into appendix chapters.

    python3 scripts/extract_appendices.py <notes-dir> <out-dir>

Writes <out-dir>/ch90_timeline.md, ch91_people.md and ch92_sources.md in the treatise's
markdown dialect. Rows are taken verbatim from the notes (one row per source mention), sorted
and lightly de-duplicated, so the appendices are the complete record behind the chapters.
"""

from __future__ import annotations

import re
import sys
from pathlib import Path

THREAD = {
    "01_AP_core": "AP", "02_AP_memos": "AP", "03_AP_regulatory": "AP", "04_AP_clearing": "AP",
    "05_AP_build": "AP", "06_AP_street": "AP", "10_AP_corporate": "AP", "07_GLX_A": "GLX",
    "08_GLX_B": "GLX", "09_Greyline": "Greyline", "11_early_ideas_A": "Origins",
    "12_early_ideas_B": "Origins", "13_gap_sweep": "Drive", "14_claude_sessions": "Claude",
    "15_artifacts_rest": "Claude", "16_gap_followup": "Drive",
}


def section(text: str, heading: str) -> str:
    m = re.search(rf"^## {re.escape(heading)}[^\n]*\n(.*?)(?=^## |\Z)", text, flags=re.M | re.S)
    return m.group(1) if m else ""


def table_rows(block: str) -> list[list[str]]:
    rows = []
    for line in block.splitlines():
        line = line.strip()
        if not line.startswith("|") or re.match(r"^\|[\s:|-]+\|$", line):
            continue
        cells = [c.strip() for c in line.strip("|").split("|")]
        rows.append(cells)
    if rows and any(h.lower() in ("date", "name", "source (title)", "source", "metric") for h in rows[0]):
        rows = rows[1:]
    return rows


MONTHS = {m: i for i, m in enumerate(["jan", "feb", "mar", "apr", "may", "jun", "jul", "aug", "sep", "oct", "nov", "dec"], 1)}


def sort_key(date: str) -> str:
    d = date.strip().strip("*~≈ ")
    m = re.match(r"(\d{4})(?:-(\d{1,2}))?(?:-(\d{1,2}))?", d)
    if m:
        return f"{m.group(1)}-{int(m.group(2) or 0):02d}-{int(m.group(3) or 0):02d}"
    m = re.search(r"(\d{1,2})?\s*([A-Za-z]{3})[a-z]*\.?\s*(\d{1,2})?,?\s*(\d{4})", d)
    if m:
        day = m.group(1) or m.group(3) or "0"
        return f"{m.group(4)}-{MONTHS.get(m.group(2).lower(), 0):02d}-{int(day):02d}"
    m = re.search(r"(\d{4})", d)
    return f"{m.group(1)}-00-00" if m else "9999"


NOISE = ("not found", "no mention", "not present", "not mentioned", "no individual", "none named", "(none", "n/a")


def is_noise(*cells: str) -> bool:
    head = " ".join(cells[:2]).lower()
    return any(n in head for n in NOISE) or cells[0].startswith("(")


def esc_cell(text: str) -> str:
    return text.replace("|", "/").strip()


def main() -> None:
    notes_dir, out_dir = Path(sys.argv[1]), Path(sys.argv[2])
    out_dir.mkdir(parents=True, exist_ok=True)
    timeline, people, sources = [], {}, []
    for f in sorted(notes_dir.glob("[0-9][0-9]_*.md")):
        thread = THREAD.get(f.stem, f.stem)
        text = f.read_text(encoding="utf-8", errors="replace")
        for cells in table_rows(section(text, "Timeline")):
            if len(cells) >= 2 and cells[0] and cells[1] and not is_noise(*cells):
                timeline.append((sort_key(cells[0]), cells[0], cells[1], cells[2] if len(cells) > 2 else "", thread))
        for cells in table_rows(section(text, "People & organizations")):
            if len(cells) >= 2 and cells[0] and not is_noise(*cells):
                key = re.sub(r"[*_`]", "", cells[0]).strip().lower()
                entry = people.setdefault(key, {"name": re.sub(r"[*_`]", "", cells[0]).strip(), "roles": [], "threads": set()})
                role = cells[1]
                if role and role not in entry["roles"]:
                    entry["roles"].append(role)
                entry["threads"].add(thread)
        for cells in table_rows(section(text, "Coverage")):
            if len(cells) >= 3 and cells[0]:
                sources.append((thread, cells[0], cells[2] if len(cells) > 2 else "", cells[-1] if len(cells) > 4 else ""))

    # Timeline: sorted; identical (date, event) pairs collapse.
    seen = set()
    lines = [
        "# Appendix A. The complete timeline {#timeline}",
        "",
        "Every dated event the research found, oldest first, exactly as each source recorded it. "
        "Where two documents date the same event differently, both rows stay.",
        "",
    ]
    current_year = None
    for key, date, event, source, thread in sorted(timeline, key=lambda r: (r[0], r[4])):
        sig = (date.lower(), event.lower()[:80])
        if sig in seen:
            continue
        seen.add(sig)
        year = key[:4] if key[:4].isdigit() else "Undated"
        if year != current_year:
            current_year = year
            lines += ["", f"## {year} {{#timeline-{year.lower()}}}", "", "| Date | Event | Thread | Source |", "|---|---|---|---|"]
        lines.append(f"| {esc_cell(date)} | {esc_cell(event)} | {thread} | {esc_cell(source)} |")
    lines += ["", "<!-- END CHAPTER -->", ""]
    (out_dir / "ch90_timeline.md").write_text("\n".join(lines), encoding="utf-8")

    lines = [
        "# Appendix B. People and organizations {#people}",
        "",
        "Everyone the documents name, with every role they were given and the threads they appear in.",
        "",
        "## Directory {#people-directory}",
        "",
        "| Name | Roles (as described) | Threads |",
        "|---|---|---|",
    ]
    for entry in sorted(people.values(), key=lambda e: e["name"].lower()):
        roles = "; ".join(esc_cell(r) for r in entry["roles"][:4])
        lines.append(f"| {esc_cell(entry['name'])} | {roles} | {', '.join(sorted(entry['threads']))} |")
    lines += ["", "<!-- END CHAPTER -->", ""]
    (out_dir / "ch91_people.md").write_text("\n".join(lines), encoding="utf-8")

    lines = [
        "# Appendix C. Sources read {#sources}",
        "",
        "Every document the research read, by thread. Drive files keep their titles; the American "
        "Perpetual data room is cited by document and line range of its compiled edition.",
        "",
    ]
    for thread in ["Origins", "Greyline", "GLX", "AP", "Drive", "Claude"]:
        rows = [s for s in sources if s[0] == thread]
        if not rows:
            continue
        lines += [f"## {thread} {{#sources-{thread.lower()}}}", "", "| Source | Date | Gist |", "|---|---|---|"]
        for _, title, date, gist in rows:
            lines.append(f"| {esc_cell(title)} | {esc_cell(date)} | {esc_cell(gist)} |")
        lines.append("")
    lines += ["<!-- END CHAPTER -->", ""]
    (out_dir / "ch92_sources.md").write_text("\n".join(lines), encoding="utf-8")
    print(f"timeline rows: {len(seen)}; people: {len(people)}; sources: {len(sources)}")


if __name__ == "__main__":
    main()
