#!/usr/bin/env python3
"""Build Resources/pictures.json for the Pictures game (v2, harder words).

Each entry: word, emoji (Emoji 13.0 or older, so it draws on macOS 13),
category, level, Chinese gloss (pending a native check), and four or more
hand-picked look-alike or same-category distractors. Distractors are plain
words and do not need an emoji of their own.
"""
import json
import os
import unicodedata

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
OUT = os.path.join(ROOT, "Resources", "pictures.json")

# word, emoji, group, level, cn, distractors
P = [
    # science and instruments
    ("telescope", "🔭", "science", 2, "望远镜", ["microscope", "periscope", "binoculars", "kaleidoscope"]),
    ("microscope", "🔬", "science", 2, "显微镜", ["telescope", "periscope", "stethoscope", "projector"]),
    ("magnifying glass", "🔍", "science", 2, "放大镜", ["monocle", "spyglass", "lorgnette", "hand mirror"]),
    ("test tube", "🧪", "science", 2, "试管", ["beaker", "flask", "pipette", "vial"]),
    ("petri dish", "🧫", "science", 3, "培养皿", ["crucible", "saucer", "watch glass", "beaker"]),
    ("double helix", "🧬", "science", 3, "双螺旋", ["corkscrew", "chromosome", "spiral staircase", "coil"]),
    ("alembic", "⚗️", "science", 3, "蒸馏器", ["beaker", "decanter", "crucible", "carafe"]),
    ("atom", "⚛️", "science", 2, "原子", ["molecule", "orbit", "nucleus", "gyroscope"]),
    ("abacus", "🧮", "science", 2, "算盘", ["slide rule", "calculator", "ledger", "loom"]),
    ("microbe", "🦠", "science", 3, "微生物", ["molecule", "spore", "amoeba", "pollen grain"]),
    ("balance scale", "⚖️", "science", 3, "天平", ["seesaw", "pendulum", "steelyard", "weathervane"]),
    ("compass", "🧭", "science", 2, "指南针", ["sundial", "barometer", "astrolabe", "gyroscope"]),
    ("set square", "📐", "science", 3, "三角尺", ["protractor", "T-square", "ruler", "drafting compass"]),
    # medical
    ("stethoscope", "🩺", "science", 2, "听诊器", ["periscope", "headphones", "otoscope", "catheter"]),
    ("lungs", "🫁", "science", 3, "肺", ["kidneys", "liver", "bronchi", "spleen"]),
    # time
    ("hourglass", "⌛", "time", 2, "沙漏", ["stopwatch", "sundial", "metronome", "egg timer"]),
    ("stopwatch", "⏱️", "time", 2, "秒表", ["pocket watch", "metronome", "compass", "pressure gauge"]),
    ("alarm clock", "⏰", "time", 2, "闹钟", ["mantel clock", "kitchen timer", "cuckoo clock", "doorbell"]),
    ("mantel clock", "🕰️", "time", 3, "座钟", ["grandfather clock", "cuckoo clock", "metronome", "barometer"]),
    # tools and hardware
    ("anchor", "⚓", "tools", 2, "锚", ["grappling hook", "harpoon", "pickaxe", "buoy"]),
    ("trident", "🔱", "tools", 2, "三叉戟", ["pitchfork", "harpoon", "spear", "scepter"]),
    ("pickaxe", "⛏️", "tools", 2, "鹤嘴锄", ["hoe", "crowbar", "mattock", "sickle"]),
    ("plunger", "🪠", "tools", 3, "搋子", ["funnel", "suction cup", "ladle", "mallet"]),
    ("mousetrap", "🪤", "tools", 3, "捕鼠器", ["snare", "cage", "clipboard", "stapler"]),
    ("fire extinguisher", "🧯", "tools", 2, "灭火器", ["oxygen tank", "hydrant", "scuba tank", "canister"]),
    # weapons and armour
    ("bow and arrow", "🏹", "tools", 2, "弓箭", ["crossbow", "slingshot", "javelin", "harpoon"]),
    ("shield", "🛡️", "tools", 2, "盾牌", ["breastplate", "crest", "helmet", "buckler"]),
    ("boomerang", "🪃", "tools", 2, "回旋镖", ["frisbee", "slingshot", "javelin", "crossbow"]),
    ("military helmet", "🪖", "tools", 3, "钢盔", ["hard hat", "crash helmet", "pith helmet", "beret"]),
    # light and household
    ("oil lamp", "🪔", "home", 3, "油灯", ["candle", "censer", "lantern", "teacup"]),
    ("paper lantern", "🏮", "home", 2, "灯笼", ["lampshade", "chandelier", "wind chime", "parasol"]),
    ("spool of thread", "🧵", "home", 3, "线轴", ["skein of yarn", "ribbon", "twine", "cocoon"]),
    ("sewing needle", "🪡", "home", 2, "缝衣针", ["pin", "awl", "bodkin", "crochet hook"]),
    ("honey pot", "🍯", "home", 2, "蜜罐", ["jam jar", "canister", "urn", "cookie jar"]),
    ("wind chime", "🎐", "home", 3, "风铃", ["mobile", "dreamcatcher", "sleigh bell", "pendulum"]),
    ("filing cabinet", "🗄️", "home", 2, "文件柜", ["chest of drawers", "safe", "locker", "dresser"]),
    ("skeleton key", "🗝️", "home", 3, "万能钥匙", ["padlock", "corkscrew", "tuning fork", "keyhole"]),
    ("crystal ball", "🔮", "home", 2, "水晶球", ["snow globe", "marble", "orb", "fishbowl"]),
    ("prayer beads", "📿", "home", 3, "念珠", ["necklace", "bracelet", "garland", "abacus"]),
    ("funeral urn", "⚱️", "home", 3, "骨灰瓮", ["vase", "chalice", "decanter", "amphora"]),
    ("amphora", "🏺", "home", 3, "双耳瓶", ["urn", "jug", "decanter", "vase"]),
    ("headstone", "🪦", "home", 3, "墓碑", ["obelisk", "plaque", "monument", "tablet"]),
    # office and media
    ("scroll", "📜", "office", 2, "卷轴", ["parchment", "manuscript", "diploma", "papyrus"]),
    ("fountain pen", "🖋️", "office", 2, "钢笔", ["quill", "stylus", "calligraphy brush", "ballpoint"]),
    ("ballot box", "🗳️", "office", 3, "投票箱", ["mailbox", "safe", "tip jar", "lockbox"]),
    ("placard", "🪧", "office", 3, "标语牌", ["billboard", "signpost", "banner", "easel"]),
    ("floppy disk", "💾", "office", 3, "软盘", ["cassette", "cartridge", "microchip", "CD-ROM"]),
    ("videocassette", "📼", "office", 3, "录像带", ["floppy disk", "cartridge", "film reel", "audiocassette"]),
    ("film strip", "🎞️", "office", 3, "胶片", ["negative", "film reel", "slide", "ticket"]),
    ("clapperboard", "🎬", "office", 3, "场记板", ["easel", "clipboard", "scoreboard", "chalkboard"]),
    ("film projector", "📽️", "office", 3, "放映机", ["camcorder", "typewriter", "gramophone", "slide viewer"]),
    ("trackball", "🖲️", "office", 3, "轨迹球", ["joystick", "touchpad", "dial", "mouse"]),
    ("fax machine", "📠", "office", 3, "传真机", ["printer", "photocopier", "typewriter", "scanner"]),
    ("pager", "📟", "office", 3, "寻呼机", ["walkie-talkie", "calculator", "transistor radio", "Walkman"]),
    ("satellite dish", "📡", "office", 2, "卫星天线", ["radar", "antenna", "telescope", "parabolic mirror"]),
    ("megaphone", "📣", "office", 2, "扩音器", ["microphone", "loudspeaker", "foghorn", "ear trumpet"]),
    ("service bell", "🛎️", "office", 3, "服务铃", ["doorbell", "gong", "chime", "buzzer"]),
    # music
    ("saxophone", "🎷", "music", 2, "萨克斯管", ["clarinet", "trumpet", "bassoon", "oboe"]),
    ("trumpet", "🎺", "music", 2, "小号", ["trombone", "cornet", "bugle", "flugelhorn"]),
    ("violin", "🎻", "music", 2, "小提琴", ["viola", "cello", "mandolin", "lute"]),
    ("accordion", "🪗", "music", 2, "手风琴", ["concertina", "harmonica", "bagpipes", "harmonium"]),
    ("banjo", "🪕", "music", 2, "班卓琴", ["mandolin", "ukulele", "lute", "sitar"]),
    ("postal horn", "📯", "music", 3, "邮号", ["bugle", "French horn", "cornet", "trombone"]),
    # places and space
    ("volcano", "🌋", "places", 2, "火山", ["geyser", "crater", "mesa", "glacier"]),
    ("desert island", "🏝️", "places", 2, "荒岛", ["atoll", "peninsula", "lagoon", "archipelago"]),
    ("mosque", "🕌", "places", 2, "清真寺", ["synagogue", "cathedral", "temple", "palace"]),
    ("synagogue", "🕍", "places", 3, "犹太会堂", ["mosque", "chapel", "cathedral", "temple"]),
    ("torii gate", "⛩️", "places", 3, "鸟居", ["pagoda", "archway", "pavilion", "portico"]),
    ("stadium", "🏟️", "places", 2, "体育场", ["amphitheater", "colosseum", "racetrack", "gymnasium"]),
    ("Ferris wheel", "🎡", "places", 2, "摩天轮", ["carousel", "roller coaster", "waterwheel", "windmill"]),
    ("Milky Way", "🌌", "places", 3, "银河", ["nebula", "aurora", "comet", "constellation"]),
    ("comet", "☄️", "places", 2, "彗星", ["meteor", "asteroid", "meteorite", "satellite"]),
    ("tornado", "🌪️", "places", 2, "龙卷风", ["hurricane", "whirlpool", "typhoon", "sandstorm"]),
    ("sheaf of rice", "🌾", "places", 3, "稻穗", ["wheat", "barley", "millet", "oats"]),
    # transport
    ("cable car", "🚠", "transport", 2, "缆车", ["funicular", "chairlift", "monorail", "tram"]),
    ("canoe", "🛶", "transport", 2, "独木舟", ["kayak", "raft", "gondola", "dinghy"]),
    ("ferry", "⛴️", "transport", 2, "渡轮", ["tugboat", "barge", "freighter", "steamer"]),
    ("ocean liner", "🚢", "transport", 3, "远洋客轮", ["freighter", "battleship", "ferry", "tanker"]),
    ("monorail", "🚝", "transport", 3, "单轨列车", ["tram", "funicular", "maglev", "subway"]),
    ("steam locomotive", "🚂", "transport", 3, "蒸汽机车", ["diesel engine", "tram", "caboose", "trolley"]),
    ("parachute", "🪂", "transport", 2, "降落伞", ["hang glider", "paraglider", "hot-air balloon", "kite"]),
    ("flying saucer", "🛸", "transport", 2, "飞碟", ["satellite", "space probe", "blimp", "frisbee"]),
    ("kick scooter", "🛴", "transport", 2, "滑板车", ["skateboard", "unicycle", "moped", "Segway"]),
    ("ice skate", "⛸️", "transport", 2, "溜冰鞋", ["roller skate", "ski boot", "snowshoe", "crampon"]),
    ("sled", "🛷", "transport", 2, "雪橇", ["snowboard", "skis", "snowmobile", "wheelbarrow"]),
    ("fuel pump", "⛽", "transport", 2, "加油泵", ["parking meter", "vending machine", "fire hydrant", "charging station"]),
    ("barricade", "🚧", "transport", 3, "路障", ["turnstile", "guardrail", "tollgate", "scaffold"]),
    # sport and play
    ("curling stone", "🥌", "play", 3, "冰壶", ["kettlebell", "discus", "hockey puck", "bowling ball"]),
    ("yo-yo", "🪀", "play", 2, "悠悠球", ["spinning top", "diabolo", "frisbee", "pulley"]),
    ("lacrosse stick", "🥍", "play", 3, "长曲棍球棍", ["hockey stick", "butterfly net", "racket", "polo mallet"]),
    ("diving mask", "🤿", "play", 2, "潜水面罩", ["goggles", "gas mask", "visor", "respirator"]),
    ("theater masks", "🎭", "play", 3, "戏剧面具", ["masquerade", "puppets", "mime", "costume"]),
    ("artist's palette", "🎨", "play", 2, "调色板", ["easel", "canvas", "swatch", "mosaic"]),
    ("slot machine", "🎰", "play", 3, "老虎机", ["jukebox", "vending machine", "cash register", "pinball machine"]),
    ("billiard ball", "🎱", "play", 2, "台球", ["bowling ball", "marble", "croquet ball", "hockey puck"]),
    ("jigsaw puzzle", "🧩", "play", 2, "拼图", ["crossword", "mosaic", "tangram", "Rubik's cube"]),
    ("chess pawn", "♟️", "play", 2, "兵（国际象棋）", ["bishop", "rook", "knight", "king"]),
    ("piñata", "🪅", "play", 3, "皮纳塔", ["kite", "paper lantern", "scarecrow", "effigy"]),
    ("nesting dolls", "🪆", "play", 3, "套娃", ["figurines", "marionettes", "bowling pins", "totem"]),
    # clothing
    ("kimono", "👘", "clothing", 2, "和服", ["sari", "robe", "poncho", "tunic"]),
    ("sari", "🥻", "clothing", 3, "纱丽", ["kimono", "toga", "sarong", "shawl"]),
    ("mortarboard", "🎓", "clothing", 3, "学位帽", ["beret", "fez", "biretta", "beanie"]),
    ("lab coat", "🥼", "clothing", 2, "实验服", ["apron", "smock", "robe", "scrubs"]),
    ("safety vest", "🦺", "clothing", 2, "安全背心", ["life jacket", "waistcoat", "apron", "bib"]),
    ("flip-flop", "🩴", "clothing", 2, "人字拖", ["sandal", "clog", "slipper", "moccasin"]),
    ("hiking boot", "🥾", "clothing", 2, "登山靴", ["sneaker", "clog", "moccasin", "ski boot"]),
    ("ballet shoes", "🩰", "clothing", 2, "芭蕾舞鞋", ["slippers", "espadrilles", "moccasins", "sandals"]),
    ("military medal", "🎖️", "clothing", 3, "勋章", ["badge", "rosette", "ribbon", "pin"]),
    # food
    ("baguette", "🥖", "food", 2, "法棍", ["ciabatta", "breadstick", "brioche", "focaccia"]),
    ("falafel", "🧆", "food", 3, "炸豆丸子", ["meatball", "croquette", "fritter", "dumpling"]),
    ("dumpling", "🥟", "food", 2, "饺子", ["empanada", "ravioli", "samosa", "pierogi"]),
    ("fortune cookie", "🥠", "food", 2, "幸运饼干", ["wafer", "cracker", "biscotti", "dumpling"]),
    ("bento box", "🍱", "food", 2, "便当", ["tiffin", "platter", "tray", "lunchbox"]),
    ("mooncake", "🥮", "food", 2, "月饼", ["tart", "scone", "pastry", "cookie"]),
    ("tamale", "🫔", "food", 3, "墨西哥粽", ["burrito", "enchilada", "empanada", "taco"]),
    ("fondue", "🫕", "food", 3, "奶酪火锅", ["hot pot", "cauldron", "casserole", "soufflé"]),
    ("bubble tea", "🧋", "food", 2, "珍珠奶茶", ["smoothie", "milkshake", "latte", "frappé"]),
    ("chestnut", "🌰", "food", 2, "栗子", ["acorn", "hazelnut", "walnut", "conker"]),
    ("oyster", "🦪", "food", 2, "牡蛎", ["clam", "mussel", "scallop", "abalone"]),
    ("squid", "🦑", "food", 2, "鱿鱼", ["octopus", "cuttlefish", "jellyfish", "nautilus"]),
    # animals
    ("flamingo", "🦩", "animals", 2, "火烈鸟", ["heron", "stork", "crane", "egret"]),
    ("peacock", "🦚", "animals", 2, "孔雀", ["pheasant", "turkey", "quetzal", "lyrebird"]),
    ("parrot", "🦜", "animals", 2, "鹦鹉", ["toucan", "kingfisher", "hummingbird", "finch"]),
    ("dodo", "🦤", "animals", 3, "渡渡鸟", ["kiwi", "emu", "puffin", "ostrich"]),
    ("hedgehog", "🦔", "animals", 2, "刺猬", ["porcupine", "echidna", "armadillo", "shrew"]),
    ("sloth", "🦥", "animals", 2, "树懒", ["koala", "lemur", "anteater", "orangutan"]),
    ("otter", "🦦", "animals", 2, "水獭", ["beaver", "ferret", "weasel", "mink"]),
    ("skunk", "🦨", "animals", 2, "臭鼬", ["badger", "raccoon", "polecat", "civet"]),
    ("badger", "🦡", "animals", 2, "獾", ["raccoon", "wolverine", "skunk", "mole"]),
    ("raccoon", "🦝", "animals", 2, "浣熊", ["badger", "red panda", "coati", "possum"]),
    ("beaver", "🦫", "animals", 2, "河狸", ["otter", "muskrat", "groundhog", "capybara"]),
    ("llama", "🦙", "animals", 2, "美洲驼", ["alpaca", "camel", "vicuña", "guanaco"]),
    ("dromedary", "🐪", "animals", 3, "单峰骆驼", ["llama", "alpaca", "oryx", "gazelle"]),
    ("hippopotamus", "🦛", "animals", 2, "河马", ["rhinoceros", "tapir", "manatee", "walrus"]),
    ("rhinoceros", "🦏", "animals", 2, "犀牛", ["hippopotamus", "tapir", "boar", "triceratops"]),
    ("mammoth", "🦣", "animals", 2, "猛犸象", ["mastodon", "elephant", "bison", "yak"]),
    ("bison", "🦬", "animals", 2, "野牛", ["yak", "musk ox", "wildebeest", "moose"]),
    ("orangutan", "🦧", "animals", 2, "猩猩", ["gorilla", "chimpanzee", "baboon", "gibbon"]),
    ("ram", "🐏", "animals", 2, "公羊", ["goat", "ewe", "ibex", "antelope"]),
    ("boar", "🐗", "animals", 2, "野猪", ["warthog", "tapir", "peccary", "hog"]),
    ("chipmunk", "🐿️", "animals", 2, "花栗鼠", ["squirrel", "hamster", "gopher", "marmot"]),
    ("lizard", "🦎", "animals", 2, "蜥蜴", ["salamander", "newt", "skink", "chameleon"]),
    ("crocodile", "🐊", "animals", 2, "鳄鱼", ["alligator", "caiman", "gharial", "iguana"]),
    ("sauropod", "🦕", "animals", 3, "蜥脚类恐龙", ["stegosaurus", "triceratops", "iguanodon", "pterodactyl"]),
    ("tyrannosaurus", "🦖", "animals", 3, "霸王龙", ["velociraptor", "allosaurus", "triceratops", "stegosaurus"]),
    ("scorpion", "🦂", "animals", 2, "蝎子", ["tarantula", "crayfish", "centipede", "mantis"]),
    ("cricket", "🦗", "animals", 2, "蟋蟀", ["grasshopper", "locust", "katydid", "cicada"]),
    ("earthworm", "🪱", "animals", 2, "蚯蚓", ["leech", "caterpillar", "maggot", "eel"]),
    ("conch", "🐚", "animals", 3, "海螺", ["whelk", "nautilus", "scallop", "cowrie"]),
    ("seal", "🦭", "animals", 2, "海豹", ["sea lion", "walrus", "manatee", "otter"]),
    ("pufferfish", "🐡", "animals", 2, "河豚", ["anglerfish", "sunfish", "boxfish", "lionfish"]),
    # plants
    ("cactus", "🌵", "plants", 2, "仙人掌", ["agave", "aloe", "yucca", "sisal"]),
    ("four-leaf clover", "🍀", "plants", 2, "四叶草", ["shamrock", "sorrel", "oxalis", "trefoil"]),
    ("maple leaf", "🍁", "plants", 2, "枫叶", ["oak leaf", "ivy leaf", "fern", "sycamore leaf"]),
    ("cherry blossom", "🌸", "plants", 2, "樱花", ["plum blossom", "magnolia", "apple blossom", "jasmine"]),
    # symbols
    ("fleur-de-lis", "⚜️", "home", 3, "鸢尾花纹", ["trefoil", "crest", "insignia", "tiara"]),
]


