#!/usr/bin/env python3
"""Apply the checked Chinese glosses in scripts/cn_fixes.json.

Run after build_resources.py or build_pictures.py (both call this at the end),
so a rebuild never brings back the old dictionary glosses. A fix is applied
only when the current gloss matches its "from" value (or already equals "to").
Anything else is reported and left alone. All picture glosses are then marked
"checked".
"""
import json
import os
import sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
FIXES = os.path.join(ROOT, "scripts", "cn_fixes.json")
FILES = {
    "words": os.path.join(ROOT, "Resources", "words.json"),
    "pictures": os.path.join(ROOT, "Resources", "pictures.json"),
}


def main():
    fixes = json.load(open(FIXES, encoding="utf-8"))
    applied, already, skipped = 0, 0, []
    for kind, path in FILES.items():
        if not os.path.exists(path):
            continue
        rows = json.load(open(path, encoding="utf-8"))
        by_word = {row["word"]: row for row in rows}
        for word, fix in fixes.get(kind, {}).items():
            row = by_word.get(word)
            if row is None:
                skipped.append("%s %s: not found" % (kind, word))
            elif row["cn"] == fix["to"]:
                already += 1
            elif row["cn"] == fix["from"]:
                row["cn"] = fix["to"]
                applied += 1
            else:
                skipped.append("%s %s: current %r is not %r" % (kind, word, row["cn"], fix["from"]))
        if kind == "pictures":
            for row in rows:
                row["cnStatus"] = "checked"
        with open(path, "w", encoding="utf-8") as handle:
            json.dump(rows, handle, ensure_ascii=False, indent=2)
            handle.write("\n")
    print("cn fixes applied %d, already %d, skipped %d" % (applied, already, len(skipped)))
    for line in skipped:
        print("  skipped " + line)
    return 0 if not skipped else 1


if __name__ == "__main__":
    sys.exit(main())
