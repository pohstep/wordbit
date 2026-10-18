#!/usr/bin/env python3
"""Build Resources/words.json and Resources/pictures.json.

words.json is the v1 list (data/words-v1.json) unchanged, plus a short Chinese
gloss from ECDICT (MIT). pictures.json is a separate set of about 150 concrete
words for the picture game. Glyphs are Apple Color Emoji code points, not
image files. An SF Symbol name is stored for fallback and is only drawn if the
emoji glyph is empty.

Usage:
  python3 scripts/build_resources.py /path/to/ecdict.csv

ECDICT: https://github.com/skywind3000/ECDICT  (MIT, Copyright (c) 2025 Linwei)
The csv is not committed. Download ecdict.csv from that repository.
"""

import csv
import json
import os
import sys
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
V1 = os.path.join(ROOT, "data", "words-v1.json")
WORDS_OUT = os.path.join(ROOT, "Resources", "words.json")
PICTURES_OUT = os.path.join(ROOT, "Resources", "pictures.json")

# word, emoji, group, level, sfsymbol, pos (n or v)
# Emoji are Unicode 13 / Emoji 13.1 or older, so they exist on macOS 13.
PICTURES = [
    ("apple", "🍎", "fruit", 1, "", "n"),
    ("banana", "🍌", "fruit", 1, "", "n"),
    ("orange", "🍊", "fruit", 1, "", "n"),
    ("grape", "🍇", "fruit", 1, "", "n"),
    ("strawberry", "🍓", "fruit", 1, "", "n"),
    ("watermelon", "🍉", "fruit", 1, "", "n"),
    ("lemon", "🍋", "fruit", 1, "", "n"),
    ("peach", "🍑", "fruit", 1, "", "n"),
    ("cherry", "🍒", "fruit", 1, "", "n"),
    ("pear", "🍐", "fruit", 1, "", "n"),
    ("pineapple", "🍍", "fruit", 2, "", "n"),
    ("mango", "🥭", "fruit", 2, "", "n"),
    ("cat", "🐱", "animal", 1, "", "n"),
    ("dog", "🐶", "animal", 1, "", "n"),
    ("bird", "🐦", "animal", 1, "", "n"),
    ("fish", "🐟", "animal", 1, "", "n"),
    ("horse", "🐴", "animal", 1, "", "n"),
    ("cow", "🐮", "animal", 1, "", "n"),
    ("pig", "🐷", "animal", 1, "", "n"),
    ("sheep", "🐑", "animal", 1, "", "n"),
    ("rabbit", "🐰", "animal", 1, "", "n"),
    ("mouse", "🐭", "animal", 1, "", "n"),
    ("lion", "🦁", "animal", 1, "", "n"),
    ("tiger", "🐯", "animal", 1, "", "n"),
    ("bear", "🐻", "animal", 1, "", "n"),
    ("monkey", "🐵", "animal", 1, "", "n"),
    ("elephant", "🐘", "animal", 2, "", "n"),
    ("frog", "🐸", "animal", 1, "", "n"),
    ("duck", "🦆", "animal", 1, "", "n"),
    ("bee", "🐝", "animal", 1, "", "n"),
    ("butterfly", "🦋", "animal", 2, "", "n"),
    ("snake", "🐍", "animal", 1, "", "n"),
    ("penguin", "🐧", "animal", 2, "", "n"),
    ("turtle", "🐢", "animal", 2, "", "n"),
    ("whale", "🐳", "animal", 2, "", "n"),
    ("chicken", "🐔", "animal", 1, "", "n"),
    ("bread", "🍞", "food", 1, "", "n"),
    ("egg", "🥚", "food", 1, "", "n"),
    ("cheese", "🧀", "food", 1, "", "n"),
    ("rice", "🍚", "food", 1, "", "n"),
    ("milk", "🥛", "food", 1, "", "n"),
    ("cake", "🎂", "food", 1, "", "n"),
    ("pizza", "🍕", "food", 1, "", "n"),
    ("cookie", "🍪", "food", 1, "", "n"),
    ("burger", "🍔", "food", 1, "", "n"),
    ("popcorn", "🍿", "food", 2, "", "n"),
    ("doughnut", "🍩", "food", 2, "", "n"),
    ("chocolate", "🍫", "food", 1, "", "n"),
    ("candy", "🍬", "food", 1, "", "n"),
    ("honey", "🍯", "food", 2, "", "n"),
    ("noodle", "🍜", "food", 1, "", "n"),
    ("salad", "🥗", "food", 2, "", "n"),
    ("steak", "🥩", "food", 2, "", "n"),
    ("coffee", "☕", "drink", 1, "cup.and.saucer.fill", "n"),
    ("tea", "🍵", "drink", 1, "", "n"),
    ("juice", "🧃", "drink", 2, "", "n"),
    ("wine", "🍷", "drink", 2, "", "n"),
    ("sun", "☀️", "weather", 1, "sun.max.fill", "n"),
    ("rain", "🌧️", "weather", 1, "cloud.rain.fill", "n"),
    ("cloud", "☁️", "weather", 1, "cloud.fill", "n"),
    ("snow", "❄️", "weather", 1, "snowflake", "n"),
    ("rainbow", "🌈", "weather", 1, "", "n"),
    ("lightning", "⚡", "weather", 1, "bolt.fill", "n"),
    ("wind", "💨", "weather", 2, "wind", "n"),
    ("moon", "🌙", "weather", 1, "moon.fill", "n"),
    ("eye", "👁️", "body", 1, "eye.fill", "n"),
    ("ear", "👂", "body", 1, "", "n"),
    ("hand", "✋", "body", 1, "hand.raised.fill", "n"),
    ("foot", "🦶", "body", 1, "", "n"),
    ("heart", "❤️", "body", 1, "heart.fill", "n"),
    ("nose", "👃", "body", 1, "", "n"),
    ("mouth", "👄", "body", 1, "", "n"),
    ("tooth", "🦷", "body", 2, "", "n"),
    ("car", "🚗", "travel", 1, "car.fill", "n"),
    ("bus", "🚌", "travel", 1, "bus.fill", "n"),
    ("bicycle", "🚲", "travel", 1, "bicycle", "n"),
    ("airplane", "✈️", "travel", 1, "airplane", "n"),
    ("boat", "⛵", "travel", 1, "sailboat.fill", "n"),
    ("train", "🚆", "travel", 1, "tram.fill", "n"),
    ("rocket", "🚀", "travel", 2, "", "n"),
    ("truck", "🚚", "travel", 2, "", "n"),
    ("house", "🏠", "home", 1, "house.fill", "n"),
    ("door", "🚪", "home", 1, "", "n"),
    ("bed", "🛏️", "home", 1, "bed.double.fill", "n"),
    ("chair", "🪑", "home", 1, "", "n"),
    ("clock", "⏰", "home", 1, "clock.fill", "n"),
    ("key", "🔑", "home", 1, "key.fill", "n"),
    ("lamp", "💡", "home", 1, "lightbulb.fill", "n"),
    ("phone", "📱", "home", 1, "iphone", "n"),
    ("camera", "📷", "home", 1, "camera.fill", "n"),
    ("computer", "💻", "home", 1, "desktopcomputer", "n"),
    ("book", "📖", "home", 1, "book.fill", "n"),
    ("gift", "🎁", "home", 1, "gift.fill", "n"),
    ("tree", "🌳", "nature", 1, "", "n"),
    ("flower", "🌸", "nature", 1, "", "n"),
    ("leaf", "🍃", "nature", 1, "leaf.fill", "n"),
    ("mountain", "⛰️", "nature", 1, "", "n"),
    ("fire", "🔥", "nature", 1, "flame.fill", "n"),
    ("wave", "🌊", "nature", 1, "", "n"),
    ("cactus", "🌵", "nature", 2, "", "n"),
    ("mushroom", "🍄", "nature", 2, "", "n"),
    ("shell", "🐚", "nature", 2, "", "n"),
    ("earth", "🌍", "nature", 2, "globe", "n"),
    ("seedling", "🌱", "nature", 2, "", "n"),
    ("maple", "🍁", "nature", 2, "", "n"),
    ("rose", "🌹", "nature", 1, "", "n"),
    ("shirt", "👕", "clothes", 1, "tshirt.fill", "n"),
    ("shoe", "👟", "clothes", 1, "", "n"),
    ("hat", "🎩", "clothes", 1, "", "n"),
    ("dress", "👗", "clothes", 1, "", "n"),
    ("pants", "👖", "clothes", 1, "", "n"),
    ("sock", "🧦", "clothes", 2, "", "n"),
    ("glove", "🧤", "clothes", 2, "", "n"),
    ("crown", "👑", "clothes", 2, "", "n"),
    ("spoon", "🥄", "kitchen", 1, "", "n"),
    ("fork", "🍴", "kitchen", 1, "fork.knife", "n"),
    ("knife", "🔪", "kitchen", 1, "", "n"),
    ("cup", "🥤", "kitchen", 1, "", "n"),
    ("plate", "🍽️", "kitchen", 1, "", "n"),
    ("soup", "🍲", "kitchen", 1, "", "n"),
    ("bowl", "🥣", "kitchen", 1, "", "n"),
    ("salt", "🧂", "kitchen", 2, "", "n"),
    ("run", "🏃", "action", 1, "figure.run", "v"),
    ("swim", "🏊", "action", 1, "figure.pool.swim", "v"),
    ("sleep", "😴", "action", 1, "", "v"),
    ("sing", "🎤", "action", 1, "music.mic", "v"),
    ("dance", "💃", "action", 1, "figure.dance", "v"),
    ("walk", "🚶", "action", 1, "figure.walk", "v"),
    ("climb", "🧗", "action", 2, "", "v"),
    ("ski", "🎿", "action", 2, "", "v"),
    ("school", "🏫", "place", 1, "", "n"),
    ("hospital", "🏥", "place", 1, "", "n"),
    ("castle", "🏰", "place", 2, "", "n"),
    ("church", "⛪", "place", 1, "", "n"),
    ("tent", "⛺", "place", 2, "", "n"),
    ("fountain", "⛲", "place", 2, "", "n"),
    ("bridge", "🌉", "place", 2, "", "n"),
    ("factory", "🏭", "place", 2, "", "n"),
    ("soccer", "⚽", "sport", 1, "", "n"),
    ("basketball", "🏀", "sport", 1, "", "n"),
    ("baseball", "⚾", "sport", 1, "", "n"),
    ("tennis", "🎾", "sport", 1, "", "n"),
    ("football", "🏈", "sport", 2, "", "n"),
    ("golf", "⛳", "sport", 2, "", "n"),
    ("volleyball", "🏐", "sport", 2, "", "n"),
    ("bowling", "🎳", "sport", 2, "", "n"),
    ("guitar", "🎸", "music", 1, "", "n"),
    ("piano", "🎹", "music", 1, "", "n"),
    ("drum", "🥁", "music", 1, "", "n"),
    ("violin", "🎻", "music", 2, "", "n"),
]

