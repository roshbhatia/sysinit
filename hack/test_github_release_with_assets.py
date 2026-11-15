import importlib.util
import pathlib
import unittest

spec = importlib.util.spec_from_file_location(
    "github_release_with_assets",
    pathlib.Path(__file__).with_name("github-release-with-assets.py"),
)
updater = importlib.util.module_from_spec(spec)
spec.loader.exec_module(updater)


class ReleaseAssetsTest(unittest.TestCase):
    def test_skips_incomplete_and_prerelease_uploads(self):
        releases = [
            {"tag_name": "v3", "draft": False, "prerelease": False, "assets": []},
            {
                "tag_name": "v2-rc1",
                "draft": False,
                "prerelease": True,
                "assets": [{"name": "arm.zip"}, {"name": "x64.zip"}],
            },
            {
                "tag_name": "v2",
                "draft": False,
                "prerelease": False,
                "assets": [{"name": "arm.zip"}],
            },
            {
                "tag_name": "v1",
                "draft": False,
                "prerelease": False,
                "assets": [{"name": "arm.zip"}, {"name": "x64.zip"}],
            },
        ]
        self.assertEqual(updater.select_release(releases, ["arm.zip", "x64.zip"]), "v1")

    def test_missing_assets_fail_instead_of_selecting_an_invalid_release(self):
        with self.assertRaisesRegex(ValueError, "No stable release"):
            updater.select_release([], ["arm.zip"])


if __name__ == "__main__":
    unittest.main()
