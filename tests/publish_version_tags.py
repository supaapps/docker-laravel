"""Add release-version names to existing verified multi-architecture images."""
import json
import re
import subprocess
import sys
from pathlib import Path

from assert_new_tag import assert_missing


def mapping(catalog, publication):
    if publication["repository"] != "supaapps/docker-laravel" or publication["release"] != catalog["release"]:
        raise ValueError("Publication repository/release mismatch")
    version = catalog["release"].removeprefix("v")
    if not re.fullmatch(r"\d+\.\d+\.\d+", version):
        raise ValueError("Stable release version required")
    rows = []
    for variant in catalog["variants"]:
        target = f"{version}-{variant['id']}"
        sources = [i for i in publication["images"] if i["php"] == variant["version"] and
                   (i["tag"].startswith(variant["id"] + "-") or i["tag"] == target)]
        if len(sources) != 1 or not re.fullmatch(r"sha256:[0-9a-f]{64}", sources[0]["digest"]):
            raise ValueError("Missing or ambiguous published image")
        rows.append({"tag": target, "digest": sources[0]["digest"]})
    return rows


def inspect(reference):
    return subprocess.run(["docker", "buildx", "imagetools", "inspect", reference,
                           "--format", "{{json .Manifest}}"], capture_output=True, text=True)


def require_index(result, digest):
    result.check_returncode()
    manifest = json.loads(result.stdout)
    platforms = {(m["platform"]["os"], m["platform"]["architecture"]) for m in manifest.get("manifests", [])}
    if manifest.get("digest") != digest or len(manifest.get("manifests", [])) != 2 or platforms != {("linux", "amd64"), ("linux", "arm64")}:
        raise ValueError("Image digest/platform mismatch")


if __name__ == "__main__":
    catalog = json.loads(Path("images.json").read_text())
    publication = json.loads(Path(sys.argv[1]).read_text())
    image = "ghcr.io/supaapps/docker-laravel"
    rows = mapping(catalog, publication)
    for row in rows:
        source, target = f"{image}@{row['digest']}", f"{image}:{row['tag']}"
        require_index(inspect(source), row["digest"])
        existing = inspect(target)
        if existing.returncode == 0:
            require_index(existing, row["digest"])
        else:
            absence = subprocess.run(["docker", "manifest", "inspect", target], capture_output=True, text=True)
            assert_missing(absence.returncode, absence.stderr + absence.stdout)
            subprocess.run(["docker", "buildx", "imagetools", "create", "--tag", target, source], check=True)
            require_index(inspect(target), row["digest"])
        print(target, row["digest"])
    Path("version-tags.json").write_text(json.dumps({"release": catalog["release"], "images": rows}, indent=2) + "\n")