ALIASES = {
    "burger": ["hamburger", "burger"],
    "doughnut": ["doughnut", "donut"],
    "airplane": ["airplane", "aeroplane", "plane"],
    "soccer": ["soccer"],
    "candy": ["candy", "sweet"],
    "pants": ["pants", "trousers"],
    "cookie": ["cookie", "biscuit"],
    "phone": ["phone", "telephone", "mobile"],
    "bicycle": ["bicycle", "bike"],
    "noodle": ["noodle", "noodles"],
    "juice": ["juice"],
    "wave": ["wave"],
    "soup": ["soup"],
    "cup": ["cup"],
    "plate": ["plate", "dish"],
    "football": ["football"],
    "maple": ["maple"],
    "seedling": ["seedling"],
    "earth": ["earth"],
    "glove": ["glove"],
    "sock": ["sock"],
    "crown": ["crown"],
    "fountain": ["fountain"],
    "bowling": ["bowling"],
    "volleyball": ["volleyball"],
    "popcorn": ["popcorn"],
    "steak": ["steak"],
    "salad": ["salad"],
    "pineapple": ["pineapple"],
    "watermelon": ["watermelon"],
    "strawberry": ["strawberry"],
    "butterfly": ["butterfly"],
    "penguin": ["penguin"],
}

