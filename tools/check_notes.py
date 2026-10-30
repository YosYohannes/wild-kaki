"""Checks docs/notes.md against the entries in lib/animals/catalog_data.dart.

Run from anywhere: python3 tools/check_notes.py
"""
import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
CATALOG = ROOT / "lib/animals/catalog_data.dart"
NOTES = ROOT / "docs/notes.md"
MAX_LEN = 80


def catalog_ids():
    text = CATALOG.read_text()
    return re.findall(r"Species\(\s*id:\s*'([^']+)'", text) + re.findall(r"\bLegend\(\s*id:\s*'([^']+)'", text)


def note_rows():
    rows = []
    for line in NOTES.read_text().splitlines():
        if not line.startswith("|"):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) != 3 or cells[0] in ("Id", "") or set(cells[0]) <= {"-", ":"}:
            continue
        rows.append(cells)
    return rows


def main():
    errors = []
    expected = catalog_ids()
    rows = note_rows()
    seen = {}
    for id_, _name, note in rows:
        seen[id_] = seen.get(id_, 0) + 1
        if not note:
            errors.append(f"empty note: {id_}")
        elif len(note) > MAX_LEN:
            errors.append(f"note too long ({len(note)} > {MAX_LEN}): {id_}: {note}")
        if re.search(r"[^\x20-\x7e]|[\"\\$`]", note):
            errors.append(f"note has a character that is not plain text: {id_}")
    for id_ in expected:
        if id_ not in seen:
            errors.append(f"missing entry: {id_}")
    for id_, count in seen.items():
        if count > 1:
            errors.append(f"duplicated entry ({count}x): {id_}")
        if id_ not in expected:
            errors.append(f"unknown entry: {id_}")
    if not errors and [r[0] for r in rows] != expected:
        errors.append("entries are not in catalog order")
    if errors:
        print("docs/notes.md has problems:")
        for e in errors:
            print(f"  - {e}")
        return 1
    print(f"ok: {len(rows)} notes, all within {MAX_LEN} characters")
    return 0


if __name__ == "__main__":
    sys.exit(main())
