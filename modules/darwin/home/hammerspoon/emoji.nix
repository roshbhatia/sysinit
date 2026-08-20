{ pkgs }:

# One dataset for both hosts. arrakis reads emoji through elephant's `symbols`
# provider, which embeds the Unicode CLDR annotation files; this derivation
# reads those same files out of elephant's source rather than fetching CLDR a
# second time, so `:sparkles` cannot resolve to different characters or carry
# different names on the two machines. If elephant moves the files, this build
# fails on the missing path instead of drifting.
#
# `variations.txt` is applied the way elephant applies it: a codepoint listed
# there is emitted with U+FE0F appended, which is what makes it render as an
# emoji rather than as text.
pkgs.runCommand "sysinit-emoji.json"
  {
    nativeBuildInputs = [ pkgs.python3 ];
    src = pkgs.elephant.src;
  }
  ''
    python3 - "$src" "$out" <<'PY'
    import json, re, sys, xml.etree.ElementTree as ET
    from pathlib import Path

    src, out = Path(sys.argv[1]), Path(sys.argv[2])
    data = src / "internal" / "providers" / "symbols" / "data"

    variations = set()
    for line in (data / "variations.txt").read_text(encoding="utf-8").splitlines():
        line = line.split("#", 1)[0].strip()
        if line:
            variations.add(chr(int(line.split()[0], 16)))

    names, keywords = {}, {}
    order = []
    for path in (data / "en.xml", data / "derived" / "en.xml"):
        for node in ET.parse(path).getroot().iter("annotation"):
            cp = node.get("cp")
            text = (node.text or "").strip()
            if not cp or not text:
                continue
            if cp not in keywords:
                keywords[cp] = []
                order.append(cp)
            if node.get("type") == "tts":
                names[cp] = text
            else:
                keywords[cp].extend(w.strip() for w in text.split("|"))

    rows = []
    for cp in order:
        name = names.get(cp)
        if not name:
            continue
        # A shortcode in the shape the rest of the world types: lowercase, one
        # underscore per gap, nothing else. `:waving_hand_light_skin_tone`.
        code = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
        # One flat haystack per row rather than a keyword array. The panel page
        # matches on every keystroke with no debounce, so a row it can scan with
        # a single string search costs far less than one it has to walk.
        terms = sorted({k.lower() for k in keywords[cp] if k} | {name.lower(), code})
        rows.append({
            "cp": cp + "\ufe0f" if cp in variations else cp,
            "name": name,
            "code": code,
            "search": " ".join(terms),
        })

    out.write_text(json.dumps(rows, ensure_ascii=False, separators=(",", ":")), encoding="utf-8")
    PY
  ''