def main():
    seen_words, seen_glyphs, out = set(), set(), []
    groups = {}
    for word, glyph, group, level, cn, distractors in P:
        key = word.lower()
        if key in seen_words:
            raise SystemExit("duplicate word " + word)
        norm = unicodedata.normalize("NFC", glyph)
        if norm in seen_glyphs:
            raise SystemExit("duplicate glyph " + word + " " + glyph)
        lowered = [d.lower() for d in distractors]
        if key in lowered or len(set(lowered)) != len(lowered) or len(lowered) < 4:
            raise SystemExit("bad distractors " + word)
        if max(ord(ch) for ch in glyph) > 0x1FAFF:
            raise SystemExit("emoji too new " + word)
        seen_words.add(key)
        seen_glyphs.add(norm)
        groups[group] = groups.get(group, 0) + 1
        out.append({
            "word": word,
            "glyph": glyph,
            "cn": cn,
            "cnStatus": "pending native check",
            "distractorGroup": group,
            "level": level,
            "symbol": "",
            "distractors": distractors,
        })
    small = [g for g, n in groups.items() if n < 4]
    if small:
        raise SystemExit("groups under 4: " + ", ".join(small))
    with open(OUT, "w", encoding="utf-8") as handle:
        json.dump(out, handle, ensure_ascii=False, indent=2)
        handle.write("\n")
    print("pictures", len(out), "groups", groups)
    return apply_checked_glosses()


def apply_checked_glosses():
    """Re-apply the checked Chinese glosses so a rebuild never undoes them."""
    import apply_cn_fixes
    return apply_cn_fixes.main()


if __name__ == "__main__":
    raise SystemExit(main())
