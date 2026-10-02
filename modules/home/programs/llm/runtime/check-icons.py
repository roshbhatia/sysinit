import json
from pathlib import Path
import re
import struct
import sys
import xml.etree.ElementTree as ET

sources = json.loads(Path(sys.argv[1]).read_text())
for name, source in sources.items():
    if not re.fullmatch(r"[a-z][a-z0-9_-]*", name):
        raise ValueError(f"Invalid notification icon name: {name}")
    root = ET.parse(source).getroot()
    if root.tag != "{http://www.w3.org/2000/svg}svg" or "viewBox" not in root.attrib:
        raise ValueError(f"Icon needs an SVG viewBox: {name}")
    for node in root.iter():
        if node.tag.rsplit("}", 1)[-1] in {"script", "foreignObject"}:
            raise ValueError(f"Active SVG content: {name}")
        for key, value in node.attrib.items():
            if key.rsplit("}", 1)[-1] == "href" and not value.startswith("#"):
                raise ValueError(f"External SVG reference: {name}")
    if len(sys.argv) > 2:
        image = Path(sys.argv[2], name + ".png").read_bytes()
        if image[:8] != b"\x89PNG\r\n\x1a\n" or struct.unpack(">II", image[16:24]) != (
            256,
            256,
        ):
            raise ValueError(f"Expected a 256x256 PNG: {name}")
print(f"Validated {len(sources)} notification icons")
