import json
from pathlib import Path
import subprocess
import sys

import yaml


for document in yaml.safe_load_all(Path(sys.argv[1]).read_text()):
    if not document:
        continue
    encoded = json.dumps(document)
    if document["kind"] == "CustomResourceDefinition":
        name = document["metadata"]["name"]
        existing = subprocess.run(
            ["kubectl", "get", "crd", name, "--ignore-not-found", "-o", "name"],
            check=True,
            capture_output=True,
            text=True,
        )
        if existing.stdout.strip():
            continue
        command = ["kubectl", "create", "-f", "-"]
    else:
        command = ["kubectl", "apply", "--server-side", "-f", "-"]
    subprocess.run(command, input=encoded, text=True, check=True)