POS_TAGS = {
    "adjective": ("a.", "adj."),
    "verb": ("vi.", "vt.", "v."),
    "noun": ("n.",),
    "v": ("vi.", "vt.", "v."),
    "n": ("n.",),
}


def has_cjk(text):
    return any("\u4e00" <= ch <= "\u9fff" for ch in text)


def split_lines(text):
    text = (text or "").replace("\\n", "\n")
    return [ln.strip() for ln in text.splitlines() if ln.strip()]


def pick_line(text, pos):
    lines = split_lines(text)
    if not lines:
        return ""
    tags = POS_TAGS.get(pos, ())
    for tag in tags:
        for ln in lines:
            if ln.startswith(tag):
                return ln
    for ln in lines:
        if not ln.startswith("[") and not ln.startswith("【"):
            return ln
    return lines[0]


# Picture cards use one concrete sense. A few headwords are listed in ECDICT
# with a looser first sense; the string here is taken from that same entry
# and the script rejects it if it is not actually one of the senses.
PICTURE_SENSE = {
    "fountain": "喷泉",
    "football": "橄榄球",
}


def senses_of(line):
    import re
    s = line.strip()
    s = re_sub_pos(s)
    while True:
        if s.startswith("[") and "]" in s[:16]:
            s = s.split("]", 1)[1].strip()
            continue
        if s.startswith("【") and "】" in s[:16]:
            s = s.split("】", 1)[1].strip()
            continue
        break
    s = re_sub_pos(s)
    s = re.sub(r"（[^）]*）", "", s)
    s = re.sub(r"\([^)]*\)", "", s)
    parts = []
    for chunk in split_senses(s):
        chunk = chunk.strip(" ，,;；、 ")
        if not chunk or not has_cjk(chunk):
            continue
        if "人名" in chunk or "姓氏" in chunk or "形物" in chunk:
            continue
        parts.append(chunk)
    return parts


