import importlib.util
import json
import pathlib
import tempfile
import unittest
from unittest.mock import patch

SOURCE = pathlib.Path(__file__).with_name('update-flakes.py')
spec = importlib.util.spec_from_file_location('update_flakes', SOURCE)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class UpdateFlakesTest(unittest.TestCase):
    def test_updates_fixed_refs_and_nested_locks_once(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            (root / 'extras').mkdir()
            (root / 'flake.nix').write_text('"github:owner/tool/v1.0.0?dir=extras" "github:owner/tool/main"')
            (root / 'extras/flake.nix').write_text('"github:owner/tool/' + 'a' * 40 + '"')
            calls = []

            def output(argv, **kwargs):
                if argv[0] == 'git':
                    return 'flake.nix\nextras/flake.nix\n'
                endpoint = argv[-1]
                if endpoint.endswith('/releases?per_page=100'):
                    return json.dumps([
                        {'tag_name': 'v3.0.0-rc1', 'draft': False, 'prerelease': True},
                        {'tag_name': 'v1.5.0', 'draft': False, 'prerelease': False},
                        {'tag_name': 'v2.0.0', 'draft': False, 'prerelease': False},
                    ])
                if endpoint.endswith('/commits/main'):
                    return json.dumps({'sha': 'b' * 40})
                return json.dumps({'default_branch': 'main'})

            with patch.object(updater, 'ROOT', root), patch.object(updater.subprocess, 'check_output', side_effect=output), patch.object(updater.subprocess, 'run', side_effect=lambda argv, **kwargs: calls.append((argv, kwargs))):
                updater.update()
            self.assertEqual((root / 'flake.nix').read_text(), '"github:owner/tool/v2.0.0?dir=extras" "github:owner/tool/main"')
            self.assertIn('b' * 40, (root / 'extras/flake.nix').read_text())
            self.assertEqual([entry[1]['cwd'] for entry in calls], [root, root / 'extras'])
            self.assertTrue(all(entry[0] == ['nix', 'flake', 'update'] and entry[1]['check'] for entry in calls))

    def test_tag_only_repositories_exclude_prereleases_and_do_not_downgrade(self):
        with tempfile.TemporaryDirectory() as temporary:
            root = pathlib.Path(temporary)
            path = root / 'flake.nix'
            path.write_text('"github:owner/tool/v2.0.0"')
            def output(argv, **kwargs):
                if argv[0] == 'git':
                    return 'flake.nix\n'
                if '/releases?' in argv[-1]:
                    return '[]'
                return json.dumps([{'name': 'v1.9.0'}, {'name': 'v3.0.0-rc1'}, {'name': 'v2.1.0'}])
            with patch.object(updater, 'ROOT', root), patch.object(updater.subprocess, 'check_output', side_effect=output), patch.object(updater.subprocess, 'run'):
                updater.update()
            self.assertEqual(path.read_text(), '"github:owner/tool/v2.1.0"')


if __name__ == '__main__':
    unittest.main()
