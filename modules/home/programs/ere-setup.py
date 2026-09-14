import argparse
import json
import os
from pathlib import Path
import shlex
import subprocess
import tempfile
from urllib.parse import urlsplit

import yaml


parser = argparse.ArgumentParser(description="Prepare private Ere cluster access")
parser.add_argument("host", choices=["arrakis", "vorgossos"])
args = parser.parse_args()
host = args.host
command = (
    "sudo -n k3s kubectl config view --raw --minify -o json"
    if host == "arrakis"
    else "sudo -n /usr/local/bin/k0s kubeconfig admin"
)
result = subprocess.run(
    ["ssh", "-o", "BatchMode=yes", host, "sh -c " + shlex.quote(command)],
    check=True,
    capture_output=True,
    text=True,
)
data = yaml.safe_load(result.stdout)
cluster = data["clusters"][0]["cluster"]
cluster["tls-server-name"] = urlsplit(cluster["server"]).hostname
cluster["server"] = f"https://{host}:6443"
data["clusters"][0]["name"] = host
data["contexts"] = [{"name": host, "context": {
    "cluster": host, "user": data["users"][0]["name"], "namespace": "ere"
}}]
data["current-context"] = host
directory = Path.home() / ".kube"
directory.mkdir(mode=0o700, exist_ok=True)
destination = directory / f"ere-{host}.yaml"
fd, temporary = tempfile.mkstemp(dir=directory, prefix=".ere-")
try:
    with os.fdopen(fd, "w") as output:
        json.dump(data, output)
    subprocess.run([
        "kubectl", "--kubeconfig", temporary, "get", "namespace", "ere"
    ], check=True)
    os.replace(temporary, destination)
finally:
    Path(temporary).unlink(missing_ok=True)
key = Path.home() / ".ssh" / "ere"
key.parent.mkdir(mode=0o700, exist_ok=True)
if not key.exists():
    subprocess.run([
        "ssh-keygen", "-q", "-t", "ed25519", "-N", "", "-f", str(key)
    ], check=True)
print(f"Prepared {destination}")