def clean_cn(line, limit=2):
    parts = senses_of(line)[:limit]
    if not parts:
        return ""
    if len(parts[0]) > 18:
        return parts[0][:18].rstrip("，,；、 ")
    out = "；".join(parts)
    if len(out) > 28:
        return parts[0]
    return out


def picture_cn(line, word):
    parts = senses_of(line)
    if word in PICTURE_SENSE:
        want = PICTURE_SENSE[word]
        if want not in parts:
            raise SystemExit("picture sense %s not in ECDICT entry for %s: %s" % (want, word, parts))
        return want
    return parts[0] if parts else ""


def re_sub_pos(s):
    import re
    return re.sub(r"^(n|v|vt|vi|a|adj|adv|prep|conj|pron|art|num|int|aux|abbr)\.\s*", "", s)


def split_senses(s):
    import re
    return re.split(r"[；;，,、/]", s)


def load_ecdict(path):
    index = {}
    with open(path, newline="", encoding="utf-8") as handle:
        for row in csv.DictReader(handle):
            key = row["word"].strip().lower()
            if not key:
                continue
            prev = index.get(key)
            # Prefer an exact lowercase lemma over "Apple" / "RUN".
            if prev is None or (row["word"] == key and prev["word"] != key):
                index[key] = row
    return index


