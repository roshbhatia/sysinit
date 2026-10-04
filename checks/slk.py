import importlib.util
from pathlib import Path
import sys
import tempfile
import tomllib

spec = importlib.util.spec_from_file_location("slk_setup", sys.argv[1])
setup = importlib.util.module_from_spec(spec)
spec.loader.exec_module(setup)

with tempfile.TemporaryDirectory() as directory:
    root = Path(directory)
    path = root / "config.toml"
    settings = root / "settings.toml"
    settings.write_text(
        '[appearance]\nimage_protocol = "auto"\n[sidebar]\nwidth = 26\n'
    )
    path.write_text(
        '# preserved comment\n[appearance]\nimage_protocol = "kitty"\n'
        'theme = "custom"\n[workspaces."work.team"]\nteam_id = "T123"\n'
        '[notifications]\non_keyword = ["important"]\n'
    )
    setup.configure(path, settings)
    contents = path.read_text()
    result = tomllib.loads(contents)
    assert result["appearance"] == {"image_protocol": "auto", "theme": "custom"}
    assert result["workspaces"]["work.team"]["team_id"] == "T123"
    assert result["notifications"]["on_keyword"] == ["important"]
    assert result["sidebar"]["width"] == 26
    assert "# preserved comment" in contents
    assert path.stat().st_mode & 0o777 == 0o600
    inode = path.stat().st_ino
    setup.configure(path, settings)
    assert path.read_text() == contents
    assert path.stat().st_ino == inode

    path.write_text("[broken")
    try:
        setup.configure(path, settings)
    except ValueError:
        pass
    else:
        raise AssertionError("Malformed config was accepted")
    assert path.read_text() == "[broken"

    fresh = root / "fresh" / "config.toml"
    setup.configure(fresh, settings)
    assert tomllib.loads(fresh.read_text())["sidebar"]["width"] == 26
    assert not list(root.glob(".config.*"))
print(
    "slk config preservation, idempotence, permissions, and invalid-input checks passed"
)
