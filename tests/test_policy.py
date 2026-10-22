import datetime
import json
import re
import unittest
from pathlib import Path

from check_scan import failures, validate_report
from assert_new_tag import assert_missing


class PolicyTests(unittest.TestCase):
    def test_pinned_supported_variants(self):
        config = json.loads(Path("images.json").read_text())
        floors = {"8.2": (8, 2, 35), "8.3": (8, 3, 36), "8.4": (8, 4, 27)}
        tags = set()
        self.assertRegex(config["base_image"], r"^cgr.dev/chainguard/wolfi-base@sha256:[0-9a-f]{64}$")
        profiles = set()
        for variant in config["variants"]:
            version = tuple(map(int, variant["version"].split(".")))
            self.assertGreaterEqual(version, floors[variant["version"].rsplit(".", 1)[0]])
            self.assertEqual(variant["branch"], variant["version"].rsplit(".", 1)[0])
            self.assertIn(variant["profile"], ("build", "runtime"))
            self.assertEqual(variant["php_package"], variant["version"] + "-r0")
            self.assertEqual(variant["tag"], config["release"].removeprefix("v") + "-" + variant["id"])
            self.assertNotIn(variant["tag"], tags)
            tags.add(variant["tag"])
            profiles.add((variant["branch"], variant["profile"]))
        self.assertEqual(profiles, {(branch, profile) for branch in floors for profile in ("build", "runtime")})

    def test_runtime_does_not_inherit_build_tools(self):
        dockerfile = Path("Dockerfile").read_text()
        self.assertIn("FROM common AS build", dockerfile)
        self.assertIn("FROM common AS runtime", dockerfile)
        self.assertNotIn("FROM build AS runtime", dockerfile)
        self.assertIn("libxml2-16=2.15.4-r1", dockerfile)
        self.assertIn("imagemagick-7=7.1.2.34-r0", dockerfile)
        self.assertNotIn("--allow-untrusted", dockerfile)
        self.assertNotIn("--force", dockerfile)

    def test_build_defaults_match_catalog(self):
        config = json.loads(Path("images.json").read_text())
        variant = next(v for v in config["variants"] if v["id"] == "php8.4-build")
        dockerfile = Path("Dockerfile").read_text()
        for argument, key in [("PHP_BRANCH", "branch"), ("PHP_PACKAGE_VERSION", "php_package"),
                              ("IMAGICK_PACKAGE_VERSION", "imagick_package"),
                              ("REDIS_PACKAGE_VERSION", "redis_package"),
                              ("XDEBUG_PACKAGE_VERSION", "xdebug_package")]:
            self.assertIn("ARG " + argument + "=" + variant[key] + "\n", dockerfile)

    def test_unreviewed_high_is_rejected(self):
        report = {"Results": [{"Vulnerabilities": [{"VulnerabilityID": "CVE-test", "PkgName": "test", "InstalledVersion": "1", "Severity": "HIGH"}]}]}
        self.assertEqual(len(failures(report, [], datetime.date.today())), 1)

    def test_runtime_cve_cannot_be_excepted(self):
        with self.assertRaises(ValueError):
            failures({}, [{"id": "CVE-2026-109618", "package": "php", "installed_version": "8.4.16", "reason": "test", "expires": "2099-01-01"}], datetime.date.today())

    def test_exception_is_version_and_package_specific(self):
        exception = {"id": "CVE-test", "package": "test", "installed_version": "1", "reason": "fixture", "expires": "2099-01-01"}
        report = {"Results": [{"Vulnerabilities": [{"VulnerabilityID": "CVE-test", "PkgName": "other", "InstalledVersion": "1", "Severity": "HIGH"}]}]}
        self.assertEqual(len(failures(report, [exception], datetime.date.today())), 1)

    def test_expired_exception_fails(self):
        with self.assertRaises(ValueError):
            failures({}, [{"id": "CVE-test", "package": "test", "installed_version": "1", "reason": "fixture", "expires": "2000-01-01"}], datetime.date.today())

    def test_clean_scan(self):
        self.assertEqual(failures({"Results": []}, [], datetime.date.today()), [])

    def test_missing_scan_fails_closed(self):
        for report in [{}, {"ArtifactType": "container_image", "Results": []}]:
            with self.assertRaises(ValueError):
                validate_report(report)

    def test_existing_or_unreachable_tag_fails_closed(self):
        for code, message in [(0, ""), (1, "unauthorized"), (1, "connection timeout")]:
            with self.assertRaises(ValueError):
                assert_missing(code, message)
        assert_missing(1, "manifest unknown")

    def test_build_dependency_cleanup_preserves_base_toolchain(self):
        dockerfile = Path("Dockerfile.debian").read_text()
        self.assertIn('savedAptMark="$(apt-mark showmanual)"', dockerfile)
        self.assertIn('apt-mark manual $savedAptMark $runtimeDeps', dockerfile)
        self.assertIn('apt-get purge -y --auto-remove', dockerfile)
        self.assertNotIn('apt-get install -y libmcrypt-dev', dockerfile)


if __name__ == "__main__":
    unittest.main()