def lookup(index, word, pos, limit=2, picture=False):
    keys = [word.lower()] + [a.lower() for a in ALIASES.get(word, []) if a.lower() != word.lower()]
    for key in keys:
        row = index.get(key)
        if not row:
            continue
        line = pick_line(row.get("translation", ""), pos)
        gloss = picture_cn(line, word) if picture else clean_cn(line, limit=limit)
        if gloss:
            return gloss
    return ""


def main():
    if len(sys.argv) != 2:
        print("usage: build_resources.py /path/to/ecdict.csv", file=sys.stderr)
        return 2
    index = load_ecdict(sys.argv[1])
    v1 = json.load(open(V1, encoding="utf-8"))
    assert len(v1) == 400
    words = []
    missing = []
    for entry in v1:
        gloss = lookup(index, entry["word"], entry["pos"], limit=2)
        if not gloss:
            missing.append(entry["word"])
        out = {
            "word": entry["word"],
            "ipa": entry["ipa"],
            "pos": entry["pos"],
            "definition": entry["definition"],
            "example": entry["example"],
            "origin": entry["origin"],
            "cn": gloss,
            "source": entry["source"],
        }
        for key in ("word", "ipa", "pos", "definition", "example", "origin", "source"):
            if out[key] != entry[key]:
                raise SystemExit("field changed: " + entry["word"] + " " + key)
        words.append(out)

    pics = []
    seen_words = set()
    seen_glyphs = set()
    groups = {}
    pic_missing = []
    for word, glyph, group, level, symbol, pos in PICTURES:
        if word in seen_words:
            raise SystemExit("duplicate picture word " + word)
        norm = unicodedata.normalize("NFC", glyph)
        if norm in seen_glyphs:
            raise SystemExit("duplicate glyph " + word + " " + glyph)
        seen_words.add(word)
        seen_glyphs.add(norm)
        groups.setdefault(group, 0)
        groups[group] += 1
        gloss = lookup(index, word, "verb" if pos == "v" else "noun", picture=True)
        if not gloss:
            pic_missing.append(word)
        # Highest scalar, so a too-new emoji fails the Mac 13 check below.
        top = max(ord(ch) for ch in glyph)
        pics.append({
            "word": word,
            "glyph": glyph,
            "cn": gloss,
            "distractorGroup": group,
            "level": level,
            "symbol": symbol,
        })
        if top > 0x1FAFF:
            print("warn high codepoint", word, hex(top))

    small = [g for g, n in groups.items() if n < 4]
    if small:
        raise SystemExit("groups under 4: " + ", ".join(small))
    if not 140 <= len(pics) <= 160:
        raise SystemExit("picture count %d" % len(pics))

    os.makedirs(os.path.dirname(WORDS_OUT), exist_ok=True)
    with open(WORDS_OUT, "w", encoding="utf-8") as handle:
        json.dump(words, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    # pictures.json is now written by scripts/build_pictures.py (v2 harder set).

    print("words", len(words), "with cn", sum(1 for w in words if w["cn"]), "missing", len(missing))
    if missing:
        print("missing words:", ", ".join(missing))
    print("pictures", len(pics), "missing cn", len(pic_missing))
    if pic_missing:
        print("missing pictures:", ", ".join(pic_missing))
    print("--- picture glosses ---")
    for p in pics:
        print("%s [%s/%s] %s  %s" % (p["glyph"], p["distractorGroup"], p["level"], p["word"], p["cn"]))
    fixed = apply_checked_glosses()
    return 0 if not pic_missing and fixed == 0 else 1


def apply_checked_glosses():
    """Re-apply the checked Chinese glosses so a rebuild never undoes them."""
    import apply_cn_fixes
    return apply_cn_fixes.main()


if __name__ == "__main__":
    sys.exit(main())
