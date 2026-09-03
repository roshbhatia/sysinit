#!/usr/bin/env python3

import json
import re
import sys
import xml.etree.ElementTree as ET
from pathlib import Path


def load_variations(data: Path) -> set[str]:
    variations = set()
    for line in (data / "variations.txt").read_text(encoding="utf-8").splitlines():
        codepoint = line.split("#", 1)[0].strip()
        if codepoint:
            variations.add(chr(int(codepoint.split()[0], 16)))
    return variations


def load_annotations(data: Path) -> tuple[dict[str, str], dict[str, list[str]], list[str]]:
    names: dict[str, str] = {}
    keywords: dict[str, list[str]] = {}
    order = []

    for path in (data / "en.xml", data / "derived" / "en.xml"):
        for node in ET.parse(path).getroot().iter("annotation"):
            codepoint = node.get("cp")
            text = (node.text or "").strip()
            if not codepoint or not text:
                continue
            if codepoint not in keywords:
                keywords[codepoint] = []
                order.append(codepoint)
            if node.get("type") == "tts":
                names[codepoint] = text
            else:
                keywords[codepoint].extend(word.strip() for word in text.split("|"))

    return names, keywords, order


def build_rows(data: Path) -> list[dict[str, str]]:
    variations = load_variations(data)
    names, keywords, order = load_annotations(data)
    rows = []

    for codepoint in order:
        name = names.get(codepoint)
        if not name:
            continue

        shortcode = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
        terms = sorted(
            {word.lower() for word in keywords[codepoint] if word}
            | {name.lower(), shortcode}
        )
        rows.append(
            {
                "cp": codepoint + "\ufe0f" if codepoint in variations else codepoint,
                "name": name,
                "code": shortcode,
                "search": " ".join(terms),
            }
        )

    return rows


source = Path(sys.argv[1])
output = Path(sys.argv[2])
data_directory = source / "internal" / "providers" / "symbols" / "data"
output.write_text(
    json.dumps(build_rows(data_directory), ensure_ascii=False, separators=(",", ":")),
    encoding="utf-8",
)
