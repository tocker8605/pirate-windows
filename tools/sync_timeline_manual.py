"""Regenerate offline manual snapshots from project JSON (Python standard library only).
Run: python tools/sync_timeline_manual.py [--check]
The HTML remains standalone and requires no local HTTP server.
"""
from pathlib import Path
import argparse
import html
import json
import re

ROOT = Path(__file__).resolve().parents[1]
MANUAL = ROOT / "docs/stage-timeline-manual.html"

def sources(root=ROOT):
    catalog = json.loads((root / "data/enemies.json").read_text(encoding="utf-8"))["entities"]
    stages = {}
    for path in sorted((root / "data").glob("stage*.json")):
        match = re.fullmatch(r"stage(\d{2})\.json", path.name)
        if match:
            stages[str(int(match[1]))] = json.loads(path.read_text(encoding="utf-8"))
    return catalog, stages

def replace_block(text, pattern, body):
    result, count = re.subn(pattern, lambda m: m[1] + body + m[3], text, count=1, flags=re.S)
    if count != 1:
        raise ValueError("Missing generated manual block: " + pattern)
    return result

def render(text, catalog, stages):
    # Escaping keeps arbitrary names/comments from closing a script element.
    payload = json.dumps({"catalog": catalog, "stages": stages}, ensure_ascii=False).replace("<", r"\u003c")
    text = replace_block(text, r'(<script id="manual-data" type="application/json">)(.*?)(</script>)', payload)
    roles = {"enemy": "일반 적", "part": "보스 파츠", "boss": "보스 본체", "supply": "보급기"}
    rows = []
    for key, d in sorted(catalog.items(), key=lambda pair: int(pair[0])):
        role = roles[d["role"]]
        name = html.escape(d["name"])
        note = d.get("display_name", "")
        if d["role"] == "supply": note = "자동 보급 · timeline 배치 불가"
        search = html.escape(f'{key} {d["name"]} {role} {note}', quote=True)
        rows.append(f'<tr data-search="{search}"><td>{key}</td><td><code>{name}</code></td><td>{role}</td><td>{d["hp"]:g}</td><td>{html.escape(note)}</td></tr>')
    text = replace_block(text, r'(<table id="catalog-table">.*?<tbody>)(.*?)(</tbody>)', "".join(rows))
    rows, options = [], []
    boss_ids = {int(key) for key, d in catalog.items() if d["role"] == "boss"}
    for key, doc in sorted(stages.items(), key=lambda pair: int(pair[0])):
        number = int(key)
        label = f'보스러시 {number-10}면' if number > 10 else f'일반 {number}면'
        events = [e for e in doc["events"] if "at" in e]
        times = [e["at"] for e in events if e.get("action") == "spawn" and e.get("definition_id") in boss_ids]
        first = f'{min(times):g}초' if times else "—"
        filename = f'stage{number:02d}.json'
        rows.append(f'<tr><td>{label}</td><td><a href="../data/{filename}">data/{filename}</a></td><td>{len(events)}</td><td>{first}</td></tr>')
        options.append(f'<option value="{key}">{label}</option>')
    text = replace_block(text, r'(<section id="files">.*?<tbody>)(.*?)(</tbody>)', "".join(rows))
    text = replace_block(text, r'(<select id="sample"[^>]*>)(.*?)(</select>)', "".join(options))
    return text

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--check", action="store_true", help="Fail without writing if the manual is stale")
    args = parser.parse_args()
    old = MANUAL.read_text(encoding="utf-8")
    new = render(old, *sources())
    if args.check:
        if old != new:
            parser.exit(1, "Manual snapshot is stale. Run: python tools/sync_timeline_manual.py\n")
        print("Manual snapshots match the source JSON.")
    elif new != old:
        MANUAL.write_text(new, encoding="utf-8")
        print("Updated manual catalog, timeline samples, file table and sample selector.")
    else:
        print("Manual is already current.")

if __name__ == "__main__":
    main()
