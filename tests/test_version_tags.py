import copy
import json
import subprocess
import unittest

from publish_version_tags import mapping, require_index


class VersionTagTests(unittest.TestCase):
    def setUp(self):
        self.catalog = {"release": "v5.0.1", "variants": [{"id": "php8.3-build", "version": "8.3.36"}]}
        self.publication = {"repository": "supaapps/docker-laravel", "release": "v5.0.1", "images": [
            {"tag": "php8.3-build-20261022.2", "php": "8.3.36", "digest": "sha256:" + "a" * 64}]}

    def test_alias_preserves_digest(self):
        self.assertEqual(mapping(self.catalog, self.publication), [{"tag": "5.0.1-php8.3-build", "digest": "sha256:" + "a" * 64}])

    def test_wrong_publication_rejected(self):
        for field, value in [("repository", "other/repository"), ("release", "v5.0.0")]:
            changed = copy.deepcopy(self.publication)
            changed[field] = value
            with self.assertRaises(ValueError):
                mapping(self.catalog, changed)

    def test_ambiguous_or_bad_digest_rejected(self):
        for images in [[], self.publication["images"] * 2, [dict(self.publication["images"][0], digest="invalid")]]:
            with self.assertRaises(ValueError):
                mapping(self.catalog, dict(self.publication, images=images))

    def test_existing_mismatched_alias_or_missing_platform_rejected(self):
        for manifest in [{"digest": "wrong"}, {"digest": "expected", "manifests": []}]:
            with self.assertRaises(ValueError):
                require_index(subprocess.CompletedProcess([], 0, json.dumps(manifest)), "expected")

    def test_matching_two_platform_index_accepted(self):
        manifest = {"digest": "expected", "manifests": [
            {"platform": {"os": "linux", "architecture": arch}} for arch in ["amd64", "arm64"]]}
        require_index(subprocess.CompletedProcess([], 0, json.dumps(manifest)), "expected")
